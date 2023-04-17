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
