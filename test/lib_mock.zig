const std = @import("std");
const stdx = @import("stdx");
const uv = @import("uv");
const gl = @import("gl");
const ma = @import("miniaudio");
const GLint = gl.GLint;
const GLsizei = gl.GLsizei;
const GLclampf = gl.GLclampf;
const GLenum = gl.GLenum;

const log = stdx.log.scoped(.lib_mock);

extern fn unitTraceC(fn_name_ptr: *const u8, fn_name_len: usize) void;

/// Since lib_mock is compiled as a static lib, it would use a different reference to the global mocks var
/// if we called unitTrace directly. Instead, call into an exported c function.
fn unitTrace(loc: std.builtin.SourceLocation) void {
    unitTraceC(&loc.fn_name[0], loc.fn_name.len);
}

// Mocked out external deps.

export fn glViewport(x: GLint, y: GLint, width: GLsizei, height: GLsizei) void {
    _ = x;
    _ = y;
    _ = width;
    _ = height;
}

export fn glClearColor(red: GLclampf, green: GLclampf, blue: GLclampf, alpha: GLclampf) void {
    _ = red;
    _ = green;
    _ = blue;
    _ = alpha;
}

export fn glDisable(cap: GLenum) void {
    _ = cap;
}

export fn glEnable(cap: GLenum) void {
    _ = cap;
}

export fn glGetIntegerv(pname: GLenum, params: [*c]GLint) void {
    _ = pname;
    _ = params;
}

export fn glBlendFunc(sfactor: GLenum, dfactor: GLenum) void {
    _ = sfactor;
    _ = dfactor;
}

export fn lyon_init() void {}

export fn lyon_deinit() void {}

export fn glDeleteBuffers() void {}
export fn glDeleteVertexArrays() void {}
export fn glDeleteTextures() void {}
export fn glUniformMatrix4fv() void {}
export fn glGetUniformLocation() void {}
export fn glUniform1i() void {}
export fn glBufferData() void {}
export fn glDrawElements() void {}
export fn glTexSubImage2D() void {}
export fn glScissor() void {}
export fn glBlendEquation() void {}

export fn SDL_GL_DeleteContext() void {}
export fn SDL_DestroyWindow() void {}
export fn SDL_CaptureMouse() void {}

export fn v8__Persistent__Reset() void {}
export fn v8__Boolean__New() void {}

export fn stbtt_GetGlyphBitmapBox() void {}
export fn stbtt_MakeGlyphBitmap() void {}

