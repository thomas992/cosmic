const std = @import("std");
const stdx = @import("stdx");
const fatal = stdx.fatal;
const Transform = stdx.math.Transform;
const string = stdx.string;
const ds = stdx.ds;
const t = stdx.testing;

const graphics = @import("graphics.zig");
const Color = graphics.Color;
const draw_cmd = @import("draw_cmd.zig");
const DrawCommandList = draw_cmd.DrawCommandList;
const DrawCommandPtr = draw_cmd.DrawCommandPtr;
const log = stdx.log.scoped(.svg);

// Parse SVG file format and SVG paths into draw commands.

pub const PathCommand = enum {
    MoveTo,
    MoveToRel,
    LineTo,
    LineToRel,
    HorzLineTo,
    HorzLineToRel,
    VertLineTo,
    VertLineToRel,
    EllipticArc,
    EllipticArcRel,
    CurveTo,
    CurveToRel,
    SmoothCurveTo,
    SmoothCurveToRel,
    ClosePath,
};

pub fn PathCommandData(comptime Tag: PathCommand) type {
    return switch (Tag) {
        .MoveTo,
        .MoveToRel => PathMoveTo,
        .LineTo,
        .LineToRel => PathLineTo,
        .HorzLineTo,
        .HorzLineToRel => PathHorzLineTo,
        .VertLineTo,
        .VertLineToRel => PathVertLineTo,
        .EllipticArc,
        .EllipticArcRel => PathEllipticArc,
        .CurveTo,
        .CurveToRel => PathCurveTo,
        .SmoothCurveTo,
        .SmoothCurveToRel => PathSmoothCurveTo,
        .ClosePath => void,
    };
}

pub const PathCommandPtr = struct {
    tag: PathCommand,
    id: u32,

    fn init(tag: PathCommand, id: u32) PathCommandPtr {
        return .{
            .tag = tag,
            .id = id,
        };
    }

    fn getData(self: *PathCommandPtr, comptime Tag: PathCommand, buf: []const u8) PathCommandData(Tag) {
        return std.mem.bytesToValue(PathCommandData(Tag), buf[self.id..][0..@sizeOf(PathCommandData(Tag))]);
    }
};

pub const PathSmoothCurveTo = struct {
    c2_x: f32,
    c2_y: f32,
    x: f32,
    y: f32,
};

pub const PathCurveTo = struct {
    ca_x: f32,
    ca_y: f32,
    cb_x: f32,
    cb_y: f32,
    x: f32,
    y: f32,
};

pub const PathEllipticArc = struct {
    rx: f32,
    ry: f32,
    deg: f32,
    x: f32,
    y: f32,
    large_arc_flag: bool,
    sweep_flag: bool,
};

pub const PathHorzLineTo = struct {
    x: f32,
};

pub const PathVertLineTo = struct {
    y: f32,
};

pub const PathVertLineToRel = struct {
    y: f32,
};

pub const PathLineTo = struct {
    x: f32,
    y: f32,
};

pub const PathMoveTo = struct {
    x: f32,
    y: f32,
};

pub const SvgPath = struct {
    alloc: ?std.mem.Allocator,
    data: []const f32,
    cmds: []const PathCommand,

    pub fn deinit(self: SvgPath) void {
        if (self.alloc) |alloc| {
            alloc.free(self.data);
            alloc.free(self.cmds);
        }
    }

    pub fn getData(self: SvgPath, comptime Tag: PathCommand, data_idx: usize) PathCommandData(Tag) {
        const Size = @sizeOf(PathCommandData(Tag)) / 4;
        return @ptrCast(*const PathCommandData(Tag), self.data[data_idx .. data_idx + Size]).*;
    }
};

