const std = @import("std");
const stdx = @import("stdx");
const Vec2 = stdx.math.Vec2;
const vec2 = Vec2.init;
const math = std.math;

const log = stdx.log.scoped(.curve);

pub const QuadBez = struct {
    const Self = @This();

    const BasicTransform = struct {
        x0: f32,
        x1: f32,
        scale: f32,
        cross: f32,
    };

    x0: f32,
    y0: f32,
    cx: f32,
    cy: f32,
    x1: f32,
    y1: f32,

    /// Return transform values to map from the quadratic bezier to the basic parabola.
    fn mapToBasic(self: Self) BasicTransform {
        const ddx = 2 * self.cx - self.x0 - self.x1;
        const ddy = 2 * self.cy - self.y0 - self.y1;
        const r0 = (self.cx - self.x0) * ddx + (self.cy - self.y0) * ddy;
        const r1 = (self.x1 - self.cx) * ddx + (self.y1 - self.cy) * ddy;
        const cross = (self.x1 - self.x0) * ddy - (self.y1 - self.y0) * ddx;
        const x0 = r0 / cross;
        const x1 = r1 / cross;
        // There's probably a more elegant formulation of this...
        const scale = math.absFloat(cross) / (math.hypot(f32, ddx, ddy) * math.absFloat(x1 - x0));
        return BasicTransform{
            .x0 = x0,
            .x1 = x1,
            .scale = scale,
            .cross = cross,
        };
    }

    /// Given t, return the (x, y) along the curve.
    pub fn eval(self: Self, t: f32) Vec2 {
        const mt = 1 - t;
        const x = self.x0 * mt * mt + 2 * self.cx * t * mt + self.x1 * t * t;
        const y = self.y0 * mt * mt + 2 * self.cy * t * mt + self.y1 * t * t;
        return Vec2.init(x, y);
    }

    /// Given error tolerance, output the minimum points needed to flatten the curve.
    /// The algorithm was developed by Raph Levien.
    /// This has an advantage over other methods since it determines the t values beforehand
    /// so that each t value can be evaluated in parallel, although the implementation is not taking advantage of that right now.
    pub fn flatten(self: Self, tol: f32, buf: *std.ArrayList(Vec2)) void {
        const params = self.mapToBasic();
        const a0 = approx_myint(params.x0);
        const a1 = approx_myint(params.x1);
        var count =  0.5 * math.absFloat(a1 - a0) * math.sqrt(params.scale / tol);
        // If count is NaN the curve can be approximated by a single straight line or a point.
        if (!math.isFinite(count)) {
            count = 1;
        }
        const n = @floatToInt(u32, math.ceil(count));
        buf.ensureTotalCapacity(n) catch unreachable;
        buf.items.len = n + 1;
        const r0 = approx_inv_myint(a0);
        const r1 = approx_inv_myint(a1);
        buf.items[0] = vec2(self.x0, self.y0);
        var i: u32 = 1;
        while (i < n) : (i += 1) {
            const r = approx_inv_myint(a0 + ((a1 - a0) * @intToFloat(f32, i)) / @intToFloat(f32, n));
            const t = (r - r0) / (r1 - r0);
            buf.items[i] = self.eval(t);
        }
        buf.items[n] = vec2(self.x1, self.y1);
    }
};

// Compute an approximation to int (1 + 4x^2) ^ -0.25 dx
// This isn't especially good but will do.
fn approx_myint(x: f32) f32 {
    const d = 0.67;
    return x / (1 - d + math.pow(f32, math.pow(f32, d, 4) + 0.25 * x * x, 0.25));
}

// Approximate the inverse of the function above.
// This is better.
fn approx_inv_myint(x: f32) f32 {
    const b = 0.39;
    return x * (1 - b + math.sqrt(b * b + 0.25 * x * x));
}

pub const SubQuadBez = struct {
    bez: QuadBez,
    a0: f32,
    a1: f32,
    val: f32,
};