export fn v8__HandleScope__CONSTRUCT() void {}
export fn v8__TryCatch__CONSTRUCT() void {}
export fn v8__Value__IsAsyncFunction() void {}
export fn v8__Function__Call() void {}
export fn v8__Function__New__DEFAULT2() void {}
export fn v8__ObjectTemplate__SetInternalFieldCount() void {}
export fn v8__ObjectTemplate__NewInstance() void {}
export fn v8__Object__SetInternalField() void {}
export fn v8__Promise__Then2() void {}
export fn v8__TryCatch__DESTRUCT() void {}
export fn v8__HandleScope__DESTRUCT() void {}
export fn v8__Object__GetInternalField() void {}
export fn v8__External__Value() void {}
export fn v8__Value__Uint32Value() void {}
export fn v8__Persistent__New() void {}
export fn v8__Value__NumberValue() void {}
export fn v8__Persistent__SetWeakFinalizer() void {}
export fn v8__WeakCallbackInfo__GetParameter() void {}
export fn curl_slist_free_all() void {}
export fn v8__Promise__Resolver__New() void {}
export fn v8__Promise__Resolver__GetPromise() void {}
export fn uv_timer_init(loop: *uv.uv_loop_t, timer: *uv.uv_timer_t) c_int {
    _ = loop;
    _ = timer;
    return 0;
}
export fn uv_async_send(async_: *uv.uv_async_t) c_int {
    _ = async_;
    return 0;
}
export fn TLS_server_method() void {}
export fn SSL_CTX_new() void {}
export fn OPENSSL_init_ssl() void {}
export fn OPENSSL_init_crypto() void {}
export fn SSL_CTX_set_options() void {}
export fn SSL_CTX_use_PrivateKey_file() void {}
export fn SSL_CTX_set_cipher_list() void {}
export fn SSL_CTX_set_ciphersuites() void {}
export fn SSL_CTX_use_certificate_chain_file() void {}
export fn h2o_get_alpn_protocols() void {}
export fn h2o_ssl_register_alpn_protocols() void {}
export fn v8__FunctionTemplate__GetFunction() void {}
export fn v8__Function__NewInstance() void {}
export fn uv_timer_start(handle: *uv.uv_timer_t, cb: uv.uv_timer_cb, timeout: u64, repeat: u64) c_int {
    _ = handle;
    _ = cb;
    _ = timeout;
    _ = repeat;
    return 0;
}
export fn h2o_strdup() void {}
export fn h2o_set_header_by_str() void {}
export fn h2o_start_response() void {}
export fn h2o_send() void {}
export fn v8__FunctionCallbackInfo__Length() void {}
export fn v8__FunctionCallbackInfo__INDEX() void {}
export fn v8__ArrayBufferView__Buffer() void {}
export fn v8__ArrayBuffer__GetBackingStore() void {}
export fn std__shared_ptr__v8__BackingStore__get() void {}
export fn v8__BackingStore__ByteLength() void {}
export fn v8__BackingStore__Data() void {}
export fn std__shared_ptr__v8__BackingStore__reset() void {}
export fn v8__Value__IsObject() void {}
export fn v8__Object__Get() void {}
export fn v8__Object__Set() void {}
export fn v8__External__New() void {}
export fn v8__ObjectTemplate__New__DEFAULT() void {}
export fn v8__String__NewFromUtf8() void {}
export fn v8__TryCatch__HasCaught() void {}
export fn v8__TryCatch__Message() void {}
export fn v8__Message__GetSourceLine() void {}
export fn v8__Message__GetStartColumn() void {}
export fn v8__Message__GetEndColumn() void {}
export fn v8__TryCatch__StackTrace() void {}
export fn v8__TryCatch__Exception() void {}
export fn v8__Value__ToString() void {}
export fn v8__String__Utf8Length() void {}
export fn v8__String__WriteUtf8() void {}
export fn SDL_InitSubSystem() void {}
export fn SDL_GetError() void {}
export fn SDL_GetWindowID() void {}
export fn stbi_load_from_memory() void {}
export fn stbi_failure_reason() void {}
export fn stbi_image_free() void {}
export fn glGenTextures() void {}
export fn glBindTexture() void {}
export fn glTexParameteri() void {}
export fn glTexImage2D() void {}
export fn curl_slist_append() void {}
export fn curl_easy_setopt() void {}
export fn curl_easy_perform() void {}
export fn curl_easy_getinfo() void {}
export fn curl_easy_init() void {}
export fn curl_multi_add_handle() void {}
export fn uv_tcp_init() void {}
export fn uv_strerror() void {}
export fn uv_ip4_addr() void {}
export fn uv_tcp_bind() void {}
export fn uv_listen() void {}
export fn uv_pipe_init() void {}
export fn uv_read_start() void {}
export fn uv_spawn() void {}
export fn h2o_config_register_host() void {}
export fn h2o_context_init() void {}
export fn h2o_context_request_shutdown() void {}
export fn uv_close() void {}
export fn uv_accept() void {}
export fn h2o_uv_socket_create() void {}
export fn h2o_accept() void {}
export fn uv_handle_get_type() void {}
export fn h2o_config_register_path() void {}
export fn h2o_create_handler() void {}
export fn v8__Integer__NewFromUnsigned() void {}
export fn v8__FunctionCallbackInfo__Data() void {}
export fn v8__Object__New() void {}
export fn v8__Exception__Error() void {}
export fn v8__Isolate__ThrowException() void {}
export fn SDL_GL_CreateContext() void {}
export fn glGetString() void {}
export fn SDL_GL_MakeCurrent() void {}
export fn SDL_GL_SetAttribute() void {}
export fn SDL_CreateWindow() void {}
export fn glActiveTexture() void {}
export fn stbtt_GetGlyphKernAdvance() void {}
export fn lyon_new_builder() void {}
export fn lyon_begin() void {}
export fn lyon_cubic_bezier_to() void {}
export fn lyon_end() void {}
export fn lyon_build_stroke() void {}
export fn lyon_quadratic_bezier_to() void {}
export fn lyon_add_polygon() void {}
export fn lyon_build_fill() void {}
export fn v8__Number__New() void {}
export fn v8__Promise__Resolver__Resolve() void {}
export fn v8__Promise__Resolver__Reject() void {}
export fn v8__Value__BooleanValue() void {}
export fn glBindVertexArray() void {}
export fn glBindBuffer() void {}
export fn glEnableVertexAttribArray() void {}
export fn glCreateShader() void {}
export fn glShaderSource() void {}
export fn glCompileShader() void {}
export fn glGetShaderiv() void {}
export fn glGetShaderInfoLog() void {}
export fn glDeleteShader() void {}
export fn glCreateProgram() void {}
export fn glAttachShader() void {}
export fn glLinkProgram() void {}
export fn glGetProgramiv() void {}
export fn glGetProgramInfoLog() void {}
export fn glDeleteProgram() void {}
export fn glDetachShader() void {}
export fn glGenVertexArrays() void {}
export fn glGenFramebuffers() void {}
export fn glBindFramebuffer() void {}
export fn glTexImage2DMultisample() void {}
export fn glFramebufferTexture2D() void {}
export fn glGenBuffers() void {}
export fn glVertexAttribPointer() void {}
export fn stbtt_InitFont() void {}
export fn lyon_line_to() void {}
export fn v8__Array__New2() void {}
export fn v8__ArrayBuffer__NewBackingStore() void {}
export fn v8__BackingStore__TO_SHARED_PTR() void {}
export fn v8__ArrayBuffer__New2() void {}
export fn v8__Uint8Array__New() void {}
export fn glUseProgram() void {}
export fn h2o_config_init() void {}
export fn v8__Message__GetStackTrace() void {}
export fn v8__StackTrace__GetFrameCount() void {}
export fn v8__StackTrace__GetFrame() void {}
export fn v8__StackFrame__GetFunctionName() void {}
export fn v8__StackFrame__GetScriptNameOrSourceURL() void {}
export fn v8__StackFrame__GetLineNumber() void {}
export fn v8__StackFrame__GetColumn() void {}
export fn v8__Isolate__CreateParams__SIZEOF() void {}
export fn v8__TryCatch__SIZEOF() void {}
export fn v8__PromiseRejectMessage__SIZEOF() void {}
export fn v8__Platform__NewDefaultPlatform() void {}
export fn v8__V8__InitializePlatform() void {}
export fn v8__V8__Initialize() void {}
export fn v8__Isolate__CreateParams__CONSTRUCT() void {}
export fn v8__ArrayBuffer__Allocator__NewDefaultAllocator() void {}
export fn v8__Isolate__New() void {}
export fn v8__Isolate__Enter() void {}
export fn v8__Context__Enter() void {}
export fn v8__Platform__PumpMessageLoop() void {}
export fn v8__Context__Exit() void {}
export fn v8__Isolate__Exit() void {}
export fn v8__Isolate__Dispose() void {}
export fn v8__ArrayBuffer__Allocator__DELETE() void {}
export fn v8__V8__Dispose() void {}
export fn v8__V8__ShutdownPlatform() void {}
export fn v8__Message__GetScriptResourceName() void {}
export fn v8__V8__DisposePlatform() void {}
export fn v8__Platform__DELETE() void {}
export fn v8__V8__GetVersion() void {}
export fn h2o__tokens() void {}
export fn h2o_globalconf_size() void {}
export fn h2o_hostconf_size() void {}
export fn h2o_httpclient_ctx_size() void {}
export fn h2o_context_size() void {}
export fn h2o_accept_ctx_size() void {}
export fn h2o_socket_size() void {}
export fn uv_loop_init(loop: *uv.uv_loop_t) c_int {
    _ = loop;
    return 0;
}
export fn uv_async_init() void {}
export fn uv_run() void {}
export fn curl_global_cleanup() void {}
export fn SDL_PollEvent() void {}
export fn curl_global_init() void {}
export fn curl_share_init() void {}
export fn curl_share_setopt() void {}
export fn curl_multi_init() void {}
export fn curl_multi_setopt() void {}
export fn uv_poll_start() void {}
export fn uv_poll_stop() void {}
export fn uv_timer_stop() void {}
export fn uv_backend_fd() void {}
export fn v8__Isolate__SetPromiseRejectCallback() void {}
export fn v8__Isolate__SetMicrotasksPolicy() void {}
export fn v8__Isolate__SetCaptureStackTraceForUncaughtExceptions() void {}
export fn v8__Isolate__AddMessageListenerWithErrorLevel() void {}
export fn v8__FunctionTemplate__New__DEFAULT() void {}
export fn v8__FunctionTemplate__InstanceTemplate() void {}
export fn v8__FunctionTemplate__PrototypeTemplate() void {}
export fn v8__FunctionTemplate__SetClassName() void {}
export fn v8__ObjectTemplate__New() void {}
export fn v8__ScriptOrigin__CONSTRUCT() void {}
export fn v8__Isolate__GetCurrentContext() void {}
export fn v8__Script__Compile() void {}
export fn v8__Script__Run() void {}
export fn curl_easy_cleanup() void {}
export fn curl_multi_cleanup() void {}
export fn curl_share_cleanup() void {}
export fn v8__TryCatch__SetVerbose() void {}
export fn SDL_Delay() void {}
export fn v8__Promise__State() void {}
export fn v8__Isolate__PerformMicrotaskCheckpoint() void {}
export fn v8__Context__New() void {}
export fn uv_poll_init_socket() void {}
export fn curl_multi_assign() void {}
export fn v8__Undefined() void {}
export fn v8__Null() void {}
export fn v8__False() void {}
export fn v8__True() void {}
export fn uv_backend_timeout() void {}
export fn v8__PromiseRejectMessage__GetPromise() void {}
export fn v8__Object__GetIsolate() void {}
export fn v8__Object__GetCreationContext() void {}
export fn v8__PromiseRejectMessage__GetEvent() void {}
export fn v8__PromiseRejectMessage__GetValue() void {}
export fn v8__Object__GetIdentityHash() void {}
export fn v8__FunctionTemplate__New__DEFAULT3() void {}
export fn v8__Template__Set() void {}
export fn v8__Template__SetAccessorProperty__DEFAULT() void {}
export fn curl_multi_socket_action() void {}
export fn curl_multi_strerror() void {}
export fn curl_multi_info_read() void {}
export fn v8__FunctionCallbackInfo__GetReturnValue() void {}
export fn v8__ReturnValue__Set() void {}
export fn curl_multi_remove_handle() void {}
export fn v8__FunctionCallbackInfo__This() void {}
export fn v8__Integer__Value() void {}
export fn v8__Value__IsFunction() void {}
export fn v8__Value__IsArray() void {}
export fn v8__Array__Length() void {}
export fn v8__Object__GetIndex() void {}
export fn v8__Value__InstanceOf() void {}
export fn v8__Value__IsUint8Array() void {}
export fn v8__Object__GetOwnPropertyNames() void {}
export fn v8__Integer__New() void {}
export fn SDL_MinimizeWindow() void {}
export fn SDL_MaximizeWindow() void {}
export fn SDL_RestoreWindow() void {}
export fn SDL_SetWindowFullscreen() void {}
export fn SDL_SetWindowPosition() void {}
export fn SDL_RaiseWindow() void {}
export fn v8__Value__Int32Value() void {}
export fn curl_easy_strerror() void {}
export fn uv_walk() void {}
export fn uv_stop() void {}
export fn uv_loop_size() void {}
export fn uv_loop_close() void {}
export fn uv_fs_event_init() void {}
export fn uv_fs_event_start() void {}
export fn v8__Message__Get() void {}
export fn v8__Isolate__TerminateExecution() void {}
export fn v8__Isolate__IsExecutionTerminating() void {}
export fn v8__StackTrace__CurrentStackTrace__STATIC() void {}
export fn h2o_timer_unlink() void {}
export fn h2o_config_dispose() void {}
export fn v8__Context__Global() void {}
export fn h2o_context_dispose() void {}
export fn uv_is_closing() void {}
export fn SDL_GL_GetDrawableSize() void {}
export fn SDL_SetWindowSize() void {}
export fn SDL_GetWindowSize() void {}
export fn SDL_SetWindowTitle() void {}
export fn SDL_GetWindowTitle() void {}
export fn v8__ScriptCompiler__Source__CONSTRUCT() void {}
export fn v8__ScriptCompiler__Source__CONSTRUCT2() void {}
export fn v8__ScriptCompiler__Source__DESTRUCT() void {}
export fn v8__ScriptCompiler__Source__SIZEOF() void {}
export fn v8__Context__GetIsolate() void {}
export fn v8__ScriptOrigin__CONSTRUCT2() void {}
export fn v8__Context__GetEmbedderData() void {}
export fn v8__Context__SetEmbedderData() void {}
export fn v8__Module__Evaluate() void {}
export fn v8__Module__GetException() void {}
export fn v8__ScriptCompiler__CompileModule() void {}
export fn v8__Module__GetStatus() void {}
export fn v8__Module__InstantiateModule() void {}
export fn v8__Module__ScriptId() void {}
export fn v8__Exception__GetStackTrace() void {}
export fn v8__TryCatch__ReThrow() void {}
export fn v8__ScriptCompiler__CachedData__SIZEOF() void {}
export fn v8__Message__GetLineNumber() void {}
export fn v8__Object__SetAlignedPointerInInternalField() void {}
export fn ma_sound_uninit() void {}
export fn ma_sound_start() void {}
export fn v8__WeakCallbackInfo__GetInternalField() void {}
export fn ma_sound_is_playing() void {}
export fn ma_sound_init_from_data_source() void {}
export fn ma_sound_at_end() void {}
export fn ma_result_description() void {}
export fn ma_engine_init() ma.ma_result {
    unitTrace(@src());
    return 0;
}
export fn v8__Isolate__LowMemoryNotification() void {}
export fn ma_decoder_uninit() void {}
export fn ma_decoder_init_memory() void {}
export fn ma_decoder_config_init_default() void {}
export fn ma_sound_set_pan() void {}
export fn ma_sound_set_volume() void {}
export fn ma_sound_set_pitch() void {}
export fn ma_sound_get_volume() void {}
export fn ma_sound_get_pitch() void {}
export fn ma_sound_get_pan() void {}
export fn ma_volume_db_to_linear() void {}
export fn ma_volume_linear_to_db() void {}
export fn v8__HeapStatistics__SIZEOF() void {}
export fn ma_data_source_seek_to_pcm_frame() void {}
export fn ma_sound_stop() void {}
export fn ma_engine_listener_get_position() void {}
export fn ma_engine_listener_get_velocity() void {}
export fn ma_engine_listener_get_world_up() void {}
export fn ma_engine_listener_set_direction() void {}
export fn ma_engine_listener_set_position() void {}
export fn ma_engine_listener_set_velocity() void {}
export fn v8__Value__IsString() void {}
export fn ma_engine_listener_set_world_up() void {}
export fn v8__BigInt__Uint64Value() void {}
export fn ma_sound_set_velocity() void {}
export fn ma_engine_listener_get_direction() void {}
export fn ma_sound_set_position() void {}
export fn v8__BigInt__NewFromUnsigned() void {}
export fn ma_sound_set_looping() void {}
export fn ma_sound_set_direction() void {}
export fn ma_sound_is_looping() void {}
export fn ma_sound_get_velocity() void {}
export fn ma_sound_get_position() void {}
export fn ma_sound_get_length_in_pcm_frames() void {}
export fn ma_sound_get_direction() void {}
export fn ma_sound_get_data_format() void {}
export fn ma_sound_get_cursor_in_pcm_frames() void {}
export fn v8__Value__IsBigInt() void {}
export fn SDL_PushEvent() void {}
export fn v8__Function__GetName() void {}
export fn v8__Value__IsNullOrUndefined() void {}
export fn v8__base__SetDcheckFunction() void {}
export fn v8__JSON__Parse() void {}
export fn SDL_GL_GetProcAddress() void {}
export fn uv_tcp_getsockname() void {}
export fn SDL_free() void {}
export fn SDL_SetClipboardText() void {}
export fn SDL_GetClipboardText() void {}
export fn GetProcessTimes() void {}
export fn FT_Init_FreeType() c_int {
    return 0;
}
export fn FT_Error_String() void {}
export fn FT_Get_Kerning() void {}
export fn glUniform4fv() void {}
export fn glUniform2fv() void {}
export fn FT_Load_Glyph() void {}
export fn FT_New_Memory_Face() void {}
export fn FT_Render_Glyph() void {}
export fn FT_Set_Pixel_Sizes() void {}
export fn stbi_write_bmp() void {}

