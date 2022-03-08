const std = @import("std");
const stdx = @import("stdx");
const t = stdx.testing;

const runtime = @import("../cosmic/runtime.zig");

test "behavior: JS syntax error prints stack trace to stderr" {
    {
        const res = run(
            \\class {
        );
        defer res.deinit();
        try t.eq(res.success, false);
        try t.eqStr(res.stderr,
            \\class {
            \\      ^
            \\Uncaught SyntaxError: Unexpected token '{'
            \\    at /test.js:1:6
            \\
        );
    }
    {
        // Case where v8 returns the same message start/end column indicator.
        const res = run(
            \\class Foo {
            \\    x: 0
        );
        defer res.deinit();
        try t.eq(res.success, false);
        try t.eqStr(res.stderr,
            \\    x: 0
            \\    ^
            \\Uncaught SyntaxError: Unexpected identifier
            \\    at /test.js:2:4
            \\
        );
    }
}

test "behavior: JS main script runtime error prints stack trace to stderr" {
    const res = run(
        \\foo
    );
    defer res.deinit();
    try t.eq(res.success, false);
    try t.eqStr(res.stderr,
        \\ReferenceError: foo is not defined
        \\    at /test.js:1:1
        \\
    );
}

const RunResult = struct {
    const Self = @This();

    success: bool,
    stderr: []const u8,

    fn deinit(self: Self) void {
        t.alloc.free(self.stderr);
    }
};

fn run(source: []const u8) RunResult {
    var stderr_capture = std.ArrayList(u8).init(t.alloc);
    var stderr_writer = stderr_capture.writer();
    var success = true;
    runtime.runUserMainAbs(t.alloc, "/test.js", false, .{
        .main_script_override = source,
        .error_writer = runtime.WriterIface.init(&stderr_writer),
    }) catch {
        success = false;
    };
    return RunResult{
        .success = success,
        .stderr = stderr_capture.toOwnedSlice(),
    };
}