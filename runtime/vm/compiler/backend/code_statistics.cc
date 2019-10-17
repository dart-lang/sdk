// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/code_statistics.h"

namespace dart {

CombinedCodeStatistics::CombinedCodeStatistics() {
  unaccounted_bytes_ = 0;
  alignment_bytes_ = 0;
  object_header_bytes_ = 0;
  return_const_count_ = 0;
  return_const_with_load_field_count_ = 0;
  intptr_t i = 0;

#define DO(type, attrs)                                                        \
  entries_[i].name = #type;                                                    \
  entries_[i].bytes = 0;                                                       \
  entries_[i++].count = 0;

  FOR_EACH_INSTRUCTION(DO)

#undef DO

#define DO(type, attrs)                                                        \
  entries_[i].name = "SlowPath:" #type;                                        \
  entries_[i].bytes = 0;                                                       \
  entries_[i++].count = 0;

  FOR_EACH_INSTRUCTION(DO)

#undef DO

#define INIT_SPECIAL_ENTRY(tag, str)                                           \
  entries_[tag].name = str;                                                    \
  entries_[tag].bytes = 0;                                                     \
  entries_[tag].count = 0;

  INIT_SPECIAL_ENTRY(kTagAssertAssignableParameterCheck,
                     "AssertAssignable:ParameterCheck");
  INIT_SPECIAL_ENTRY(kTagAssertAssignableInsertedByFrontend,
                     "AssertAssignable:InsertedByFrontend");
  INIT_SPECIAL_ENTRY(kTagAssertAssignableFromSource,
                     "AssertAssignable:FromSource");

  INIT_SPECIAL_ENTRY(kTagCheckedEntry, "<checked-entry-prologue>");
  INIT_SPECIAL_ENTRY(kTagIntrinsics, "<intrinsics>");
#undef INIT_SPECIAL_ENTRY
}

void CombinedCodeStatistics::DumpStatistics() {
  ASSERT(unaccounted_bytes_ >= 0);

  Entry* sorted[kNumEntries];
  for (intptr_t i = 0; i < kNumEntries; i++) {
    sorted[i] = &entries_[i];
  }
  qsort(sorted, kNumEntries, sizeof(Entry*), &CompareEntries);

  intptr_t instruction_bytes = 0;
  for (intptr_t i = 0; i < kNumEntries; i++) {
    instruction_bytes += entries_[i].bytes;
  }
  intptr_t total = object_header_bytes_ + instruction_bytes +
                   unaccounted_bytes_ + alignment_bytes_;
  float ftotal = static_cast<float>(total) / 100.0;

  OS::PrintErr("--------------------\n");

  for (intptr_t i = 0; i < kNumEntries; i++) {
    Entry* entry = sorted[i];
    const char* name = entry->name;
    intptr_t bytes = entry->bytes;
    intptr_t count = entry->count;
    float percent = bytes / ftotal;
    float avg = static_cast<float>(bytes) / count;
    if (bytes > 0) {
      OS::PrintErr(
          "%5.2f %% "
          "% 8" Pd
          " bytes  "
          "% 8" Pd
          " count "
          "%8.2f avg bytes/entry    "
          "-    %s\n",
          percent, bytes, count, avg, name);
    }
  }

  OS::PrintErr("--------------------\n");

  OS::PrintErr("%5.2f %% % 8" Pd " bytes unaccounted\n",
               unaccounted_bytes_ / ftotal, unaccounted_bytes_);
  OS::PrintErr("%5.2f %% % 8" Pd " bytes alignment\n",
               alignment_bytes_ / ftotal, alignment_bytes_);
  OS::PrintErr("%5.2f %% % 8" Pd " bytes instruction object header\n",
               object_header_bytes_ / ftotal, object_header_bytes_);
  OS::PrintErr("%5.2f %% % 8" Pd " bytes instructions\n",
               instruction_bytes / ftotal, instruction_bytes);
  OS::PrintErr("--------------------\n");
  OS::PrintErr("%5.2f %% % 8" Pd " bytes in total\n", total / ftotal, total);
  OS::PrintErr("--------------------\n");
  OS::PrintErr("% 8" Pd " return-constant functions\n", return_const_count_);
  OS::PrintErr("% 8" Pd " return-constant-with-load-field functions\n",
               return_const_with_load_field_count_);
  OS::PrintErr("--------------------\n");
}

int CombinedCodeStatistics::CompareEntries(const void* a, const void* b) {
  const intptr_t a_size = (*static_cast<const Entry* const*>(a))->bytes;
  const intptr_t b_size = (*static_cast<const Entry* const*>(b))->bytes;
  if (a_size < b_size) {
    return -1;
  } else if (a_size > b_size) {
    return 1;
  } else {
    return 0;
  }
}

CodeStatistics::CodeStatistics(compiler::Assembler* assembler)
    : assembler_(assembler) {
  memset(entries_, 0, CombinedCodeStatistics::kNumEntries * sizeof(Entry));
  instruction_bytes_ = 0;
  unaccounted_bytes_ = 0;
  alignment_bytes_ = 0;

  stack_index_ = -1;
  for (intptr_t i = 0; i < kStackSize; i++)
    stack_[i] = -1;
}

void CodeStatistics::Begin(Instruction* instruction) {
  SpecialBegin(static_cast<intptr_t>(instruction->statistics_tag()));
}

void CodeStatistics::End(Instruction* instruction) {
  SpecialEnd(static_cast<intptr_t>(instruction->statistics_tag()));
}

void CodeStatistics::SpecialBegin(intptr_t tag) {
  stack_index_++;
  RELEASE_ASSERT(stack_index_ < kStackSize);
  RELEASE_ASSERT(stack_[stack_index_] == -1);
  RELEASE_ASSERT(tag < CombinedCodeStatistics::kNumEntries);
  stack_[stack_index_] = assembler_->CodeSize();
  RELEASE_ASSERT(stack_[stack_index_] >= 0);
}

void CodeStatistics::SpecialEnd(intptr_t tag) {
  RELEASE_ASSERT(stack_index_ > 0 || stack_[stack_index_] >= 0);
  RELEASE_ASSERT(tag < CombinedCodeStatistics::kNumEntries);

  intptr_t diff = assembler_->CodeSize() - stack_[stack_index_];
  RELEASE_ASSERT(diff >= 0);
  RELEASE_ASSERT(entries_[tag].bytes >= 0);
  RELEASE_ASSERT(entries_[tag].count >= 0);
  entries_[tag].bytes += diff;
  entries_[tag].count++;
  instruction_bytes_ += diff;
  stack_[stack_index_] = -1;
  stack_index_--;
}

void CodeStatistics::Finalize() {
  intptr_t function_size = assembler_->CodeSize();
  unaccounted_bytes_ = function_size - instruction_bytes_;
  ASSERT(unaccounted_bytes_ >= 0);

  const intptr_t unaligned_bytes = Instructions::HeaderSize() + function_size;
  alignment_bytes_ =
      Utils::RoundUp(unaligned_bytes, kObjectAlignment) - unaligned_bytes;
  assembler_ = NULL;
}

void CodeStatistics::AppendTo(CombinedCodeStatistics* stat) {
  intptr_t sum = 0;
  bool returns_constant = true;
  bool returns_const_with_load_field_ = true;

  for (intptr_t i = 0; i < CombinedCodeStatistics::kNumEntries; i++) {
    intptr_t bytes = entries_[i].bytes;
    stat->entries_[i].count += entries_[i].count;
    if (bytes > 0) {
      sum += bytes;
      stat->entries_[i].bytes += bytes;
      if (i != CombinedCodeStatistics::kTagParallelMove &&
          i != CombinedCodeStatistics::kTagReturn &&
          i != CombinedCodeStatistics::kTagCheckStackOverflow &&
          i != CombinedCodeStatistics::kTagCheckStackOverflowSlowPath) {
        returns_constant = false;
        if (i != CombinedCodeStatistics::kTagLoadField &&
            i != CombinedCodeStatistics::kTagTargetEntry &&
            i != CombinedCodeStatistics::kTagJoinEntry) {
          returns_const_with_load_field_ = false;
        }
      }
    }
  }
  stat->unaccounted_bytes_ += unaccounted_bytes_;
  ASSERT(stat->unaccounted_bytes_ >= 0);
  stat->alignment_bytes_ += alignment_bytes_;
  stat->object_header_bytes_ += Instructions::HeaderSize();

  if (returns_constant) stat->return_const_count_++;
  if (returns_const_with_load_field_) {
    stat->return_const_with_load_field_count_++;
  }
}

}  // namespace dart
