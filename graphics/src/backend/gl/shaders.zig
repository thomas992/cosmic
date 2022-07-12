const std = @import("std");
const builtin = @import("builtin");
const IsWasm = builtin.target.isWasm();
const stdx = @import("stdx");
const Vec2 = stdx.math.Vec2;
const Mat4 = stdx.math.Mat4;
const gl = @import("gl");

const graphics = @import("../../graphics.zig");
const TexShaderVertex = graphics.gpu.TexShaderVertex;
const Shader = graphics.gl.Shader;
const Color = graphics.Color;

const tex_vert = @embedFile("shaders/tex_vert.glsl");
const tex_frag = @embedFile("shaders/tex_frag.glsl");

const tex_vert_webgl2 = @embedFile("shaders/tex_vert_webgl2.glsl");
const tex_frag_webgl2 = @embedFile("shaders/tex_frag_webgl2.glsl");

const gradient_vert = @embedFile("shaders/gradient_vert.glsl");
const gradient_frag = @embedFile("shaders/gradient_frag.glsl");

const gradient_vert_webgl2 = @embedFile("shaders/gradient_vert_webgl2.glsl");
const gradient_frag_webgl2 = @embedFile("shaders/gradient_frag_webgl2.glsl");

const plane_vert = @embedFile("shaders/plane_vert.glsl");
const plane_frag = @embedFile("shaders/plane_frag.glsl");

const plane_vert_webgl2 = @embedFile("shaders/plane_vert_webgl2.glsl");
const plane_frag_webgl2 = @embedFile("shaders/plane_frag_webgl2.glsl");

pub const PlaneShader = struct {
    shader: Shader,
    u_const: gl.GLint,

    pub fn init(vert_buf_id: gl.GLuint) !PlaneShader {
        var shader: Shader = undefined;
        if (IsWasm) {
            shader = try Shader.init(plane_vert_webgl2, plane_frag_webgl2);
        } else {
            shader = try Shader.init(plane_vert, plane_frag);
        }

        gl.bindVertexArray(shader.vao_id);
        defer gl.bindVertexArray(0);

        gl.bindBuffer(gl.GL_ARRAY_BUFFER, vert_buf_id);
        bindAttributes(@sizeOf(TexShaderVertex), &.{
            // a_pos
            ShaderAttribute.init(0, @offsetOf(TexShaderVertex, "pos"), gl.GL_FLOAT, 4),
        });

        return PlaneShader{
            .shader = shader,
            .u_const = shader.getUniformLocation("u_const.mvp"),
        };
    }

    pub fn deinit(self: PlaneShader) void {
        self.shader.deinit();
    }

    pub fn bind(self: PlaneShader, mvp: Mat4) void {
        gl.useProgram(self.shader.prog_id);

        // set u_mvp, since transpose is false, it expects to receive in column major order.
        gl.uniformMatrix4fv(self.u_const, 1, gl.GL_FALSE, &mvp);
    }
};

pub const TexShader = struct {
    shader: Shader,
    u_mvp: gl.GLint,
    u_tex: gl.GLint,

    const Self = @This();

    pub fn init(vert_buf_id: gl.GLuint) Self {
        var shader: Shader = undefined;
        if (IsWasm) {
            shader = Shader.init(tex_vert_webgl2, tex_frag_webgl2) catch unreachable;
        } else {
            shader = Shader.init(tex_vert, tex_frag) catch unreachable;
        }

        gl.bindVertexArray(shader.vao_id);
        defer gl.bindVertexArray(0);

        gl.bindBuffer(gl.GL_ARRAY_BUFFER, vert_buf_id);
        bindAttributes(@sizeOf(TexShaderVertex), &.{
            // a_pos
            ShaderAttribute.init(0, @offsetOf(TexShaderVertex, "pos"), gl.GL_FLOAT, 4),
            // a_uv
            ShaderAttribute.init(1, @offsetOf(TexShaderVertex, "uv"), gl.GL_FLOAT, 2),
            // a_color
            ShaderAttribute.init(2, @offsetOf(TexShaderVertex, "color"), gl.GL_FLOAT, 4),
        });

        return .{
            .shader = shader,
            .u_mvp = shader.getUniformLocation("u_mvp"),
            .u_tex = shader.getUniformLocation("u_tex"),
        };
    }

    pub fn deinit(self: Self) void {
        self.shader.deinit();
    }

    pub fn bind(self: Self, mvp: Mat4, tex_id: gl.GLuint) void {
        gl.useProgram(self.shader.prog_id);

        // set u_mvp, since transpose is false, it expects to receive in column major order.
        gl.uniformMatrix4fv(self.u_mvp, 1, gl.GL_FALSE, &mvp);

        gl.activeTexture(gl.GL_TEXTURE0);
        gl.bindTexture(gl.GL_TEXTURE_2D, tex_id);

        // set tex to active texture.
        gl.uniform1i(self.u_tex, 0);
    }
};

