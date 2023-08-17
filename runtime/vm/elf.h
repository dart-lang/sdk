// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ELF_H_
#define RUNTIME_VM_ELF_H_

#include "platform/globals.h"

#if defined(DART_PRECOMPILER)
#include "vm/allocation.h"
#include "vm/compiler/runtime_api.h"
#include "vm/datastream.h"
#include "vm/growable_array.h"
#include "vm/zone.h"
#endif

namespace dart {

// The max page size on all supported architectures. Used to determine
// the alignment of load segments, so that they are guaranteed page-aligned,
// and no ELF section or segment should have a larger alignment.
#if defined(DART_TARGET_OS_LINUX) && defined(TARGET_ARCH_ARM64)
// Some Linux distributions on ARM64 select 64 KB page size.
// Follow LLVM (https://reviews.llvm.org/D25079) and set maximum page size
// to 64 KB for ARM64 Linux builds.
static constexpr intptr_t kElfPageSize = 64 * KB;
#elif defined(DART_TARGET_OS_ANDROID) && defined(TARGET_ARCH_IS_64_BIT)
static constexpr intptr_t kElfPageSize = 64 * KB;
#else
static constexpr intptr_t kElfPageSize = 16 * KB;
#endif

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

  static constexpr intptr_t kPageSize = kElfPageSize;

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
  struct Relocation {
    size_t size_in_bytes;
    intptr_t section_offset;
    intptr_t source_label;
    intptr_t source_offset;
    intptr_t target_label;
    intptr_t target_offset;

    // Used when the corresponding offset is relative from the location of the
    // relocation itself.
    static constexpr intptr_t kSelfRelative = -1;
    // Used when the corresponding offset is relative to the start of the
    // snapshot.
    static constexpr intptr_t kSnapshotRelative = -2;

    Relocation(size_t size_in_bytes,
               intptr_t section_offset,
               intptr_t source_label,
               intptr_t source_offset,
               intptr_t target_label,
               intptr_t target_offset)
        : size_in_bytes(size_in_bytes),
          section_offset(section_offset),
          source_label(source_label),
          source_offset(source_offset),
          target_label(target_label),
          target_offset(target_offset) {
      // Other than special values, all labels should be positive.
      ASSERT(source_label > 0 || source_label == kSelfRelative ||
             source_label == kSnapshotRelative);
      ASSERT(target_label > 0 || target_label == kSelfRelative ||
             target_label == kSnapshotRelative);
    }
  };

  // Stores the information needed to appropriately generate a symbol
  // during finalization.
  struct SymbolData {
    const char* name;
    intptr_t type;
    intptr_t offset;
    size_t size;
    // A positive unique ID only used internally in the Dart VM, not part of
    // the Elf output.
    intptr_t label;

    SymbolData(const char* name,
               intptr_t type,
               intptr_t offset,
               size_t size,
               intptr_t label)
        : name(name), type(type), offset(offset), size(size), label(label) {
      ASSERT(label > 0);
    }
  };

  // Must be the same value as the values returned by ImageWriter::SectionLabel
  // for the appropriate section and vm values.
  static constexpr intptr_t kVmBssLabel = 5;
  static constexpr intptr_t kIsolateBssLabel = 6;
  static constexpr intptr_t kBuildIdLabel = 7;

  void AddText(const char* name,
               intptr_t label,
               const uint8_t* bytes,
               intptr_t size,
               const ZoneGrowableArray<Relocation>* relocations,
               const ZoneGrowableArray<SymbolData>* symbol);
  void AddROData(const char* name,
                 intptr_t label,
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
