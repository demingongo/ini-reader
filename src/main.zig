//! Reads INI file and outputs a section
//! or the value of a key in a section.

const std = @import("std");
const mem = std.mem; // will be used to compare bytes
/// https://github.com/ziglibs/ini
const ini = @import("ini");

/// https://ziglearn.org/chapter-2/#allocators
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn read_ini_file(file_path: []const u8, section_name: []const u8, key_name: []const u8) !void {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const allocator = gpa.allocator();

    var parser = ini.parse(allocator, file.reader());
    defer parser.deinit();

    const section_to_find = section_name;
    const key_to_find = key_name;

    var section_found: bool = false;

    var writer = std.io.getStdOut().writer();

    while (try parser.next()) |record| {
        switch (record) {
            .section => |heading| {
                if (section_found and !mem.eql(u8, heading, section_to_find)) {
                    break;
                }
                if (mem.eql(u8, heading, section_to_find)) {
                    section_found = true;
                }
            },
            .property => |kv| {
                if (section_found) {
                    if (key_to_find.len > 0) {
                        if (mem.eql(u8, kv.key, key_to_find)) {
                            try writer.print("{s}\n", .{kv.value});
                            break;
                        }
                    } else {
                        try writer.print("{s} {s}\n", .{ kv.key, kv.value });
                    }
                }
            },
            .enumeration => |value| {
                if (section_found) {
                    if (key_to_find.len == 0) {
                        try writer.print("{s}\n", .{value});
                    }
                }
            },
        }
    }
}

pub fn main() !u8 {
    const allocator = gpa.allocator();

    var args = try std.process.argsAlloc(allocator);

    if (args.len < 2) {
        // missing argument 1
        try std.io.getStdErr().writer().print("Missing argument 1: path to the ini file\n", .{});
        return 1;
    }
    if (args.len < 3) {
        // missing argument 2
        try std.io.getStdErr().writer().print("Missing argument 2: section to read\n", .{});
        return 1;
    }

    var file_path: []u8 = undefined;
    var section_name: []u8 = undefined;
    var key_name: []u8 = "";

    // read args 1 to .. (do not define end so we do not run into "index out of bounds")
    // btw loop index (i) always starts at 0
    for (args[1..], 0..) |arg, i| {
        switch (i) {
            0 => {
                file_path = arg;
            },
            1 => {
                section_name = arg;
            },
            2 => {
                key_name = arg;
            },
            else => {
                // do not read further unnecessary args
                break;
            },
        }
    }

    // check if file exists and parse it

    const file_stat = std.fs.cwd().statFile(file_path);

    if (file_stat) |_| {
        try read_ini_file(file_path, section_name, key_name);
    } else |_| {
        try std.io.getStdErr().writer().print("Could not find file: {s}\n", .{file_path});
        return 2;
    }

    return 0;
}
