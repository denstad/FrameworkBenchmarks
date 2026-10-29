// Access compiler flags via the per-user compiler_env module
const CompilerEnv = @import("compiler_env").CompilerEnv;

pub const panic = if (@import("builtin").mode == .Debug)
    @import("std").debug.FullPanic(@import("std").debug.defaultPanic)
else
    @import("std").debug.simple_panic;


const __koru_bare = struct {
    extern fn posix_memalign(memptr: *?*anyopaque, alignment: usize, size: usize) c_int;
    extern fn free(ptr: ?*anyopaque) void;
    fn bareAlloc(_: *anyopaque, len: usize, alignment: @import("std").mem.Alignment, _: usize) ?[*]u8 {
        var p: ?*anyopaque = null;
        const a = @max(alignment.toByteUnits(), @sizeOf(usize));
        if (posix_memalign(&p, a, len) != 0) return null;
        return @ptrCast(p);
    }
    fn bareResize(_: *anyopaque, _: []u8, _: @import("std").mem.Alignment, _: usize, _: usize) bool { return false; }
    fn bareRemap(_: *anyopaque, _: []u8, _: @import("std").mem.Alignment, _: usize, _: usize) ?[*]u8 { return null; }
    fn bareFree(_: *anyopaque, memory: []u8, _: @import("std").mem.Alignment, _: usize) void { free(@ptrCast(memory.ptr)); }
    const vtable = @import("std").mem.Allocator.VTable{ .alloc = bareAlloc, .resize = bareResize, .remap = bareRemap, .free = bareFree };
    const allocator = @import("std").mem.Allocator{ .ptr = undefined, .vtable = &vtable };
};
const __koru_backing = if (@import("builtin").link_libc) @import("std").heap.c_allocator else if (@import("builtin").os.tag == .freestanding and !@import("builtin").cpu.arch.isWasm()) __koru_bare.allocator else @import("std").heap.page_allocator;
var __koru_leak_count: @import("std").atomic.Value(usize) = .init(0);
fn __koru_alloc(ctx: *anyopaque, len: usize, alignment: @import("std").mem.Alignment, ret_addr: usize) ?[*]u8 {
    _ = ctx;
    const r = __koru_backing.rawAlloc(len, alignment, ret_addr);
    if (comptime @import("builtin").mode == .Debug) {
        if (r != null) _ = __koru_leak_count.fetchAdd(1, .monotonic);
    }
    return r;
}
fn __koru_resize(ctx: *anyopaque, memory: []u8, alignment: @import("std").mem.Alignment, new_len: usize, ret_addr: usize) bool {
    _ = ctx;
    return __koru_backing.rawResize(memory, alignment, new_len, ret_addr);
}
fn __koru_remap(ctx: *anyopaque, memory: []u8, alignment: @import("std").mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    _ = ctx;
    return __koru_backing.rawRemap(memory, alignment, new_len, ret_addr);
}
fn __koru_free(ctx: *anyopaque, memory: []u8, alignment: @import("std").mem.Alignment, ret_addr: usize) void {
    _ = ctx;
    __koru_backing.rawFree(memory, alignment, ret_addr);
    if (comptime @import("builtin").mode == .Debug) {
        _ = __koru_leak_count.fetchSub(1, .monotonic);
    }
}
const __koru_vtable = @import("std").mem.Allocator.VTable{ .alloc = __koru_alloc, .resize = __koru_resize, .remap = __koru_remap, .free = __koru_free };
pub fn koru_allocator() @import("std").mem.Allocator {
    return .{ .ptr = undefined, .vtable = &__koru_vtable };
}

pub inline fn __koru_intcast(comptime T: type, x: anytype) T {
    if (comptime (@import("builtin").mode == .Debug or @import("builtin").mode == .ReleaseSafe))
        return @as(T, @intCast(x));
    const dst = @typeInfo(T);
    const src = @typeInfo(@TypeOf(x));
    if (comptime (dst == .int and src == .int and dst.int.bits == src.int.bits and dst.int.signedness != src.int.signedness))
        return @as(T, @bitCast(x));
    return @as(T, @intCast(x));
}

pub fn koru_leak_check() void {
    if (comptime @import("builtin").mode != .Debug) return;
    if (__koru_leak_count.load(.acquire) == 0) return;
    if (comptime @import("builtin").target.os.tag == .freestanding) {
        if (comptime @import("builtin").cpu.arch == .wasm32 or @import("builtin").cpu.arch == .wasm64) {
            @panic("KORU LEAK CHECK FAILED: the produced program leaked");
        } else {
            const __klc = struct { extern var stdout: ?*anyopaque; extern fn fputs(__s: [*:0]const u8, __st: ?*anyopaque) c_int; };
            var __lb: [128]u8 = undefined;
            const __lm = "KORU LEAK CHECK FAILED: allocations still outstanding at end of run: ";
            @memcpy(__lb[0..__lm.len], __lm);
            var __ln: usize = __lm.len;
            var __lv = __koru_leak_count.load(.acquire);
            var __ld: [20]u8 = undefined;
            var __lk: usize = 0;
            while (__lv > 0) : (__lk += 1) { __ld[__lk] = @intCast('0' + __lv % 10); __lv /= 10; }
            for (0..__lk) |__li| { __lb[__ln] = __ld[__lk - 1 - __li]; __ln += 1; }
            __lb[__ln] = '\n'; __ln += 1; __lb[__ln] = 0;
            _ = __klc.fputs(@as([*:0]const u8, @ptrCast(&__lb)), __klc.stdout);
            @trap();
        }
    } else {
        @import("std").debug.print("KORU LEAK CHECK FAILED: the produced program leaked (trace above)\n", .{});
        @import("std").process.exit(1);
    }
}

pub const main_module = struct {
    pub fn koru_start_flow() void {
        const result_0 = koru_koru.start_event.handler(.{  });
        const result_0_done = result_0.done;
        _ = &result_0_done;
    }
    pub fn koru_end_flow() void {
        const result_0 = koru_koru.end_event.handler(.{  });
        const result_0_done = result_0.done;
        _ = &result_0_done;
    }
};

pub const koru_koru = struct {
    pub const start_event = struct {
        pub const Input = struct {
        };
        pub const Output = union(enum(u8)) {
            done: struct {
            },
        };
        pub fn handler(__koru_event_input: @This().Input) @This().Output {
            _ = &__koru_event_input;
            return .{ .done = .{} };
        }
    };
    pub const end_event = struct {
        pub const Input = struct {
        };
        pub const Output = union(enum(u8)) {
            done: struct {
            },
        };
        pub fn handler(__koru_event_input: @This().Input) @This().Output {
            _ = &__koru_event_input;
            return .{ .done = .{} };
        }
    };
};
pub fn main() void {
    main_module.koru_start_flow();
    main_module.koru_end_flow();
    if (comptime @import("builtin").mode == .Debug) koru_leak_check();
}

test {
    @import("std").testing.refAllDeclsRecursive(@This());
}
