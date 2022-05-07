pub const testing = @import("testing.zig");
pub const debug = @import("debug.zig");
pub const ds = @import("ds/ds.zig");
pub const algo = @import("algo/algo.zig");
pub const log = @import("log.zig");
pub const string = @import("string.zig");
pub const mem = @import("mem.zig");
pub const meta = @import("meta.zig");
pub const heap = @import("heap.zig");
pub const wasm = @import("wasm.zig");
pub const math = @import("math/math.zig");
pub const time = @import("time.zig");
pub const unicode = @import("unicode.zig");
pub const fs = @import("fs.zig");
pub const http = @import("http.zig");
pub const events = @import("events.zig");
pub const net = @import("net.zig");
pub const textbuf = struct {
    pub const document = @import("textbuf/document.zig");
};

const closure = @import("closure.zig");
pub const Closure = closure.Closure;
pub const ClosureIface = closure.ClosureIface;
const callback = @import("callback.zig");
pub const Callback = callback.Callback;

// Common utils.
pub const panic = debug.panic;
pub const panicFmt = debug.panicFmt;

pub const Function = closure.Function;