export fn SDL_Vulkan_GetVkGetInstanceProcAddr() void {}
export fn SDL_Vulkan_GetInstanceExtensions() void {}
export fn SDL_Vulkan_GetDrawableSize() void {}
export fn SDL_Vulkan_CreateSurface() void {}

export fn vkEnumeratePhysicalDevices() void {}
export fn vkGetPhysicalDeviceFeatures() void {}
export fn vkCreateInstance() void {}
export fn vkCreateDevice() void {}
export fn vkEnumerateInstanceLayerProperties() void {}
export fn vkGetPhysicalDeviceQueueFamilyProperties() void {}
export fn vkGetPhysicalDeviceSurfaceSupportKHR() void {}
export fn vkEnumerateDeviceExtensionProperties() void {}
export fn vkGetPhysicalDeviceSurfaceCapabilitiesKHR() void {}
export fn vkGetPhysicalDeviceSurfaceFormatsKHR() void {}
export fn vkGetPhysicalDeviceSurfacePresentModesKHR() void {}
export fn vkGetDeviceQueue() void {}
export fn vkAllocateDescriptorSets() void {}
export fn vkUpdateDescriptorSets() void {}
export fn vkGetSwapchainImagesKHR() void {}
export fn vkCreateSwapchainKHR() void {}
export fn vkCreateCommandPool() void {}
export fn vkAllocateCommandBuffers() void {}
export fn vkCreateRenderPass() void {}
export fn vkCreateSampler() void {}
export fn vkDestroyDevice() void {}
export fn vkDestroySurfaceKHR() void {}
export fn vkDestroyInstance() void {}
export fn vkMapMemory() void {}
export fn vkDestroyBuffer() void {}
export fn vkFreeMemory() void {}
export fn vkUnmapMemory() void {}
export fn vkCmdSetScissor() void {}
export fn vkCreateImageView() void {}
export fn vkCreateImage() void {}
export fn vkGetImageMemoryRequirements() void {}
export fn vkAllocateMemory() void {}
export fn vkBindImageMemory() void {}
export fn vkCreateSemaphore() void {}
export fn vkCreateFence() void {}
export fn vkCreateFramebuffer() void {}
export fn vkCreateDescriptorSetLayout() void {}
export fn vkCreateDescriptorPool() void {}
export fn vkCreateBuffer() void {}
export fn vkGetBufferMemoryRequirements() void {}
export fn vkBindBufferMemory() void {}
export fn vkCmdPipelineBarrier() void {}
export fn vkCmdCopyBufferToImage() void {}
export fn vkGetPhysicalDeviceMemoryProperties() void {}
export fn vkCreatePipelineLayout() void {}
export fn vkCreateGraphicsPipelines() void {}
export fn vkDestroyShaderModule() void {}
export fn vkCmdBindPipeline() void {}
export fn vkCmdBindDescriptorSets() void {}
export fn vkCmdPushConstants() void {}
export fn vkCmdDrawIndexed() void {}
export fn vkBeginCommandBuffer() void {}
export fn vkEndCommandBuffer() void {}
export fn vkQueueSubmit() void {}
export fn vkQueueWaitIdle() void {}
export fn vkFreeCommandBuffers() void {}
export fn vkCreateShaderModule() void {}
export fn stb_perlin_noise3() void {}
export fn cgltf_parse() void {}
export fn JPH__BPLayerInterfaceImpl__DELETE() void {}
export fn JPH__BPLayerInterfaceImpl__NEW() void {}
export fn JPH__BodyCreationSettings__CONSTRUCT2() void {}
export fn JPH__BodyCreationSettings__SIZEOF() void {}
export fn JPH__BodyInterface__AddBody() void {}
export fn JPH__BodyInterface__CreateBody() void {}
export fn JPH__BodyLockInterface__TryGetBody() void {}
export fn JPH__BodyLockRead__SIZEOF() void {}
export fn JPH__Body__GetID() void {}
export fn JPH__Body__GetPosition() void {}
export fn JPH__Body__GetRotation() void {}
export fn JPH__Body__GetUserData() void {}
export fn JPH__Body__SetUserData() void {}
export fn JPH__BoxShape__NEW() void {}
export fn JPH__InitDefaultFactory() void {}
export fn JPH__JobSystemThreadPool__DELETE() void {}
export fn JPH__JobSystemThreadPool__NEW() void {}
export fn JPH__PhysicsSystem__DELETE() void {}
export fn JPH__PhysicsSystem__GetActiveBodies() void {}
export fn JPH__PhysicsSystem__GetBodyInterface() void {}
export fn JPH__PhysicsSystem__GetBodyLockInterfaceNoLock() void {}
export fn JPH__PhysicsSystem__GetNumActiveBodies() void {}
export fn JPH__PhysicsSystem__Init() void {}
export fn JPH__PhysicsSystem__NEW() void {}
export fn JPH__PhysicsSystem__Update() void {}
export fn JPH__RegisterDefaultAllocator() void {}
export fn JPH__RegisterTypes() void {}
export fn JPH__SetAssertFailed() void {}
export fn JPH__TempAllocatorImpl__DELETE() void {}
export fn JPH__TempAllocatorImpl__NEW() void {}
export fn cgltf_num_components() void {}
export fn cgltf_load_buffer_base64() void {}
export fn cgltf_free() void {}
export fn cgltf_accessor_unpack_floats() void {}
export fn cgltf_accessor_read_uint() void {}
export fn cgltf_accessor_read_index() void {}
export fn cgltf_accessor_read_float() void {}
export fn glslang_finalize_process() void {}
export fn glslang_initialize_process() void {}

