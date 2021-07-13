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

#if defined(DART_PRECOMPILER)

class Dwarf;
class DynamicTable;
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

  static constexpr intptr_t kPageSize = 16 * KB;
  static constexpr uword kNoSectionStart = 0;

  bool IsStripped() const { return dwarf_ == nullptr; }

  Zone* zone() const { return zone_; }
  const Dwarf* dwarf() const { return dwarf_; }
  Dwarf* dwarf() { return dwarf_; }
  const SymbolTable& symtab() const { return *symtab_; }

  // Stores the information needed to appropriately generate a
  // relocation from the target to the source at the given section offset.
  // If a given symbol is nullptr, then the offset is absolute (from 0).
  // Both source and target symbols could be "." which is pseudosymbol
  // corresponding to the location of the relocation itself.
  struct Relocation {
    size_t size_in_bytes;
    intptr_t section_offset;
    const char* source_symbol;
    intptr_t source_offset;
    const char* target_symbol;
    intptr_t target_offset;
  };

  // Stores the information needed to appropriately generate a symbol
  // during finalization.
  struct SymbolData {
    const char* name;
    intptr_t type;
    intptr_t offset;
    size_t size;
  };

  void AddText(const char* name,
               const uint8_t* bytes,
               intptr_t size,
               const ZoneGrowableArray<Relocation>* relocations,
               const ZoneGrowableArray<SymbolData>* symbol);
  void AddROData(const char* name,
                 const uint8_t* bytes,
                 intptr_t size,
                 const ZoneGrowableArray<Relocation>* relocations,
                 const ZoneGrowableArray<SymbolData>* symbols);

  void Finalize();

 private:
  static constexpr const char* kBuildIdNoteName = ".note.gnu.build-id";

  void AddSection(Section* section, const char* name);

  const Section* FindSectionBySymbolName(const char* symbol_name) const;

  void CreateBSS();
  void GenerateBuildId();

  void OrderSectionsAndCreateSegments();

  void InitializeSymbolTables();
  void FinalizeSymbolTables();
  void FinalizeDwarfSections();
  void FinalizeProgramTable();
  void ComputeOffsets();

  void FinalizeEhFrame();

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

  // All our strings would fit in a single page. However, we use separate
  // .shstrtab and .dynstr to work around a bug in Android's strip utility.
  StringTable* const shstrtab_;
  DynamicTable* dynamic_ = nullptr;

  // The static tables are always created for use in relocation calculations,
  // even though they may not end up in the final ELF file.
  SymbolTable* symtab_ = nullptr;

  // We always create a BSS section for all Elf files to keep memory offsets
  // consistent, though it is NOBITS for separate debugging information.
  Section* bss_ = nullptr;

  // We currently create a GNU build ID for all ELF snapshots and associated
  // debugging information.
  Section* build_id_ = nullptr;

  GrowableArray<Section*> sections_;
  GrowableArray<Segment*> segments_;

  intptr_t memory_offset_;
  intptr_t section_table_file_offset_ = -1;
  intptr_t section_table_file_size_ = -1;
  intptr_t program_table_file_offset_ = -1;
  intptr_t program_table_file_size_ = -1;
};

#endif  // DART_PRECOMPILER

}  // namespace dart

#endif  // RUNTIME_VM_ELF_H_
