# Cosmic Graphics

Standalone 2D graphics library for GUI and games in Zig. Uses SDL for window/graphics context creation. See the [Web Demo](https://fubark.github.io/cosmic-site/demo).

- [x] Create window with OpenGL(3.3) context. WebGL2 for wasm build.
- [x] Canvas API / Vector graphics
  - [x] Fill/stroke shapes.
  - [x] Complex polygons.
  - [x] Curves.
  - [x] SVG path rendering, SVG file support (subset of spec)
  - [ ] [TinyVG](https://github.com/TinyVG) file support.
  - [ ] Line join styles.
- [x] Text rendering.
  - [x] Supports TTF/OTF fonts.
  - [x] Dynamic text sizes.
  - [x] Color emojis.
  - [x] Fallback font support. (for missing UTF-8 codepoints)
  - [x] Bitmap fonts.
  - [x] Freetype2 (default) and stb_truetype backends. 
  - [ ] MacOS CoreText backend.
  - [ ] Windows DirectWrite backend.
- [x] Load/draw images. (JPG, PNG, BMP)
- [x] Draw to offscreen images with the same Canvas API.
- [x] Transforms.
- [x] Blending.
- [x] Gradients.
- [ ] Draw 3D meshes. (Basic support.)
- [ ] Load 3D models from gltf. (Basic support.)
- [ ] Custom Shaders.
- [x] Cross platform.
- [ ] Cross compilation. (Might work already, needs verification.)
- [ ] C bindings.

| Status | Platform | Backend | Size (demo.zig)* |
| --- | --- | --- | --- |
| ✅ | Linux x64 [(Screenshot)](https://raw.githubusercontent.com/fubark/cosmic-site/master/graphics-demo-linux.png) | OpenGL, Vulkan** | demo - 2.2 M |
| ✅ | Web [(Demo)](https://fubark.github.io/cosmic-site/demo) | Wasm/WebGL2 | demo.wasm - 461 KB |
| ✅ | Windows x64 [(Screenshot)](https://raw.githubusercontent.com/fubark/cosmic-site/master/graphics-demo-win11.png) | OpenGL | demo.exe - 2.7 M |
| ✅ | macOS x64 [(Screenshot)](https://raw.githubusercontent.com/fubark/cosmic-site/master/graphics-demo-macos.png) | OpenGL, Vulkan** | demo - 3.1 M |
| ✅ | macOS arm64 [(Screenshot)](https://raw.githubusercontent.com/fubark/cosmic-site/master/graphics-demo-macos.png) | OpenGL, Vulkan** | demo - 2.8 M |
| Planned | Windows Vulkan backend |
| Undecided | Android/iOS |
| Future | WebGPU backend for Win/Mac/Linux/Web |

\* Static binary size not including the demo assets. Compiled with -Drelease-safe.

\** Vulkan backend does not currently support dynamic blending or drawing to offscreen images. Note for macOS, you need to install MoltenVK. In a future release, the static lib will automatically be included. If you'd like to use OpenGL instead, enable it in cosmic/platform/backend.zig.

## Screenshot
<a href="https://raw.githubusercontent.com/fubark/cosmic-site/master/graphics-demo-linux.png"><img src="https://raw.githubusercontent.com/fubark/cosmic-site/master/graphics-demo-linux.png" alt="Linux Demo" height="300"></a>

## Dependencies
Get the latest Zig compiler (0.10.0-dev) [here](https://ziglang.org/download/).

Clone the cosmic repo which includes:
- cosmic/graphics: This module.
- cosmic/platform: Used to facilitate events from the window.
- cosmic/stdx: Used for additional utilities.
- cosmic/lib/sdl: SDL2 source. Used to create a window and OpenGL 3.3 context. Built automatically.
- cosmic/lib/freetype2: Freetype2 font renderer backend used by default for desktop. Built automatically.
- cosmic/lib/stb: Contains stb_truetype, an optional font renderer backend. Also contains stb_image for decoding images. Built automatically.
- cosmic/lib/wasm: Wasm/js bootstrap and glue code.
```sh
git clone https://github.com/fubark/cosmic.git
cd cosmic
```

## Run demo (Desktop)
```sh
# If you are using the latest zig stage3 compiler, append "-fstage1" to the command.
zig build run -Dpath="graphics/examples/demo.zig" -Dgraphics -Drelease-safe
```

## Run demo (Web/Wasm)

```sh
zig build wasm -Dpath="graphics/examples/demo.zig" -Dgraphics -Drelease-safe
cd zig-out/wasm32-freestanding-musl/demo
python3 -m http.server
# Or "cosmic http ." if you have cosmic installed.
# Then fire up your browser to see the demo.
```

## Using as a Zig library.
The lib.zig in this graphics module provides simple helpers for you add the package, build, and link this library in your own build.zig file. Here is how you would do that:
```zig
// build.zig
// cosmic repo should be a subdirectory.
const std = @import("std");
const graphics = @import("cosmic/graphics/lib.zig");
const backend = @import("cosmic/platform/backend.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    // main.zig would be your app code. You could copy over examples/demo.zig as a template.
    const exe = b.addExecutable("myapp", "main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    const graphics_backend = backend.getGraphicsBackend(exe);
    graphics.addPackage(exe, .{.graphics_backend = graphics_backend});
    graphics.buildAndLink(exe, .{.graphics_backend = graphics_backend});

    exe.setOutputDir("zig-out");

    const run = exe.run();
    b.default_step.dependOn(&run.step);
}
```
Then run `zig build` in your own project directory and it will build and run your app.

## Using as a C Library.
* TODO: Provide c headers.

## Lyon bindings
There is an optional integration with lyon (a Rust path tessellation lib) to provide a good comparison with Cosmic for development. `zig build get-extras` will get prebuilt lyon bindings. If that doesn't work you'll need rust and cargo to do:
```sh
zig build lyon
```

## License
Cosmic Graphics is free and open source under the MIT License.
