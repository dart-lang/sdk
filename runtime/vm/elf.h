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
#include "vm/so_writer.h"
#include "vm/zone.h"
#endif

namespace dart {

// The max page size on all supported architectures. Used to determine
// the alignment of load segments, so that they are guaranteed page-aligned,
// and no shared object section or segment should have a larger alignment.
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

class ProgramTable;
class SectionTable;
class ElfSymbolTable;

class ElfWriter : public SharedObjectWriter {
 public:
  ElfWriter(Zone* zone,
            BaseWriteStream* stream,
            Type type,
            Dwarf* dwarf = nullptr);

  static constexpr intptr_t kPageSize = kElfPageSize;
  intptr_t page_size() const override { return kPageSize; }

  Output output() const override { return Output::Elf; }

  const ElfSymbolTable& symtab() const {
    ASSERT(symtab_ != nullptr);
    return *symtab_;
  }
  const SectionTable& section_table() const { return *section_table_; }

  void AddText(const char* name,
               intptr_t label,
               const uint8_t* bytes,
               intptr_t size,
               const SharedObjectWriter::RelocationArray* relocations,
               const SharedObjectWriter::SymbolDataArray* symbol) override;
  void AddROData(const char* name,
                 intptr_t label,
                 const uint8_t* bytes,
                 intptr_t size,
                 const SharedObjectWriter::RelocationArray* relocations,
                 const SharedObjectWriter::SymbolDataArray* symbols) override;

  void Finalize() override;

  void AssertConsistency(const SharedObjectWriter* debug) const override {
    if (auto* const debug_elf = debug->AsElfWriter()) {
      AssertConsistency(this, debug_elf);
    } else {
      FATAL("Expected both snapshot and debug to be ELF");
    }
  }

  const ElfWriter* AsElfWriter() const override { return this; }

 private:
  static void AssertConsistency(const ElfWriter* snapshot,
                                const ElfWriter* debug_info);

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

  // Contains all sections that will have entries in the section header table.
  SectionTable* const section_table_;

  // Contains all segments in the program header table. Set after finalizing
  // the section table.
  ProgramTable* program_table_ = nullptr;

  // The static tables are always created for use in relocation calculations,
  // even though they may not end up in the final ELF file.
  ElfSymbolTable* symtab_ = nullptr;

  friend class SectionTable;  // For section name static fields.
};

#endif  // DART_PRECOMPILER

}  // namespace dart

#endif  // RUNTIME_VM_ELF_H_
