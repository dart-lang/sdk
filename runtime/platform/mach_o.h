// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_MACH_O_H_
#define RUNTIME_PLATFORM_MACH_O_H_

#include <platform/globals.h>

namespace dart {

namespace mach_o {

#pragma pack(push, 1)

typedef int cpu_type_t;
typedef int cpu_subtype_t;
typedef int vm_prot_t;

// Mach-O FAT header is big-endian.
static constexpr uint32_t FAT_MAGIC = 0xcafebabe;
static constexpr uint32_t FAT_MAGIC_64 = 0xcafebabf;

struct fat_header {
  uint32_t magic;      // FAT_MAGIC or FAT_MAGIC_64
  uint32_t nfat_arch;  // Number of fat_arch structs that follow.
};

// iOS uses a 32-bit fat_arch struct, despite being a 64-bit platform.
struct fat_arch {
  cpu_type_t cputype;
  cpu_subtype_t cpusubtype;
  uint32_t offset;
  uint32_t size;
  uint32_t align;
};

// We only care about 64-bit ARM for iOS.
static constexpr uint32_t CPU_ARCH_MASK = 0xff000000;
static constexpr uint32_t CPU_ARCH_ABI64 = 0x01000000;
static constexpr cpu_type_t CPU_TYPE_ARM = 12;
static constexpr cpu_type_t CPU_TYPE_ARM64 = CPU_TYPE_ARM | CPU_ARCH_ABI64;

struct mach_header {
  uint32_t magic;
  cpu_type_t cputype;
  cpu_subtype_t cpusubtype;
  uint32_t filetype;
  uint32_t ncmds;
  uint32_t sizeofcmds;
  uint32_t flags;
};

static constexpr uint32_t MH_MAGIC = 0xfeedface;
static constexpr uint32_t MH_CIGAM = 0xcefaedfe;

struct mach_header_64 {
  uint32_t magic;
  cpu_type_t cputype;
  cpu_subtype_t cpusubtype;
  uint32_t filetype;
  uint32_t ncmds;
  uint32_t sizeofcmds;
  uint32_t flags;
  uint32_t reserved;
};

static constexpr uint32_t MH_MAGIC_64 = 0xfeedfacf;
static constexpr uint32_t MH_CIGAM_64 = 0xcffaedfe;

static constexpr uint32_t LC_SYMTAB = 0x2;
static constexpr uint32_t LC_SEGMENT_64 = 0x19;

struct symtab_command {
  uint32_t cmd;
  uint32_t cmdsize;
  uint32_t symoff;  // Offset to the symbol table, relative to beginning of the
                    // loaded linkedit segment.
  uint32_t nsyms;
  uint32_t stroff;   // Offset to the string table, relative to beginning of the
                     // loaded linkedit segment.  The string table immediately
                     // follows the symbol table and is just an series of
                     // null-terminated strings one after the other.
  uint32_t strsize;  // Size of the string table.
};

// Symbol table entry.
struct nlist_64 {
  union {
    uint32_t n_strx;  // index into the string table.
  } n_un;
  uint8_t n_type;
  uint8_t n_sect;  // Section number (1-based).
  uint16_t n_desc;
  uint64_t n_value;  // Value of this symbol (e.g. address)
};

// A Segment Load Command.  In a Dart snapshot, there will only be 3 segments:
// __TEXT, __DATA, and __LINKEDIT.
// The __TEXT segment contains the code and read-only data.
// The __DATA segment contains the read-write data.
// The __LINKEDIT segment contains the symbol table and string table.
struct segment_command_64 {
  uint32_t cmd;
  uint32_t cmdsize;
  char segname[16];
  uint64_t vmaddr;
  uint64_t vmsize;
  uint64_t fileoff;
  uint64_t filesize;
  vm_prot_t maxprot;
  vm_prot_t initprot;
  uint32_t nsects;
  uint32_t flags;
};

static constexpr uint32_t VM_PROT_NONE = 0x00;
static constexpr uint32_t VM_PROT_READ = 0x01;
static constexpr uint32_t VM_PROT_WRITE = 0x02;
static constexpr uint32_t VM_PROT_EXECUTE = 0x04;

// Segments may contain zero or more sections.
struct section_64 {
  char sectname[16];
  char segname[16];
  uint64_t addr;
  uint64_t size;
  uint32_t offset;
  uint32_t align;
  uint32_t reloff;
  uint32_t nreloc;
  uint32_t flags;
  uint32_t reserved1;
  uint32_t reserved2;
  uint32_t reserved3;
};

struct load_command {
  uint32_t cmd;
  uint32_t cmdsize;
};

static constexpr uint32_t LC_NOTE = 0x31;
struct note_command {
  uint32_t cmd;
  uint32_t cmdsize;
  char data_owner[16];
  uint64_t offset;
  uint64_t size;
};

#pragma pack(pop)

}  // namespace mach_o

}  // namespace dart

#endif  // RUNTIME_PLATFORM_MACH_O_H_
