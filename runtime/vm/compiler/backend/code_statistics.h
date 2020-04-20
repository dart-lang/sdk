// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_CODE_STATISTICS_H_
#define RUNTIME_VM_COMPILER_BACKEND_CODE_STATISTICS_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/il.h"
#include "vm/object.h"

namespace dart {

class CombinedCodeStatistics {
 public:
  // clang-format off
  enum EntryCounter {
#define DO(type, attrs) kTag##type,
    FOR_EACH_INSTRUCTION(DO)
#undef DO

#define DO(type, attrs) kTag##type##SlowPath,
    FOR_EACH_INSTRUCTION(DO)
#undef DO

    kTagAssertAssignableParameterCheck,
    kTagAssertAssignableInsertedByFrontend,
    kTagAssertAssignableFromSource,

    kTagCheckedEntry,
    kTagIntrinsics,

    kNumEntries,
  };
  // clang-format on

  CombinedCodeStatistics();

  void Begin(Instruction* instruction);
  void End(Instruction* instruction);

  void DumpStatistics();

  static EntryCounter SlowPathCounterFor(Instruction::Tag tag) {
    return static_cast<CombinedCodeStatistics::EntryCounter>(
        CombinedCodeStatistics::kTagGraphEntrySlowPath + tag);
  }

 private:
  friend class CodeStatistics;

  static int CompareEntries(const void* a, const void* b);

  typedef struct {
    const char* name;
    intptr_t bytes;
    intptr_t count;
  } Entry;

  Entry entries_[kNumEntries];
  intptr_t unaccounted_bytes_;
  intptr_t alignment_bytes_;
  intptr_t object_header_bytes_;
  intptr_t return_const_count_;
  intptr_t return_const_with_load_field_count_;
};

class CodeStatistics {
 public:
  explicit CodeStatistics(compiler::Assembler* assembler);

  void Begin(Instruction* instruction);
  void End(Instruction* instruction);

  void SpecialBegin(intptr_t tag);
  void SpecialEnd(intptr_t tag);

  void AppendTo(CombinedCodeStatistics* stat);

  void Finalize();

 private:
  static const int kStackSize = 8;

  compiler::Assembler* assembler_;

  typedef struct {
    intptr_t bytes;
    intptr_t count;
  } Entry;

  Entry entries_[CombinedCodeStatistics::kNumEntries];
  intptr_t instruction_bytes_;
  intptr_t unaccounted_bytes_;
  intptr_t alignment_bytes_;

  intptr_t stack_[kStackSize];
  intptr_t stack_index_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_CODE_STATISTICS_H_
