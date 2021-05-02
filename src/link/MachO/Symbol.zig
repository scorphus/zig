const Symbol = @This();

const std = @import("std");
const macho = std.macho;
const mem = std.mem;

const Allocator = mem.Allocator;
const Object = @import("Object.zig");

pub const Type = enum {
    regular,
    proxy,
    unresolved,
};

/// Symbol type.
@"type": Type,

/// Symbol name. Owned slice.
name: []u8,

pub const Regular = struct {
    base: Symbol,

    /// Linkage type.
    linkage: Linkage,

    /// Symbol address.
    address: u64,

    /// Section ID where the symbol resides.
    section: u8,

    /// Whether the symbol is a weak ref.
    weak_ref: bool,

    /// File where to locate this symbol.
    file: *Object,

    /// Debug stab if defined.
    stab: ?struct {
        /// Stab kind
        kind: enum {
            function,
            global,
            static,
        },

        /// Size of the stab.
        size: u64,
    } = null,

    pub const base_type: Symbol.Type = .regular;

    pub const Linkage = enum {
        translation_unit,
        linkage_unit,
        global,
    };
};

pub const Proxy = struct {
    base: Symbol,

    /// Dylib ordinal.
    dylib: u16,

    pub const base_type: Symbol.Type = .proxy;
};

pub const Unresolved = struct {
    base: Symbol,

    /// Alias of.
    alias: ?*Symbol = null,

    /// File where this symbol was referenced.
    file: *Object,

    pub const base_type: Symbol.Type = .unresolved;
};

pub fn deinit(base: *Symbol, allocator: *Allocator) void {
    allocator.free(base.name);
}

pub fn cast(base: *Symbol, comptime T: type) ?*T {
    if (base.@"type" != T.base_type) {
        return null;
    }
    return @fieldParentPtr(T, "base", base);
}

pub fn isStab(sym: macho.nlist_64) bool {
    return (macho.N_STAB & sym.n_type) != 0;
}

pub fn isPext(sym: macho.nlist_64) bool {
    return (macho.N_PEXT & sym.n_type) != 0;
}

pub fn isExt(sym: macho.nlist_64) bool {
    return (macho.N_EXT & sym.n_type) != 0;
}

pub fn isSect(sym: macho.nlist_64) bool {
    const type_ = macho.N_TYPE & sym.n_type;
    return type_ == macho.N_SECT;
}

pub fn isUndf(sym: macho.nlist_64) bool {
    const type_ = macho.N_TYPE & sym.n_type;
    return type_ == macho.N_UNDF;
}

pub fn isWeakDef(sym: macho.nlist_64) bool {
    return (sym.n_desc & macho.N_WEAK_DEF) != 0;
}

pub fn isWeakRef(sym: macho.nlist_64) bool {
    return (sym.n_desc & macho.N_WEAK_REF) != 0;
}