pub const PathParser = struct {
    data: std.ArrayList(f32),
    cmds: std.ArrayList(u8),
    temp_buf: std.ArrayList(u8),
    src: []const u8,
    next_pos: u32,

    // Use cur buffers during parsing so it can parse with it's own buffer or with a give buffer.
    cur_data: std.ArrayList(f32),
    cur_cmds: std.ArrayList(u8),

    pub fn init(alloc: std.mem.Allocator) PathParser {
        return .{
            .data = std.ArrayList(f32).init(alloc),
            .temp_buf = std.ArrayList(u8).init(alloc),
            .cmds = std.ArrayList(u8).init(alloc),
            .src = undefined,
            .next_pos = undefined,
            .cur_data = undefined,
            .cur_cmds = undefined,
        };
    }

    pub fn deinit(self: PathParser) void {
        self.data.deinit();
        self.cmds.deinit();
        self.temp_buf.deinit();
    }

    // Parses into existing buffers.
    fn parseAppend(self: *PathParser, cmds: *std.ArrayList(u8), data: *std.ArrayList(f32), str: []const u8) !SvgPath {
        self.cur_cmds = cmds.*;
        self.cur_data = data.*;
        defer {
            cmds.* = self.cur_cmds;
            data.* = self.cur_data;
        }
        return self.parseInternal(str);
    }

    fn parseAlloc(self: *PathParser, alloc: std.mem.Allocator, str: []const u8) !SvgPath {
        const path = try self.parse(str);
        const new_cmds = try alloc.alloc(PathCommand, path.cmds.len);
        std.mem.copy(PathCommand, new_cmds, path.cmds);
        const new_data = try alloc.alloc(f32, path.data.len);
        std.mem.copy(f32, new_data, path.data);
        return SvgPath{
            .alloc = alloc,
            .data = new_data,
            .cmds = new_cmds,
        };
    }

    pub fn parse(self: *PathParser, str: []const u8) !SvgPath {
        self.temp_buf.clearRetainingCapacity();

        self.cur_cmds = self.cmds;
        self.cur_data = self.data;
        defer {
            self.cmds = self.cur_cmds;
            self.data = self.cur_data;
        }

        self.cur_cmds.clearRetainingCapacity();
        self.cur_data.clearRetainingCapacity();
        return self.parseInternal(str);
    }

    fn seekToNext(self: *PathParser) ?u8 {
        self.consumeDelim();
        if (self.nextAtEnd()) {
            return null;
        }
        return self.peekNext();
    }

    fn parseInternal(self: *PathParser, str: []const u8) !SvgPath {
        self.src = str;
        self.next_pos = 0;

        const start_data_idx = self.cur_data.items.len;
        const start_cmd_idx = self.cur_cmds.items.len;
        errdefer {
            // Restore buffers.
            self.cur_data.resize(start_data_idx) catch unreachable;
            self.cur_cmds.resize(start_cmd_idx) catch unreachable;
        }

        while (true) {
            self.consumeDelim();
            if (self.nextAtEnd()) {
                break;
            }
            var ch = self.peekNext();
            if (!std.ascii.isAlpha(ch)) {
                log.debug("unsupported command char: {c} {} at {}", .{ ch, ch, self.next_pos });
                log.debug("{s}", .{self.src});
                return error.ParseError;
            }
            self.consumeNext();
            switch (ch) {
                'm' => {
                    var cmd = try self.parseMoveTo(true);
                    self.cur_cmds.append(@enumToInt(cmd)) catch fatal();

                    // Subsequent points are treated as LineTo
                    ch = self.seekToNext() orelse break;
                    while (!std.ascii.isAlpha(ch)) {
                        cmd = try self.parseLineTo(true);
                        self.cur_cmds.append(@enumToInt(cmd)) catch fatal();
                        ch = self.seekToNext() orelse break;
                    }
                },
                'M' => {
                    var cmd = try self.parseMoveTo(false);
                    self.cur_cmds.append(@enumToInt(cmd)) catch fatal();

                    // Subsequent points are treated as LineTo
                    ch = self.seekToNext() orelse break;
                    while (!std.ascii.isAlpha(ch)) {
                        cmd = try self.parseLineTo(false);
                        self.cur_cmds.append(@enumToInt(cmd)) catch fatal();
                        ch = self.seekToNext() orelse break;
                    }
                },
                'a' => {
                    var cmd = try self.parseEllipticArc(true);
                    self.cur_cmds.append(@enumToInt(cmd)) catch fatal();

                    // Subsequent args are additional elliptic arc commands.
                    ch = self.seekToNext() orelse break;
                    while (!std.ascii.isAlpha(ch)) {
                        cmd = try self.parseEllipticArc(true);
                        self.cur_cmds.append(@enumToInt(cmd)) catch fatal();
                        ch = self.seekToNext() orelse break;
                    }
                },
                'h' => {
                    const cmd = try self.parsePathHorzLineTo(true);
                    self.cur_cmds.append(@enumToInt(cmd)) catch fatal();
                },
                'H' => {
                    const cmd = try self.parsePathHorzLineTo(false);
                    self.cur_cmds.append(@enumToInt(cmd)) catch fatal();
                },
                'v' => {
                    const cmd = try self.parsePathVertLineTo(true);
                    self.cur_cmds.append(@enumToInt(cmd)) catch fatal();
                },
                'l' => {
                    var cmd = try self.parseLineTo(true);
                    self.cur_cmds.append(@enumToInt(cmd)) catch fatal();

                    // Subsequent args represent a polyline.
                    ch = self.seekToNext() orelse break;
                    while (!std.ascii.isAlpha(ch)) {
                        cmd = try self.parseLineTo(true);
                        self.cur_cmds.append(@enumToInt(cmd)) catch fatal();
                        ch = self.seekToNext() orelse break;
                    }
                },
                'L' => {
                    var cmd = try self.parseLineTo(false);
                    self.cur_cmds.append(@enumToInt(cmd)) catch fatal();

                    // Subsequent args represent a polyline.
                    ch = self.seekToNext() orelse break;
                    while (!std.ascii.isAlpha(ch)) {
                        cmd = try self.parseLineTo(false);
                        self.cur_cmds.append(@enumToInt(cmd)) catch fatal();
                        ch = self.seekToNext() orelse break;
                    }
                },
                'c' => {
                    var cmd = try self.parseSvgCurveto(true);
                    self.cur_cmds.append(@enumToInt(cmd)) catch fatal();

                    ch = self.seekToNext() orelse break;
                    while (!std.ascii.isAlpha(ch)) {
                        // Polybezier, keep parsing same command.
                        cmd = try self.parseSvgCurveto(true);
                        self.cur_cmds.append(@enumToInt(cmd)) catch fatal();
                        ch = self.seekToNext() orelse break;
                    }
                },
                'C' => {
                    const cmd = try self.parseSvgCurveto(false);
                    self.cur_cmds.append(@enumToInt(cmd)) catch fatal();
                },
                's' => {
                    var cmd = try self.parseSvgSmoothCurveto(true);
                    self.cur_cmds.append(@enumToInt(cmd)) catch fatal();

                    ch = self.seekToNext() orelse break;
                    while (!std.ascii.isAlpha(ch)) {
                        // Polybezier, keep parsing same command.
                        cmd = try self.parseSvgSmoothCurveto(true);
                        self.cur_cmds.append(@enumToInt(cmd)) catch fatal();
                        ch = self.seekToNext() orelse break;
                    }
                },
                'S' => {
                    const cmd = try self.parseSvgSmoothCurveto(false);
                    self.cur_cmds.append(@enumToInt(cmd)) catch fatal();
                },
                'z' => {
                    self.cur_cmds.append(@enumToInt(PathCommand.ClosePath)) catch fatal();
                },
                'Z' => {
                    self.cur_cmds.append(@enumToInt(PathCommand.ClosePath)) catch fatal();
                },
                else => {
                    log.debug("unsupported command char: {c} {}", .{ ch, ch });
                    return error.ParseError;
                },
            }
        }
        return SvgPath{
            .alloc = null,
            .data = self.cur_data.items[start_data_idx..],
            .cmds = std.mem.bytesAsSlice(PathCommand, self.cur_cmds.items[start_cmd_idx..]),
        };
    }

    fn consumeDelim(self: *PathParser) void {
        while (!self.nextAtEnd()) {
            const ch = self.peekNext();
            _ = std.mem.indexOf(u8, SvgPathDelimiters, &.{ch}) orelse return;
            self.next_pos += 1;
        }
    }

    fn nextAtEnd(self: *PathParser) bool {
        return self.next_pos == self.src.len;
    }

    fn consumeNext(self: *PathParser) void {
        self.next_pos += 1;
    }

    fn peekNext(self: *PathParser) u8 {
        return self.src[self.next_pos];
    }

    fn parseEllipticArc(self: *PathParser, relative: bool) !PathCommand{
        var cmd = PathEllipticArc{
            .rx = try self.parseSvgFloat(),
            .ry = try self.parseSvgFloat(),
            .deg = try self.parseSvgFloat(),
            .large_arc_flag = (try self.parseSvgFloat()) == 1,
            .sweep_flag = (try self.parseSvgFloat()) == 1,
            .x = try self.parseSvgFloat(),
            .y = try self.parseSvgFloat(),
        };
        if (relative) {
            return self.appendCommand(.EllipticArcRel, &cmd);
        } else {
            return self.appendCommand(.EllipticArc, &cmd);
        }
    }

    fn parsePathHorzLineTo(self: *PathParser, relative: bool) !PathCommand {
        var cmd = PathHorzLineTo{
            .x = try self.parseSvgFloat(),
        };
        if (relative) {
            return self.appendCommand(.HorzLineToRel, &cmd);
        } else {
            return self.appendCommand(.HorzLineTo, &cmd);
        }
    }

    fn parsePathVertLineTo(self: *PathParser, relative: bool) !PathCommand {
        var cmd = PathVertLineTo{
            .y = try self.parseSvgFloat(),
        };
        if (relative) {
            return self.appendCommand(.VertLineToRel, &cmd);
        } else {
            return self.appendCommand(.VertLineTo, &cmd);
        }
    }

    fn parseLineTo(self: *PathParser, relative: bool) !PathCommand {
        var cmd = PathLineTo{
            .x = try self.parseSvgFloat(),
            .y = try self.parseSvgFloat(),
        };
        if (relative) {
            return self.appendCommand(.LineToRel, &cmd);
        } else {
            return self.appendCommand(.LineTo, &cmd);
        }
    }

    fn appendCommand(self: *PathParser, comptime Tag: PathCommand, cmd: *PathCommandData(Tag)) PathCommand {
        const Size = @sizeOf(std.meta.Child(@TypeOf(cmd))) / 4;
        self.cur_data.appendSlice(@ptrCast(*[Size]f32, cmd)) catch unreachable;
        return Tag;
    }

    fn parseMoveTo(self: *PathParser, relative: bool) !PathCommand {
        // log.debug("parse moveto", .{});
        var cmd = PathMoveTo{
            .x = try self.parseSvgFloat(),
            .y = try self.parseSvgFloat(),
        };
        if (relative) {
            return self.appendCommand(.MoveToRel, &cmd);
        } else {
            return self.appendCommand(.MoveTo, &cmd);
        }
    }

    fn parseSvgSmoothCurveto(self: *PathParser, relative: bool) !PathCommand {
        var cmd = PathSmoothCurveTo{
            .c2_x = try self.parseSvgFloat(),
            .c2_y = try self.parseSvgFloat(),
            .x = try self.parseSvgFloat(),
            .y = try self.parseSvgFloat(),
        };
        if (relative) {
            return self.appendCommand(.SmoothCurveToRel, &cmd);
        } else {
            return self.appendCommand(.SmoothCurveTo, &cmd);
        }
    }

    fn parseSvgCurveto(self: *PathParser, relative: bool) !PathCommand {
        var cmd = PathCurveTo{
            .ca_x = try self.parseSvgFloat(),
            .ca_y = try self.parseSvgFloat(),
            .cb_x = try self.parseSvgFloat(),
            .cb_y = try self.parseSvgFloat(),
            .x = try self.parseSvgFloat(),
            .y = try self.parseSvgFloat(),
        };
        if (relative) {
            return self.appendCommand(.CurveToRel, &cmd);
        } else {
            return self.appendCommand(.CurveTo, &cmd);
        }
    }

    fn parseSvgFloat(self: *PathParser) !f32 {
        // log.debug("parse float", .{});
        self.consumeDelim();

        self.temp_buf.clearRetainingCapacity();

        var allow_decimal = true;
        var is_valid = false;

        // Check first character.
        if (self.nextAtEnd()) {
            return error.ParseError;
        }
        var ch = self.peekNext();
        if (std.ascii.isDigit(ch)) {
            is_valid = true;
            self.temp_buf.append(ch) catch unreachable;
        } else if (ch == '-') {
            self.temp_buf.append(ch) catch unreachable;
        } else if (ch == '.') {
            allow_decimal = false;
        } else {
            return error.ParseError;
        }
        self.consumeNext();

        while (true) {
            if (self.nextAtEnd()) {
                break;
            }
            ch = self.peekNext();
            if (std.ascii.isDigit(ch)) {
                is_valid = true;
                self.temp_buf.append(ch) catch unreachable;
                self.consumeNext();
                continue;
            }
            if (allow_decimal and ch == '.') {
                allow_decimal = false;
                self.temp_buf.append(ch) catch unreachable;
                self.consumeNext();
                continue;
            }
            // Not a float char. Check to see if we already have a valid number.
            if (is_valid) {
                break;
            } else {
                return error.ParseError;
            }
        }
        return std.fmt.parseFloat(f32, self.temp_buf.items) catch unreachable;
    }
};

