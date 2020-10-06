// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_ELF_H_
#define RUNTIME_PLATFORM_ELF_H_

#include "platform/globals.h"

namespace dart {
namespace elf {

#pragma pack(push, 1)

struct ElfHeader {
  uint8_t ident[16];
  uint16_t type;
  uint16_t machine;
  uint32_t version;
#if defined(TARGET_ARCH_IS_32_BIT)
  uint32_t entry_point;
  uint32_t program_table_offset;
  uint32_t section_table_offset;
#else
  uint64_t entry_point;
  uint64_t program_table_offset;
  uint64_t section_table_offset;
#endif
  uint32_t flags;
  uint16_t header_size;
  uint16_t program_table_entry_size;
  uint16_t num_program_headers;
  uint16_t section_table_entry_size;
  uint16_t num_section_headers;
  uint16_t shstrtab_section_index;
};

enum class ProgramHeaderType : uint32_t {
  PT_NULL = 0,
  PT_LOAD = 1,
  PT_DYNAMIC = 2,
  PT_NOTE = 4,
  PT_PHDR = 6,
};

struct ProgramHeader {
#if defined(TARGET_ARCH_IS_32_BIT)
  ProgramHeaderType type;
  uint32_t file_offset;
  uint32_t memory_offset;
  uint32_t physical_memory_offset;
  uint32_t file_size;
  uint32_t memory_size;
  uint32_t flags;
  uint32_t alignment;
#else
  ProgramHeaderType type;
  uint32_t flags;
  uint64_t file_offset;
  uint64_t memory_offset;
  uint64_t physical_memory_offset;
  uint64_t file_size;
  uint64_t memory_size;
  uint64_t alignment;
#endif
};

enum class SectionHeaderType : uint32_t {
  SHT_NULL = 0,
  SHT_PROGBITS = 1,
  SHT_SYMTAB = 2,
  SHT_STRTAB = 3,
  SHT_HASH = 5,
  SHT_NOTE = 7,
  SHT_NOBITS = 8,
  SHT_DYNAMIC = 6,
  SHT_DYNSYM = 11,
};

struct SectionHeader {
#if defined(TARGET_ARCH_IS_32_BIT)
  uint32_t name;
  SectionHeaderType type;
  uint32_t flags;
  uint32_t memory_offset;
  uint32_t file_offset;
  uint32_t file_size;
  uint32_t link;
  uint32_t info;
  uint32_t alignment;
  uint32_t entry_size;
#else
  uint32_t name;
  SectionHeaderType type;
  uint64_t flags;
  uint64_t memory_offset;
  uint64_t file_offset;
  uint64_t file_size;
  uint32_t link;
  uint32_t info;
  uint64_t alignment;
  uint64_t entry_size;
#endif
};

struct Symbol {
#if defined(TARGET_ARCH_IS_32_BIT)
  uint32_t name;
  uint32_t value;
  uint32_t size;
  uint8_t info;
  uint8_t other;  // Reserved by ELF.
  uint16_t section;
#else
  uint32_t name;
  uint8_t info;
  uint8_t other;  // Reserved by ELF.
  uint16_t section;
  uint64_t value;
  uint64_t size;
#endif
};

enum class DynamicEntryType : uint32_t {
  DT_NULL = 0,
  DT_HASH = 4,
  DT_STRTAB = 5,
  DT_SYMTAB = 6,
  DT_STRSZ = 10,
  DT_SYMENT = 11,
};

struct DynamicEntry {
#if defined(TARGET_ARCH_IS_32_BIT)
  uint32_t tag;
  uint32_t value;
#else
  uint64_t tag;
  uint64_t value;
#endif
};

enum class NoteType : uint32_t {
  NT_GNU_BUILD_ID = 3,
};

struct Note {
  uint32_t name_size;
  uint32_t description_size;
  NoteType type;
  uint8_t data[];
};

#pragma pack(pop)

static constexpr intptr_t ELFCLASS32 = 1;
static constexpr intptr_t ELFCLASS64 = 2;

static const intptr_t EI_DATA = 5;
static const intptr_t ELFDATA2LSB = 1;

static const intptr_t ELFOSABI_SYSV = 0;

static const intptr_t ET_DYN = 3;

static constexpr intptr_t EF_ARM_ABI_FLOAT_HARD = 0x00000400;
static constexpr intptr_t EF_ARM_ABI_FLOAT_SOFT = 0x00000200;
static constexpr intptr_t EF_ARM_ABI = 0x05000000;

static constexpr intptr_t EM_386 = 3;
static constexpr intptr_t EM_ARM = 40;
static constexpr intptr_t EM_X86_64 = 62;
static constexpr intptr_t EM_AARCH64 = 183;

static const intptr_t EV_CURRENT = 1;

static const intptr_t PF_X = 1;
static const intptr_t PF_W = 2;
static const intptr_t PF_R = 4;

static const intptr_t SHF_WRITE = 0x1;
static const intptr_t SHF_ALLOC = 0x2;
static const intptr_t SHF_EXECINSTR = 0x4;

static const intptr_t SHN_UNDEF = 0;

static const intptr_t STN_UNDEF = 0;

static const intptr_t STB_LOCAL = 0;
static const intptr_t STB_GLOBAL = 1;

static const intptr_t STT_NOTYPE = 0;
static const intptr_t STT_OBJECT = 1;  // I.e., data.
static const intptr_t STT_FUNC = 2;
static const intptr_t STT_SECTION = 3;

static constexpr const char ELF_NOTE_GNU[] = "GNU";

// Creates symbol info from the given STB and STT values.
constexpr decltype(Symbol::info) SymbolInfo(intptr_t binding, intptr_t type) {
  // Take the low nibble of each value in case, though the upper bits should
  // all be zero as long as STB/STT constants are used.
  return (binding & 0xf) << 4 | (type & 0xf);
}

// Retrieves the STB binding value for the given symbol info.
constexpr intptr_t SymbolBinding(const decltype(Symbol::info) info) {
  return (info >> 4) & 0xf;
}

// Retrieves the STT type value for the given symbol info.
constexpr intptr_t SymbolType(const decltype(Symbol::info) info) {
  return info & 0xf;
}

}  // namespace elf
}  // namespace dart

#endif  // RUNTIME_PLATFORM_ELF_H_
