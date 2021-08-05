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
class ProgramTable;
class Section;
class SectionTable;
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

  // The max page size on all supported architectures. Used to determine
  // the alignment of load segments, so that they are guaranteed page-aligned,
  // and no ELF section or segment should have a larger alignment.
  static constexpr intptr_t kPageSize = 16 * KB;

  bool IsStripped() const { return dwarf_ == nullptr; }

  Zone* zone() const { return zone_; }
  const Dwarf* dwarf() const { return dwarf_; }
  Dwarf* dwarf() { return dwarf_; }
  const SymbolTable& symtab() const {
    ASSERT(symtab_ != nullptr);
    return *symtab_;
  }
  const SectionTable& section_table() const { return *section_table_; }

  // Stores the information needed to appropriately generate a
  // relocation from the target to the source at the given section offset.
  // If a given symbol name is nullptr, then the corresponding offset is
  // relative from the location of the relocation itself.
  // If a given symbol name is "", then the corresponding offset is relative to
  // the start of the snapshot.
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
  static constexpr const char kBuildIdNoteName[] = ".note.gnu.build-id";
  static constexpr const char kTextName[] = ".text";
  static constexpr const char kDataName[] = ".rodata";
  static constexpr const char kBssName[] = ".bss";
  static constexpr const char kDynamicTableName[] = ".dynamic";

  void CreateBSS();
  void GenerateBuildId();
  void InitializeSymbolTables();
  void FinalizeDwarfSections();
  void FinalizeEhFrame();
  void ComputeOffsets();

  Zone* const zone_;
  BaseWriteStream* const unwrapped_stream_;
  const Type type_;

  // If nullptr, then the ELF file should be stripped of static information like
  // the static symbol table (and its corresponding string table).
  Dwarf* const dwarf_;

  // Contains all sections that will have entries in the section header table.
  SectionTable* const section_table_;

  // Contains all segments in the program header table. Set after finalizing
  // the section table.
  ProgramTable* program_table_ = nullptr;

  // The static tables are always created for use in relocation calculations,
  // even though they may not end up in the final ELF file.
  SymbolTable* symtab_ = nullptr;

  friend class SectionTable;  // For section name static fields.
};

#endif  // DART_PRECOMPILER

}  // namespace dart

#endif  // RUNTIME_VM_ELF_H_