const SvgPathDelimiters = " ,\r\n\t";

pub fn parseSvgPath(alloc: std.mem.Allocator, str: []const u8) !SvgPath {
    var parser = PathParser.init(alloc);
    defer parser.deinit();
    return parser.parseAlloc(alloc, str);
}

test "parseSvgPath absolute moveto" {
    const res = try parseSvgPath(t.alloc, "M394,106");
    defer res.deinit();

    try t.eq(res.cmds[0], .MoveTo);
    const data = res.getData(.MoveTo, 0);
    try t.eq(data.x, 394);
    try t.eq(data.y, 106);
}

test "parseSvgPath relative curveto" {
    const res = try parseSvgPath(t.alloc, "c-10.2,7.3-24,12-37.7,12");
    defer res.deinit();

    try t.eq(res.cmds[0], .CurveToRel);
    const data = res.getData(.CurveToRel, 0);
    try t.eq(data.ca_x, -10.2);
    try t.eq(data.ca_y, 7.3);
    try t.eq(data.cb_x, -24);
    try t.eq(data.cb_y, 12);
    try t.eq(data.x, -37.7);
    try t.eq(data.y, 12);
}

test "parseSvgPath curveto polybezier" {
    const res = try parseSvgPath(t.alloc, "m293,111s-12-8-13.5-6c0,0,10.5,6.5,13,15,0,0-1.5-9,0.5-9z");
    defer res.deinit();

    try t.eq(res.cmds.len, 5);
    try t.eq(res.cmds[2], .CurveToRel);
    var cmd = res.getData(.CurveToRel, 6);
    try t.eq(cmd.ca_x, 0);
    try t.eq(cmd.ca_y, 0);
    try t.eq(cmd.cb_x, 10.5);
    try t.eq(cmd.cb_y, 6.5);
    try t.eq(cmd.x, 13);
    try t.eq(cmd.y, 15);
    try t.eq(res.cmds[3], .CurveToRel);
    cmd = res.getData(.CurveToRel, 12);
    try t.eq(cmd.ca_x, 0);
    try t.eq(cmd.ca_y, 0);
    try t.eq(cmd.cb_x, -1.5);
    try t.eq(cmd.cb_y, -9);
    try t.eq(cmd.x, 0.5);
    try t.eq(cmd.y, -9);
}

