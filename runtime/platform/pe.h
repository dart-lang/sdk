// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_PE_H_
#define RUNTIME_PLATFORM_PE_H_

#include <platform/globals.h>

namespace dart {

namespace pe {

#pragma pack(push, 1)

static constexpr intptr_t kPEOffsetOffset = 0x3c;
static const char kPEMagic[] = {'P', 'E', '\0', '\0'};

struct coff_file_header {
  uint16_t machine;
  uint16_t num_sections;
  uint32_t timestamp;
  uint32_t symbol_table_offset;
  uint32_t num_symbols;
  uint16_t optional_header_size;
  uint16_t characteristics;
};

// Does not include the BaseOfData field for PE32 (not PE32+) files, but we
// don't need that to load a snapshot out of a PE file.
struct coff_optional_header {
  uint16_t magic;
  uint8_t linker_major_version;
  uint8_t linker_minor_version;
  uint32_t code_size;
  uint32_t initialized_data_size;
  uint32_t uninitialized_data_size;
  uint32_t entry_point_address;
  uint32_t code_base_address;
};

static constexpr uint16_t kPE32Magic = 0x10b;
static constexpr uint16_t kPE32PlusMagic = 0x20b;

static constexpr intptr_t kCoffSectionNameSize = 8;

struct coff_section_header {
  char name[kCoffSectionNameSize];
  uint32_t virtual_size;
  uint32_t virtual_address;
  uint32_t file_size;
  uint32_t file_offset;
  uint32_t relocations_offset;
  uint32_t line_numbers_offset;
  uint16_t num_relocations;
  uint16_t num_line_numbers;
  uint32_t characteristics;
};

#pragma pack(pop)

}  // namespace pe

}  // namespace dart

#endif  // RUNTIME_PLATFORM_PE_H_
