// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ELF_H_
#define RUNTIME_VM_ELF_H_

#include "vm/allocation.h"
#include "vm/compiler/runtime_api.h"
#include "vm/datastream.h"
#include "vm/growable_array.h"
#include "vm/zone.h"

namespace dart {

class Dwarf;
class ElfWriteStream;
class Section;
class Segment;
class StringTable;
class SymbolTable;

class Elf : public ZoneAllocated {
 public:
  enum class Type {
    // A snapshot that should include segment contents.
    Snapshot,
    // Separately compiled debugging information that should not include
    // most segment contents.
    DebugInfo,
  };

  Elf(Zone* zone,
      StreamingWriteStream* stream,
      Type type,
      Dwarf* dwarf = nullptr);

  static const intptr_t kPageSize = 4096;

  bool IsStripped() const { return dwarf_ == nullptr; }

  Zone* zone() { return zone_; }
  const Dwarf* dwarf() const { return dwarf_; }
  Dwarf* dwarf() { return dwarf_; }

  uword BssStart(bool vm) const;

  // What the next memory offset for a kPageSize-aligned section would be.
  //
  // Only used by BlobImageWriter::WriteText() to determine the memory offset
  // for the text section before it is added.
  intptr_t NextMemoryOffset() const;
  intptr_t AddNoBits(const char* name, const uint8_t* bytes, intptr_t size);
  intptr_t AddText(const char* name, const uint8_t* bytes, intptr_t size);
  intptr_t AddROData(const char* name, const uint8_t* bytes, intptr_t size);
  void AddDebug(const char* name, const uint8_t* bytes, intptr_t size);

  void Finalize();

 private:
  static Section* CreateBSS(Zone* zone, Type type, intptr_t size);

  // Adds the section and also creates a PT_LOAD segment for the section if it
  // is an allocated section.
  //
  // For allocated sections, if symbol_name is provided, a symbol for the
  // section will be added to the dynamic table (if allocated) and static
  // table (if not stripped) during finalization.
  //
  // Returns the memory offset if the section is allocated.
  intptr_t AddSection(Section* section,
                      const char* name,
                      const char* symbol_name = nullptr);
  void AddStaticSymbol(const char* name,
                       intptr_t info,
                       intptr_t section_index,
                       intptr_t address,
                       intptr_t size);
  void AddDynamicSymbol(const char* name,
                        intptr_t info,
                        intptr_t section_index,
                        intptr_t address,
                        intptr_t size);

  Segment* LastLoadSegment() const;
  const Section* FindSectionForAddress(intptr_t address) const;
  Section* GenerateBuildId();

  void AddSectionSymbols();
  void FinalizeDwarfSections();
  void FinalizeProgramTable();
  void ComputeFileOffsets();

  void WriteHeader(ElfWriteStream* stream);
  void WriteSectionTable(ElfWriteStream* stream);
  void WriteProgramTable(ElfWriteStream* stream);
  void WriteSections(ElfWriteStream* stream);

  Zone* const zone_;
  StreamingWriteStream* const unwrapped_stream_;
  const Type type_;

  // If nullptr, then the ELF file should be stripped of static information like
  // the static symbol table (and its corresponding string table).
  Dwarf* const dwarf_;

  // We always create a BSS section for all Elf files, though it may be NOBITS
  // if this is separate debugging information.
  Section* const bss_;

  // All our strings would fit in a single page. However, we use separate
  // .shstrtab and .dynstr to work around a bug in Android's strip utility.
  StringTable* const shstrtab_;
  StringTable* const dynstrtab_;
  SymbolTable* const dynsym_;

  // The static tables are lazily created when static symbols are added.
  StringTable* strtab_ = nullptr;
  SymbolTable* symtab_ = nullptr;

  GrowableArray<Section*> sections_;
  GrowableArray<Segment*> segments_;
  intptr_t memory_offset_;
  intptr_t section_table_file_offset_ = -1;
  intptr_t section_table_file_size_ = -1;
  intptr_t program_table_file_offset_ = -1;
  intptr_t program_table_file_size_ = -1;
};

}  // namespace dart

#endif  // RUNTIME_VM_ELF_H_