test "PathParser.parse" {
    // Just check length.
    const path =
        \\M394,106c-10.2,7.3-24,12-37.7,12c-29,0-51.1-20.8-51.1-48.3c0-27.3,22.5-48.1,52-48.1
        \\c14.3,0,29.2,5.5,38.9,14l-13,15c-7.1-6.3-16.8-10-25.9-10c-17,0-30.2,12.9-30.2,29.5c0,16.8,13.3,29.6,30.3,29.6
        \\c5.7,0,12.8-2.3,19-5.5L394,106z
    ;
    const res = try parseSvgPath(t.alloc, path);
    defer res.deinit();
    try t.eq(res.cmds.len, 12);
}

test "PathParser.parse CR/LF" {
    const path = "M394,106\r\nM100,100";
    const res = try parseSvgPath(t.alloc, path);
    defer res.deinit();
}

test "SvgParser.parse CR/LF" {
    var parser = SvgParser.init(t.alloc);
    defer parser.deinit();

    const svg = "<svg><polygon points=\"10,10\r\n10,10\"/></svg>";
    _ = try parser.parse(svg);
}

test "SvgParser.parse viewbox" {
    var parser = SvgParser.init(t.alloc);
    defer parser.deinit();

    const svg =
        \\<svg xmlns="http://www.w3.org/2000/svg" viewBox="1 2 24 25">
        \\  <g>
        \\    <path fill="none" d="M0 0h24v24H0z"/>
        \\  </g>
        \\</svg>
        ;

    const res = try parser.parse(svg);
    try t.eq(res.min_x, 1);
    try t.eq(res.min_y, 2);
    try t.eq(res.width, 24);
    try t.eq(res.height, 25);
}

test "PathParser.parse with continuation of the same command type." {
    const path = "M12 22C6.477 22 2 17.523 2 12S6.477 2 12 2s10 4.477 10 10-4.477 10-10 10zm0-2a8 8 0 1 0 0-16 8 8 0 0 0 0 16zm0-9.414l2.828-2.829 1.415 1.415L13.414 12l2.829 2.828-1.415 1.415L12 13.414l-2.828 2.829-1.415-1.415L10.586 12 7.757 9.172l1.415-1.415L12 10.586z";
    const res = try parseSvgPath(t.alloc, path);
    defer res.deinit();
    try t.eq(res.cmds.len, 24);
}

const SvgElement = enum {
    Svg,
    Group,
    Polygon,
    Path,
    Rect,
};

const Attribute = struct {
    key: []const u8,
    value: ?[]const u8,
};

const SvgDrawState = struct {
    // Empty indicates fill=none (don't do fill op)
    fill: ?Color,
    stroke: ?Color,

    transform: ?Transform,
};

