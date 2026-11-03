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

// Offsets of the data directories in the COFF optional header. They are
// immediately preceded by the number of data directories.
static constexpr intptr_t kPE32DataDirectoriesOffset = 96;
static constexpr intptr_t kPE32PlusDataDirectoriesOffset = 112;

static constexpr intptr_t kDebugDataDirectoryIndex = 6;

struct data_directory {
  uint32_t virtual_address;
  uint32_t size;
};

struct debug_directory_entry {
  uint32_t characteristics;
  uint32_t timestamp;
  uint16_t major_version;
  uint16_t minor_version;
  uint32_t type;
  uint32_t data_size;
  uint32_t data_address;
  uint32_t data_file_offset;
};

static constexpr uint32_t kDebugTypeCodeView = 2;

// The CodeView record that identifies the PDB for a PE image.
static const char kCodeViewPDB70Signature[] = {'R', 'S', 'D', 'S'};

struct codeview_pdb70_record {
  char signature[sizeof(kCodeViewPDB70Signature)];
  uint8_t guid[16];
  uint32_t age;
  // Followed by the null-terminated path of the PDB.
};

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