export fn glslang_default_resource() void {}
export fn glslang_shader_create() void {}
export fn glslang_shader_preprocess() void {}
export fn glslang_shader_get_info_log() void {}
export fn glslang_shader_get_info_debug_log() void {}
export fn glslang_shader_delete() void {}
export fn glslang_shader_parse() void {}
export fn glslang_program_create() void {}
export fn glslang_program_add_shader() void {}
export fn glslang_program_link() void {}
export fn glslang_program_delete() void {}
export fn glslang_program_SPIRV_generate() void {}
export fn glslang_program_SPIRV_get_size() void {}
export fn glslang_program_SPIRV_get() void {}
export fn glslang_program_SPIRV_get_messages() void {}

export fn JS_GetPropertyUint32() void {}
export fn JS_FreeCString() void {}
export fn JS_NewRuntime() void {}
export fn JS_NewContext() void {}
export fn JS_SetContextOpaque() void {}
export fn JS_Eval() void {}
export fn JS_FreeContext() void {}
export fn JS_FreeRuntime() void {}
export fn __JS_FreeValue() void {}
export fn JS_ToCStringLen2() void {}
export fn SDL_SetCursor() void {}
export fn SDL_FreeCursor() void {}
export fn SDL_CreateSystemCursor() void {}
export fn JS_GetException() void {}
export fn JS_IsFunction() void {}

export fn stbi_set_flip_vertically_on_load() void {}
export fn glFrontFace() void {}
export fn glCheckFramebufferStatus() void {}