// Fast parser that just extracts draw commands from svg file. No ast returned.
pub const SvgParser = struct {
    alloc: std.mem.Allocator,
    src: []const u8,
    next_ch_idx: u32,

    extra_data: std.ArrayList(f32),
    cmd_data: ds.DynamicArrayList(u32, f32),
    sub_cmds: std.ArrayList(u8),
    cmds: std.ArrayList(DrawCommandPtr),
    elem_map: ds.OwnedKeyStringHashMap(SvgElement),
    str_buf: std.ArrayList(u8),
    state_stack: std.ArrayList(SvgDrawState),
    path_parser: PathParser,
    last_err: []const u8,

    /// Parsed viewbox.
    min_x: f32,
    min_y: f32,
    width: f32,
    height: f32,

    // Keep track of the current colors set to determine adding FillColor/StrokeColor ops.
    cur_fill: ?Color,
    cur_stroke: ?Color,

    // Current transform to apply to coords.
    // TODO: implement transforms. We'd need to apply transform to every vertex generated. Probable solution is to
    // append transform commands to DrawCommandList in a way similar to setFillColor
    cur_transform: ?Transform,

    pub fn init(alloc: std.mem.Allocator) SvgParser {
        var elem_map = ds.OwnedKeyStringHashMap(SvgElement).init(alloc);
        elem_map.put("svg", .Svg) catch unreachable;
        elem_map.put("g", .Group) catch unreachable;
        elem_map.put("polygon", .Polygon) catch unreachable;
        elem_map.put("path", .Path) catch unreachable;
        elem_map.put("rect", .Rect) catch unreachable;
        return .{
            .alloc = alloc,
            .src = undefined,
            .next_ch_idx = undefined,
            .extra_data = std.ArrayList(f32).init(alloc),
            .cmd_data = ds.DynamicArrayList(u32, f32).init(alloc),
            .cmds = std.ArrayList(DrawCommandPtr).init(alloc),
            .sub_cmds = std.ArrayList(u8).init(alloc),
            .elem_map = elem_map,
            .str_buf = std.ArrayList(u8).init(alloc),
            .state_stack = std.ArrayList(SvgDrawState).init(alloc),
            .cur_fill = undefined,
            .cur_stroke = undefined,
            .cur_transform = undefined,
            .path_parser = PathParser.init(alloc),
            .last_err = "",
            .min_x = 0,
            .min_y = 0,
            .width = 0,
            .height = 0,
        };
    }

    pub fn deinit(self: *SvgParser) void {
        self.extra_data.deinit();
        self.cmd_data.deinit();
        self.sub_cmds.deinit();
        self.cmds.deinit();
        self.elem_map.deinit();
        self.str_buf.deinit();
        self.state_stack.deinit();
        self.path_parser.deinit();
        self.alloc.free(self.last_err);
    }

    fn reportError(self: *SvgParser, comptime format: []const u8, args: anytype) void {
        self.alloc.free(self.last_err);
        self.last_err = std.fmt.allocPrint(self.alloc, format, args) catch fatal();
    }

    pub fn parseAlloc(self: *SvgParser, alloc: std.mem.Allocator, src: []const u8) !SvgRenderData {
        const res = try self.parse(src);
        const cmds = res.cmds;
        const new_cmd_data = alloc.alloc(f32, cmds.cmd_data.len) catch unreachable;
        std.mem.copy(f32, new_cmd_data, cmds.cmd_data);
        const new_extra_data = alloc.alloc(f32, cmds.extra_data.len) catch unreachable;
        std.mem.copy(f32, new_extra_data, cmds.extra_data);
        const new_cmds = alloc.alloc(DrawCommandPtr, cmds.cmds.len) catch unreachable;
        std.mem.copy(DrawCommandPtr, new_cmds, cmds.cmds);
        const new_sub_cmds = alloc.alloc(u8, cmds.sub_cmds.len) catch unreachable;
        std.mem.copy(u8, new_sub_cmds, cmds.sub_cmds);
        return SvgRenderData{
            .min_x = self.min_x,
            .min_y = self.min_y,
            .width = self.width,
            .height = self.height,
            .cmds = DrawCommandList{
                .alloc = alloc,
                .extra_data = new_extra_data,
                .cmd_data = new_cmd_data,
                .cmds = new_cmds,
                .sub_cmds = new_sub_cmds,
            },
        };
    }

    pub fn parse(self: *SvgParser, src: []const u8) !SvgRenderData {
        self.src = src;
        self.next_ch_idx = 0;

        self.extra_data.clearRetainingCapacity();
        self.cmd_data.clearRetainingCapacity();
        self.sub_cmds.clearRetainingCapacity();
        self.cmds.clearRetainingCapacity();
        self.state_stack.clearRetainingCapacity();

        // Root state.
        try self.state_stack.append(.{
            .fill = Color.Black,
            .stroke = null,
            .transform = null,
        });
        self.cur_fill = null;
        self.cur_stroke = null;
        self.cur_transform = null;

        while (!self.nextAtEnd()) {
            _ = self.parseElement() catch {
                log.debug("error: {s}", .{self.last_err});
                return error.ParseError;
            };
        }

        return SvgRenderData{
            .min_x = self.min_x,
            .min_y = self.min_y,
            .width = self.width,
            .height = self.height,
            .cmds = DrawCommandList{
                .alloc = null,
                .extra_data = self.extra_data.items,
                .cmd_data = self.cmd_data.buf.items,
                .cmds = self.cmds.items,
                .sub_cmds = self.sub_cmds.items,
            },
        };
    }

    fn parsePath(self: *SvgParser) !void {
        // log.debug("parse path", .{});
        while (try self.parseAttribute()) |attr| {
            if (stdx.string.eq(attr.key, "d")) {
                if (attr.value) |value| {
                    const sub_cmd_start = self.sub_cmds.items.len;
                    const data_start = self.extra_data.items.len;
                    const res = try self.path_parser.parseAppend(&self.sub_cmds, &self.extra_data, value);
                    // log.debug("path: {}cmds {s}", .{res.cmds.len, value});

                    const state = self.getCurrentState();

                    // Fill path.
                    if (state.fill != null) {
                        if (self.cur_fill == null or state.fill.?.value != self.cur_fill.?.value) {
                            const ptr = self.cmd_data.append(draw_cmd.FillColorCommand{
                                .rgba = state.fill.?.toU32(),
                            }) catch unreachable;
                            self.cmds.append(.{ .tag = .FillColor, .id = ptr.id }) catch unreachable;
                        }
                        self.cur_fill = state.fill.?;

                        const ptr = self.cmd_data.append(draw_cmd.FillPathCommand{
                            .num_cmds = @intCast(u32, res.cmds.len),
                            .start_path_cmd_id = @intCast(u32, sub_cmd_start),
                            .start_data_id = @intCast(u32, data_start),
                        }) catch unreachable;
                        self.cmds.append(.{ .tag = .FillPath, .id = ptr.id }) catch unreachable;
                    }
                }
            }
        }
        try self.consume('/');
        try self.consume('>');
    }

    fn getCurrentState(self: *SvgParser) SvgDrawState {
        return self.state_stack.items[self.state_stack.items.len - 1];
    }

    fn parseRect(self: *SvgParser) !void {
        // log.debug("parse rect", .{});
        var req_fields: u4 = 0;
        var x: f32 = undefined;
        var y: f32 = undefined;
        var width: f32 = undefined;
        var height: f32 = undefined;
        while (try self.parseAttribute()) |attr| {
            // log.debug("{s}: {s}", .{attr.key, attr.value.?});
            if (std.mem.eql(u8, attr.key, "x")) {
                if (attr.value) |value| {
                    x = try std.fmt.parseFloat(f32, value);
                    req_fields |= 1;
                }
            } else if (std.mem.eql(u8, attr.key, "y")) {
                if (attr.value) |value| {
                    y = try std.fmt.parseFloat(f32, value);
                    req_fields |= 1 << 1;
                }
            } else if (std.mem.eql(u8, attr.key, "width")) {
                if (attr.value) |value| {
                    width = try std.fmt.parseFloat(f32, value);
                    req_fields |= 1 << 2;
                }
            } else if (std.mem.eql(u8, attr.key, "height")) {
                if (attr.value) |value| {
                    height = try std.fmt.parseFloat(f32, value);
                    req_fields |= 1 << 3;
                }
            }
        }
        if (req_fields == (1 << 4) - 1) {
            const state = self.getCurrentState();

            // Fill rect.
            if (state.fill != null) {
                if (self.cur_fill == null or state.fill.?.value != self.cur_fill.?.value) {
                    const ptr = self.cmd_data.append(draw_cmd.FillColorCommand{
                        .rgba = state.fill.?.toU32(),
                    }) catch unreachable;
                    self.cmds.append(.{ .tag = .FillColor, .id = ptr.id }) catch unreachable;
                }
                self.cur_fill = state.fill.?;

                const ptr = self.cmd_data.append(draw_cmd.FillRectCommand{
                    .x = x,
                    .y = y,
                    .width = width,
                    .height = height,
                }) catch unreachable;
                self.cmds.append(.{ .tag = .FillRect, .id = ptr.id }) catch unreachable;
            }
        }
        try self.consume('/');
        try self.consume('>');
    }

    fn parsePolygon(self: *SvgParser) !void {
        // log.debug("parse polygon", .{});
        while (try self.parseAttribute()) |attr| {
            // log.debug("{s}: {s}", .{attr.key, attr.value});
            if (std.mem.eql(u8, attr.key, "points")) {
                if (attr.value) |value| {
                    var iter = std.mem.tokenize(u8, value, "\r\n\t ");
                    var num_verts: u32 = 0;
                    const start_vert_id = @intCast(u32, self.extra_data.items.len);
                    while (iter.next()) |pair| {
                        const sep_idx = stdx.string.indexOf(pair, ',') orelse {
                            self.reportError("Expected , in points.", .{});
                            return error.ParseError;
                        };
                        const x = try std.fmt.parseFloat(f32, pair[0..sep_idx]);
                        const y = try std.fmt.parseFloat(f32, pair[sep_idx + 1 ..]);
                        self.extra_data.appendSlice(&.{ x, y }) catch unreachable;
                        num_verts += 1;
                    }

                    const state = self.getCurrentState();

                    // Fill polygon.
                    if (state.fill != null) {
                        if (self.cur_fill == null or state.fill.?.value != self.cur_fill.?.value) {
                            const ptr = self.cmd_data.append(draw_cmd.FillColorCommand{
                                .rgba = state.fill.?.toU32(),
                            }) catch unreachable;
                            self.cmds.append(.{ .tag = .FillColor, .id = ptr.id }) catch unreachable;
                        }
                        self.cur_fill = state.fill.?;

                        const ptr = self.cmd_data.append(draw_cmd.FillPolygonCommand{
                            .num_vertices = num_verts,
                            .start_vertex_id = start_vert_id,
                        }) catch unreachable;
                        self.cmds.append(.{ .tag = .FillPolygon, .id = ptr.id }) catch unreachable;
                    }
                }
            }
        }
        try self.consume('/');
        try self.consume('>');
    }

    fn parseFunctionLastFloatArg(self: *SvgParser, str: []const u8, next_pos: *u32) !f32 {
        _ = self;
        const pos = next_pos.*;
        if (string.indexOfPos(str, pos, ')')) |end| {
            const res = try std.fmt.parseFloat(f32, str[pos..end]);
            next_pos.* = @intCast(u32, end) + 1;
            return res;
        } else {
            return error.ParseError;
        }
    }

    fn parseFunctionFloatArg(self: *SvgParser, str: []const u8, next_pos: *u32) !f32 {
        _ = self;
        const pos = next_pos.*;
        if (string.indexOfPos(str, pos, ',')) |end| {
            const res = try std.fmt.parseFloat(f32, str[pos..end]);
            next_pos.* = @intCast(u32, end) + 1;
            return res;
        } else {
            return error.ParseError;
        }
    }

    // Parses from an attribute value.
    fn parseFunctionName(self: *SvgParser, str: []const u8, next_pos: *u32) !?[]const u8 {
        _ = self;
        var pos = next_pos.*;
        if (pos == str.len) {
            return null;
        }

        // consume whitespace.
        var ch = str[pos];
        while (std.ascii.isSpace(ch)) {
            pos += 1;
            if (pos == str.len) {
                return null;
            }
            ch = str[pos];
        }

        const start_pos = pos;
        if (!std.ascii.isAlpha(ch)) {
            return error.ParseError;
        }
        pos += 1;
        while (true) {
            if (pos == str.len) {
                return error.ParseError;
            }
            ch = str[pos];
            if (ch == '(') {
                next_pos.* = pos + 1;
                return str[start_pos..pos];
            }
            pos += 1;
        }
    }

    fn parseSvgElement(self: *SvgParser) !void {
        while (try self.parseAttribute()) |attr| {
            if (std.ascii.eqlIgnoreCase(attr.key, "viewbox")) {
                if (attr.value) |value| {
                    var iter = std.mem.tokenize(u8, value, " ");
                    self.min_x = try std.fmt.parseFloat(f32, iter.next().?);
                    self.min_y = try std.fmt.parseFloat(f32, iter.next().?);
                    self.width = try std.fmt.parseFloat(f32, iter.next().?);
                    self.height = try std.fmt.parseFloat(f32, iter.next().?);
                }
            }
        }
        try self.consume('>');
        try self.parseChildrenAndCloseTag();
    }

    // Parses until end element '>' is consumed.
    fn parseGroup(self: *SvgParser) !void {
        // log.debug("parse group", .{});

        // Need a flag to separate declaring "none" and not having a value at all.
        var declared_fill = false;
        var fill: ?Color = null;
        var transform: ?Transform = null;
        while (try self.parseAttribute()) |attr| {
            self.str_buf.resize(attr.key.len) catch unreachable;
            const lower = stdx.string.toLower(attr.key, self.str_buf.items);
            if (string.eq(lower, "fill")) {
                if (attr.value) |value| {
                    if (stdx.string.eq(value, "none")) {
                        fill = null;
                    } else {
                        const c = try Color.parse(value);
                        fill = c;
                    }
                    declared_fill = true;
                }
            } else if (string.eq(lower, "transform")) {
                if (attr.value) |value| {
                    var next_pos: u32 = 0;
                    if (try self.parseFunctionName(value, &next_pos)) |name| {
                        if (string.eq(name, "matrix")) {
                            const m0 = try self.parseFunctionFloatArg(value, &next_pos);
                            const m1 = try self.parseFunctionFloatArg(value, &next_pos);
                            const m2 = try self.parseFunctionFloatArg(value, &next_pos);
                            const m3 = try self.parseFunctionFloatArg(value, &next_pos);
                            const m4 = try self.parseFunctionFloatArg(value, &next_pos);
                            const m5 = try self.parseFunctionLastFloatArg(value, &next_pos);
                            transform = Transform.initRowMajor([16]f32{
                                m0, m2, 0, m4,
                                m1, m3, 0, m5,
                                0,  0,  1, 0,
                                0,  0,  0, 1,
                            });
                            // log.debug("yay matrix {} {} {} {} {} {}", .{m0, m1, m2, m3, m4, m5});
                            // unreachable;
                        }
                    }
                }
            }
        }
        try self.consume('>');

        var state = self.getCurrentState();

        self.cur_transform = if (transform != null) transform.? else state.transform;
        self.state_stack.append(.{
            .fill = if (declared_fill) fill else state.fill,
            .stroke = state.stroke,
            .transform = self.cur_transform,
        }) catch unreachable;

        try self.parseChildrenAndCloseTag();
        _ = self.state_stack.pop();

        // Need to restore cur_transform. cur_fill/cur_stroke track the current graphics state.
        state = self.getCurrentState();
        self.cur_transform = state.transform;
    }

    fn parseAttribute(self: *SvgParser) !?Attribute {
        const key = try self.parseAttributeKey();
        if (key == null) return null;
        // log.debug("attr key: {s}", .{key.?});
        try self.consume('=');
        try self.consume('"');
        if (self.nextAtEnd()) return error.ParseError;
        const start_idx = self.next_ch_idx;
        try self.consumeUntilIncl('"');
        const value = self.src[start_idx .. self.next_ch_idx - 1];
        return Attribute{ .key = key.?, .value = value };
    }

    fn consumeUntilIncl(self: *SvgParser, ch: u8) !void {
        while (self.peekNext() != ch) {
            self.next_ch_idx += 1;
            if (self.nextAtEnd()) {
                return error.ParseError;
            }
        }
        self.next_ch_idx += 1;
    }

    fn consume(self: *SvgParser, ch: u8) !void {
        if (self.nextAtEnd()) {
            return error.ParseError;
        }
        if (self.peekNext() == ch) {
            self.next_ch_idx += 1;
        } else {
            log.debug("Failed to consume: {c} at {}", .{ ch, self.next_ch_idx });
            return error.ParseError;
        }
    }

    fn consumeUntilWhitespace(self: *SvgParser) void {
        while (!std.ascii.isSpace(self.peekNext())) {
            self.next_ch_idx += 1;
            if (self.nextAtEnd()) {
                break;
            }
        }
    }

    fn consumeWhitespaces(self: *SvgParser) void {
        while (std.ascii.isSpace(self.peekNext())) {
            self.next_ch_idx += 1;
            if (self.nextAtEnd()) {
                break;
            }
        }
    }

    fn peekNext(self: *SvgParser) u8 {
        return self.src[self.next_ch_idx];
    }

    fn hasLookahead(self: *SvgParser, n: u32, ch: u8) bool {
        if (self.next_ch_idx + n < self.src.len) {
            return self.src[self.next_ch_idx + n] == ch;
        } else {
            return false;
        }
    }

    // Returns whether an element was parsed.
    fn parseElement(self: *SvgParser) anyerror!bool {
        // log.debug("parse element", .{});
        const ch = self.peekNext();
        if (std.ascii.isSpace(ch)) {
            self.consumeWhitespaces();
        }

        if (self.nextAtEnd()) {
            return false;
        }
        if (self.peekNext() == '<') {
            // End of a parent element.
            if (self.hasLookahead(1, '/')) {
                return false;
            }
        } else return error.ParseError;

        try self.consume('<');
        if (self.peekNext() == '?') {
            // Skip xml declaration.
            _ = try self.consumeToTagEnd();
            return true;
        }
        const name = try self.parseTagName();
        // log.debug("elem name: {s}", .{name});
        self.str_buf.resize(name.len) catch unreachable;
        if (self.elem_map.get(stdx.string.toLower(name, self.str_buf.items))) |elem| {
            switch (elem) {
                .Svg => try self.parseSvgElement(),
                .Group => try self.parseGroup(),
                .Polygon => try self.parsePolygon(),
                .Path => try self.parsePath(),
                .Rect => try self.parseRect(),
            }
            return true;
        } else {
            if (self.nextAtEnd()) {
                return error.ParseError;
            }

            const single_elem = try self.consumeToTagEnd();
            if (single_elem) {
                return true;
            }
            try self.parseChildrenAndCloseTag();
            return true;
        }
    }

    fn parseChildrenAndCloseTag(self: *SvgParser) !void {
        // log.debug("parse children", .{});
        while (try self.parseElement()) {}

        // Parse close tag.
        if (self.nextAtEnd()) {
            return error.ParseError;
        }
        try self.consume('<');
        try self.consume('/');
        _ = try self.parseTagName();
        try self.consume('>');
    }

    // Returns whether tag is single element.
    fn consumeToTagEnd(self: *SvgParser) !bool {
        while (true) {
            var ch = self.peekNext();
            if (ch == '>') {
                self.next_ch_idx += 1;
                return false;
            } else if (ch == '/') {
                self.next_ch_idx += 1;
                if (self.nextAtEnd()) {
                    return error.ParseError;
                }
                ch = self.peekNext();
                if (ch == '>') {
                    self.next_ch_idx += 1;
                    return true;
                }
            }
            self.next_ch_idx += 1;
            if (self.nextAtEnd()) {
                return error.ParseError;
            }
        }
    }

    fn nextAtEnd(self: *SvgParser) bool {
        return self.next_ch_idx == self.src.len;
    }

    fn parseAttributeKey(self: *SvgParser) anyerror!?[]const u8 {
        if (self.nextAtEnd()) {
            return error.ParseError;
        }
        var ch = self.peekNext();
        if (std.ascii.isAlpha(ch)) {
            const start = self.next_ch_idx;
            while (true) {
                if (ch == '=') {
                    break;
                }
                if (std.ascii.isSpace(ch)) {
                    return error.ParseError;
                }
                self.next_ch_idx += 1;
                if (self.nextAtEnd()) {
                    return error.ParseError;
                }
                ch = self.peekNext();
            }
            return self.src[start..self.next_ch_idx];
        } else if (std.ascii.isSpace(ch)) {
            self.consumeWhitespaces();
            return try self.parseAttributeKey();
        } else {
            return null;
        }
    }

    fn parseTagName(self: *SvgParser) ![]const u8 {
        if (self.nextAtEnd()) {
            return error.ParseError;
        }
        var ch = self.peekNext();
        if (std.ascii.isSpace(ch)) {
            self.consumeWhitespaces();
            if (self.nextAtEnd()) {
                return error.ParseError;
            }
            ch = self.peekNext();
        }
        if (std.ascii.isAlpha(ch)) {
            const start = self.next_ch_idx;
            while (true) {
                if (std.ascii.isSpace(ch) or ch == '>') {
                    break;
                }
                self.next_ch_idx += 1;
                if (self.nextAtEnd()) {
                    break;
                }
                ch = self.peekNext();
            }
            return self.src[start..self.next_ch_idx];
        } else {
            log.debug("Failed to consume: {c} at {}", .{ ch, self.next_ch_idx });
            return error.ParseError;
        }
    }
};

pub const SvgRenderData = struct {
    /// Viewbox.
    min_x: f32,
    min_y: f32,
    width: f32,
    height: f32,

    /// Render data.
    cmds: DrawCommandList,

    pub fn deinit(self: SvgRenderData) void {
        self.cmds.deinit();
    }
};