pub const CubicBez = struct {
    const Self = @This();

    x0: f32,
    y0: f32,
    cx0: f32,
    cy0: f32,
    cx1: f32,
    cy1: f32,
    x1: f32,
    y1: f32,

    fn weightsum(self: Self, c0: f32, c1: f32, c2: f32, c3: f32) Vec2 {
        const x = c0 * self.x0 + c1 * self.cx0 + c2 * self.cx1 + c3 * self.x1;
        const y = c0 * self.y0 + c1 * self.cy0 + c2 * self.cy1 + c3 * self.y1;
        return vec2(x, y);
    }

    /// Given error tolerance, output the minimum points needed to flatten the curve.
    /// The cubic bezier is first converted into quad bezier curves and then uses the same quad bezier flatten algorithm.
    pub fn flatten(self: Self, tol: f32, buf: *std.ArrayList(Vec2), qbez_buf: *std.ArrayList(SubQuadBez)) void {
        const tol1 = 0.1 * tol; // error for subdivision into quads
        const tol2 = tol - tol1; // error for subdivision of quads into lines
        const sqrt_tol2 = math.sqrt(tol2);
        const err2 = self.weightsum(1, -3, 3, -1).squareLength();
        const n_quads = math.ceil(math.pow(f32, err2 / (432 * tol1 * tol1), @as(f32, 1)/@as(f32, 6)));
        const n_quads_i = @floatToInt(u32, n_quads);

        qbez_buf.ensureTotalCapacity(n_quads_i) catch unreachable;
        qbez_buf.items.len = n_quads_i;
        var sum: f32 = 0;
        var i: u32 = 0;
        while (i < n_quads_i) : (i += 1) {
            const t0 = @intToFloat(f32, i) / n_quads;
            const t1 = @intToFloat(f32, i + 1) / n_quads;
            const sub = self.subsegment(t0, t1);
            const quad = sub.midpointQBez();
            const params = quad.mapToBasic();
            const a0 = approx_myint(params.x0);
            const a1 = approx_myint(params.x1);
            const scale = math.sqrt(params.scale);
            var val = math.absFloat(a1 - a0) * scale;
            if (math.signbit(params.x0) != math.signbit(params.x1)) {
                // min x value in basic parabola to make sure we don't skip cusp
                const xmin = sqrt_tol2 / scale;
                const cusp_val = sqrt_tol2 * math.absFloat(a1 - a0) / approx_myint(xmin);
                // I *think* it will always be larger, but just in case...
                val = math.max(val, cusp_val);
            }
            qbez_buf.items[i] = .{
                .bez = quad,
                .a0 = a0,
                .a1 = a1,
                .val = val,
            };
            sum += val;
        }
        var count = 0.5 * sum / sqrt_tol2;
        // If count is NaN the curve can be approximated by a single straight line or a point.
        if (!math.isFinite(count)) {
            count = 1;
        }
        const n = math.ceil(count);
        const ni = @floatToInt(u32, n);

        buf.ensureTotalCapacity(ni) catch unreachable;
        buf.items.len = ni + 1;

        buf.items[0] = vec2(self.x0, self.y0);
        var val: f32 = 0; // sum of vals from [0..i]
        i = 0;
        var j: u32 = 0;
        while (j < ni) : (j += 1) {
            const target = sum * @intToFloat(f32, j) / n;
            while (val + qbez_buf.items[i].val < target) {
                val += qbez_buf.items[i].val;
                i += 1;
            }
            const a0 = qbez_buf.items[i].a0;
            const a1 = qbez_buf.items[i].a1;
            // Note: we can cut down on recomputing these
            const r0 = approx_inv_myint(a0);
            const r1 = approx_inv_myint(a1);
            const a = a0 + (a1 - a0) * (target - val) / qbez_buf.items[i].val;
            const r = approx_inv_myint(a);
            const t = (r - r0) / (r1 - r0);
            buf.items[j] = qbez_buf.items[i].bez.eval(t);
        }
        buf.items[j] = vec2(self.x1, self.y1);
    }

    fn subsegment(self: Self, t0: f32, t1: f32) Self {
        const p0 = self.eval(t0);
        const p1 = self.eval(t1);
        const scale = (t1 - t0) / 3;
        const d0 = self.deriv(t0);
        const d1 = self.deriv(t1);
        return .{
            .x0 = p0.x,
            .y0 = p0.y,
            .cx0 = p0.x + scale * d0.x,
            .cy0 = p0.y + scale * d0.y,
            .cx1 = p1.x - scale * d1.x,
            .cy1 = p1.y - scale * d1.y,
            .x1 = p1.x,
            .y1 = p1.y,
        };
    }

    fn deriv(self: Self, t: f32) Vec2 {
        const mt = 1 - t;
        const c0 = -3 * mt * mt;
        const c3 = 3 * t * t;
        const c1 = -6 * t * mt - c0;
        const c2 = 6 * t * mt - c3;
        return self.weightsum(c0, c1, c2, c3);
    }

    fn eval(self: Self, t: f32) Vec2 {
        const mt = 1 - t;
        const c0 = mt * mt * mt;
        const c1 = 3 * mt * mt * t;
        const c2 = 3 * mt * t * t;
        const c3 = t * t * t;
        return self.weightsum(c0, c1, c2, c3);
    }

    /// quadratic bezier with matching endpoints and minimum max vector error
    fn midpointQBez(self: Self) QuadBez {
        const p1 = self.weightsum(-0.25, 0.75, 0.75, -0.25);
        return QuadBez{
            .x0 = self.x0,
            .y0 = self.y0,
            .cx = p1.x,
            .cy = p1.y,
            .x1 = self.x1,
            .y1 = self.y1,
        };
    }
};