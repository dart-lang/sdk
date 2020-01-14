// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ELF_H_
#define RUNTIME_VM_ELF_H_

#include "vm/allocation.h"
#include "vm/compiler/runtime_api.h"
#include "vm/datastream.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/zone.h"

namespace dart {

class DynamicTable;
class Section;
class StringTable;
class Symbol;
class SymbolTable;

class Elf : public ZoneAllocated {
 public:
  Elf(Zone* zone,
      StreamingWriteStream* stream,
      bool strip,
      StreamingWriteStream* debug_stream = nullptr);

  static const intptr_t kPageSize = 4096;

  intptr_t NextMemoryOffset() const { return memory_offset_; }
  intptr_t NextSectionIndex() const;
  intptr_t AddText(const char* name, const uint8_t* bytes, intptr_t size);
  intptr_t AddROData(const char* name, const uint8_t* bytes, intptr_t size);
  intptr_t AddBSSData(const char* name, intptr_t size);
  void AddDebug(const char* name, const uint8_t* bytes, intptr_t size);
  void AddStaticSymbol(intptr_t section,
                       const char* name,
                       size_t memory_offset);

  void Finalize();

  static void WriteBytes(StreamingWriteStream* stream,
                         const uint8_t* bytes,
                         intptr_t size) {
    stream->WriteBytes(bytes, size);
  }
  static void WriteByte(StreamingWriteStream* stream, uint8_t value) {
    stream->WriteBytes(reinterpret_cast<uint8_t*>(&value), sizeof(value));
  }
  static void WriteHalf(StreamingWriteStream* stream, uint16_t value) {
    stream->WriteBytes(reinterpret_cast<uint8_t*>(&value), sizeof(value));
  }
  static void WriteWord(StreamingWriteStream* stream, uint32_t value) {
    stream->WriteBytes(reinterpret_cast<uint8_t*>(&value), sizeof(value));
  }
  static void WriteAddr(StreamingWriteStream* stream,
                        compiler::target::uword value) {
    stream->WriteBytes(reinterpret_cast<uint8_t*>(&value), sizeof(value));
  }
  static void WriteOff(StreamingWriteStream* stream,
                       compiler::target::uword value) {
    stream->WriteBytes(reinterpret_cast<uint8_t*>(&value), sizeof(value));
  }
#if defined(TARGET_ARCH_IS_64_BIT)
  static void WriteXWord(StreamingWriteStream* stream, uint64_t value) {
    stream->WriteBytes(reinterpret_cast<uint8_t*>(&value), sizeof(value));
  }
#endif

 private:
  void AddSection(Section* section, const char* name);
  void AddSegment(Section* section);

  intptr_t ActiveSectionsIndex(intptr_t section_index) const;
  intptr_t SectionTableIndex(intptr_t section_index) const;
  intptr_t ProgramTableSize() const;
  intptr_t SectionTableSize() const;

  void ClearOutputInfo();
  // Checks that the output information used by the writing methods has been
  // properly constructed.
  void VerifyOutputInfo() const;

  // Creates a new version of shstrtab_ that only copies over names of active
  // sections. Sets the contents of section_names_ to indices in the new table.
  StringTable* CreateSectionHeaderStringTable();
  // Either returns the original section or a section like the old one that
  // also accounts for what sections are currently active.
  Section* AdjustForActiveSections(Section* section);

  // These methods return the new file offset taking into consideration the
  // alignment and size of the section.
  intptr_t PrepareDebugSection(Section* section,
                               intptr_t start_offset,
                               bool use_fake_info);
  intptr_t PrepareMainSection(Section* section,
                              intptr_t start_offset,
                              intptr_t skipped_sections);

  // These methods set up:
  //   * Various information about file offsets
  //   * The number of entries in the program and section tables
  //   * An array of the active sections (i.e., those in the section table).
  //   * An array of the sections that will be fully output.
  //   * Some arrays of information used instead of the values of their
  //     corresponding Section fields when creating the section table.
  void PrepareDebugOutputInfo();
  void PrepareMainOutputInfo();

  void WriteHeader(StreamingWriteStream* s);
  void WriteProgramTable(StreamingWriteStream* s);
  void WriteSectionTable(StreamingWriteStream* s);
  void WriteSections(StreamingWriteStream* s);

  Zone* const zone_;
  const bool strip_;
  StreamingWriteStream* const stream_;
  StreamingWriteStream* const debug_stream_;
  GrowableArray<Section*> sections_;
  GrowableArray<Section*> segments_;

  intptr_t memory_offset_ = 0;
  StringTable* shstrtab_ = nullptr;
  StringTable* dynstrtab_ = nullptr;
  SymbolTable* dynsym_ = nullptr;
  StringTable* strtab_ = nullptr;
  SymbolTable* symtab_ = nullptr;
  DynamicTable* dynamic_ = nullptr;

  // Filled out during the Prepare*OutputInfo methods and used by the Write*
  // instance methods, as these values will differ between stripped and
  // debugging outputs.
  GrowableArray<Section*> active_sections_;
  GrowableArray<Section*> output_sections_;
  IntMap<intptr_t> adjusted_indices_;
  // These should all contain entries for the sections in active_sections_.
  GrowableArray<intptr_t> file_sizes_;
  GrowableArray<intptr_t> section_names_;
  GrowableArray<intptr_t> section_types_;
  intptr_t section_table_file_offset_ = -1;
  intptr_t section_table_entry_count_ = -1;
  intptr_t program_table_file_offset_ = -1;
  intptr_t program_table_entry_count_ = -1;
};

}  // namespace dart

#endif  // RUNTIME_VM_ELF_H_
