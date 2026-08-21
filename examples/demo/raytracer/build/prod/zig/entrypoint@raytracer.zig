const std = @import("std");
const P = @import("prelude.zig");
const module = @import("raytracer/raytracer.zig");
pub fn main(init: std.process.Init.Minimal) void {
    P.process_args = init.args;
    P.drop(module.@"main"());
    P.leakCheckExit();
}
