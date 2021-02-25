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

  Elf(Zone* zone, BaseWriteStream* stream, Type type, Dwarf* dwarf = nullptr);

  static constexpr intptr_t kPageSize = 4096;
  static constexpr uword kNoSectionStart = 0;

  bool IsStripped() const { return dwarf_ == nullptr; }

  Zone* zone() { return zone_; }
  const Dwarf* dwarf() const { return dwarf_; }
  Dwarf* dwarf() { return dwarf_; }

  // Returns the relocated address for the symbol with the given name or
  // kNoSectionStart if the symbol was not found.
  uword SymbolAddress(const char* name) const;

  // What the next memory offset for an appropriately aligned section would be.
  //
  // Only used by AssemblyImageWriter and BlobImageWriter methods.
  intptr_t NextMemoryOffset(intptr_t alignment) const;
  intptr_t AddText(const char* name, const uint8_t* bytes, intptr_t size);
  intptr_t AddROData(const char* name, const uint8_t* bytes, intptr_t size);
  void AddDebug(const char* name, const uint8_t* bytes, intptr_t size);

  // Adds a local symbol for the given offset and size in the "current" section,
  // that is, the section index for the symbol is for the next added section.
  void AddLocalSymbol(const char* name,
                      intptr_t type,
                      intptr_t offset,
                      intptr_t size);

  void Finalize();

 private:
  static constexpr const char* kBuildIdNoteName = ".note.gnu.build-id";

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
  // Replaces [old_section] with [new_section] in all appropriate places. If the
  // section is allocated, the memory size of the section must be the same as
  // the original to ensure any already-calculated memory offsets are unchanged.
  void ReplaceSection(Section* old_section, Section* new_section);

  void AddStaticSymbol(const char* name,
                       intptr_t binding,
                       intptr_t type,
                       intptr_t section_index,
                       intptr_t address,
                       intptr_t size);
  void AddDynamicSymbol(const char* name,
                        intptr_t binding,
                        intptr_t type,
                        intptr_t section_index,
                        intptr_t address,
                        intptr_t size);

  Segment* LastLoadSegment() const;
  const Section* FindSectionForAddress(intptr_t address) const;
  Section* CreateBuildIdNote(const void* description_bytes,
                             intptr_t description_length);
  Section* GenerateFinalBuildId();

  void AddSectionSymbols();
  void FinalizeDwarfSections();
  void FinalizeProgramTable();
  void ComputeFileOffsets();

  void WriteHeader(ElfWriteStream* stream);
  void WriteSectionTable(ElfWriteStream* stream);
  void WriteProgramTable(ElfWriteStream* stream);
  void WriteSections(ElfWriteStream* stream);

  Zone* const zone_;
  BaseWriteStream* const unwrapped_stream_;
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

  // We always create a GNU build ID for all Elf files. In order to create
  // the appropriate offset to it in an InstructionsSection object, we create an
  // initial build ID section as a placeholder and then replace that section
  // during finalization once we have the information to calculate the real one.
  Section* build_id_;

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
