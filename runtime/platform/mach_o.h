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

struct mach_header {
  uint32_t magic;
  cpu_type_t cputype;
  cpu_subtype_t cpusubtype;
  uint32_t filetype;
  uint32_t ncmds;
  uint32_t sizeofcmds;
  uint32_t flags;
};

static const uint32_t MH_MAGIC = 0xfeedface;
static const uint32_t MH_CIGAM = 0xcefaedfe;

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

static const uint32_t MH_MAGIC_64 = 0xfeedfacf;
static const uint32_t MH_CIGAM_64 = 0xcffaedfe;

struct load_command {
  uint32_t cmd;
  uint32_t cmdsize;
};

static const uint32_t LC_SEGMENT = 0x1;
static const uint32_t LC_SEGMENT_64 = 0x19;

struct section {
  char sectname[16];
  char segname[16];
  uint32_t addr;
  uint32_t size;
  uint32_t offset;
  uint32_t align;
  uint32_t reloff;
  uint32_t nreloc;
  uint32_t flags;
  uint32_t reserved1;
  uint32_t reserved2;
};

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

#pragma pack(pop)

}  // namespace mach_o

}  // namespace dart

#endif  // RUNTIME_PLATFORM_MACH_O_H_