pub const GradientShader = struct {
    shader: Shader,
    u_mvp: gl.GLint,
    u_start_pos: gl.GLint,
    u_start_color: gl.GLint,
    u_end_pos: gl.GLint,
    u_end_color: gl.GLint,

    pub fn init(vert_buf_id: gl.GLuint) GradientShader {
        var shader: Shader = undefined;
        if (IsWasm) {
            shader = Shader.init(gradient_vert_webgl2, gradient_frag_webgl2) catch unreachable;
        } else {
            shader = Shader.init(gradient_vert, gradient_frag) catch unreachable;
        }

        gl.bindVertexArray(shader.vao_id);
        gl.bindBuffer(gl.GL_ARRAY_BUFFER, vert_buf_id);
        bindAttributes(@sizeOf(TexShaderVertex), &.{
            // a_pos
            ShaderAttribute.init(0, 0, gl.GL_FLOAT, 4),
        });
        gl.bindVertexArray(0);

        return .{
            .shader = shader,
            .u_mvp = shader.getUniformLocation("u_mvp"),
            .u_start_pos = shader.getUniformLocation("u_start_pos"),
            .u_start_color = shader.getUniformLocation("u_start_color"),
            .u_end_pos = shader.getUniformLocation("u_end_pos"),
            .u_end_color = shader.getUniformLocation("u_end_color"),
        };
    }

    pub fn deinit(self: GradientShader) void {
        self.shader.deinit();
    }

    pub fn bind(self: GradientShader, mvp: Mat4, start_pos: Vec2, start_color: Color, end_pos: Vec2, end_color: Color) void {
        gl.useProgram(self.shader.prog_id);

        // set u_mvp, since transpose is false, it expects to receive in column major order.
        gl.uniformMatrix4fv(self.u_mvp, 1, gl.GL_FALSE, &mvp);

        gl.uniform2fv(self.u_start_pos, 1, @ptrCast([*]const f32, &start_pos));
        gl.uniform2fv(self.u_end_pos, 1, @ptrCast([*]const f32, &end_pos));

        const start_color_arr = start_color.toFloatArray();
        gl.uniform4fv(self.u_start_color, 1, &start_color_arr);

        const end_color_arr = end_color.toFloatArray();
        gl.uniform4fv(self.u_end_color, 1, &end_color_arr);
    }
};

fn u32ToVoidPtr(val: u32) ?*const gl.GLvoid {
    return @intToPtr(?*const gl.GLvoid, val);
}

// Define how to get attribute data out of vertex buffer. Eg. an attribute a_pos could be a vec4 meaning 4 components.
// size - num of components for the attribute.
// type - component data type.
// normalized - normally false, only relevant for non GL_FLOAT types anyway.
// stride - number of bytes for each vertex. 0 indicates that the stride is size * sizeof(type)
// offset - offset in bytes of the first component of first vertex.
fn vertexAttribPointer(attr_idx: gl.GLuint, size: gl.GLint, data_type: gl.GLenum, stride: gl.GLsizei, offset: ?*const gl.GLvoid) void {
    gl.vertexAttribPointer(attr_idx, size, data_type, gl.GL_FALSE, stride, offset);
}

const ShaderAttribute = struct {
    pos: u32,
    offset: u32,
    num_components: gl.GLint,
    data_type: gl.GLenum,

    fn init(pos: u32, offset: u32, data_type: gl.GLenum, num_components: gl.GLint) ShaderAttribute {
        return .{
            .pos = pos,
            .offset = offset,
            .data_type = data_type,
            .num_components = num_components,
        };
    }
};

fn bindAttributes(stride: u32, attrs: []const ShaderAttribute) void {
    for (attrs) |attr| {
        gl.enableVertexAttribArray(attr.pos);
        vertexAttribPointer(attr.pos, attr.num_components, attr.data_type, @intCast(c_int, stride), u32ToVoidPtr(attr.offset));
    }
}