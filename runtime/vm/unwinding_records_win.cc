// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unwinding_records.h"

#include "vm/globals.h"

#include "platform/unwinding_records.h"

#if defined(DART_HOST_OS_WINDOWS) && defined(TARGET_ARCH_X64)

namespace dart {

static void InitUnwindingRecord(intptr_t offset,
                                CodeRangeUnwindingRecord* record,
                                size_t code_size_in_bytes) {
  // All addresses are 32bit relative offsets to start.
  record->runtime_function[0].BeginAddress = 0;
  record->runtime_function[0].EndAddress = code_size_in_bytes;
  record->runtime_function[0].UnwindData =
      offset + offsetof(CodeRangeUnwindingRecord, unwind_info);
  record->runtime_function_count = 1;
}

const void* UnwindingRecords::GenerateRecordsInto(intptr_t offset,
                                                  uint8_t* target_buffer) {
  CodeRangeUnwindingRecord* record =
      new (target_buffer) CodeRangeUnwindingRecord();
  InitUnwindingRecord(offset, record, offset);
  return target_buffer;
}

// Special exception-unwinding records are put at the end of executable
// page on Windows for 64-bit applications.
void UnwindingRecords::RegisterExecutablePage(Page* page) {
  // Won't set up unwinding records on Windows 7, so users won't be able
  // to benefit from proper unhandled exceptions filtering.
  auto function = static_cast<decltype(&::RtlAddGrowableFunctionTable)>(
      UnwindingRecordsPlatform::GetAddGrowableFunctionTableFunc());
  if (function == nullptr) return;
  ASSERT(page->is_executable());
  ASSERT(sizeof(CodeRangeUnwindingRecord) <=
         UnwindingRecordsPlatform::SizeInBytes());
  page->top_ -= UnwindingRecordsPlatform::SizeInBytes();
  intptr_t unwinding_record_offset =
      page->memory_->size() - UnwindingRecordsPlatform::SizeInBytes();
  CodeRangeUnwindingRecord* record =
      new (reinterpret_cast<uint8_t*>(page->memory_->start()) +
           unwinding_record_offset) CodeRangeUnwindingRecord();
  InitUnwindingRecord(unwinding_record_offset, record, page->memory_->size());
  if (function(
          /*DynamicTable=*/&record->dynamic_table,
          /*FunctionTable=*/record->runtime_function,
          /*EntryCount=*/record->runtime_function_count,
          /*MaximumEntryCount=*/record->runtime_function_count,
          /*RangeBase=*/page->memory_->start(),
          /*RangeEnd=*/page->memory_->end()) != 0) {
    FATAL("Failed to add growable function table: %d\n", GetLastError());
  }
}

void UnwindingRecords::UnregisterExecutablePage(Page* page) {
  auto function = static_cast<decltype(&::RtlDeleteGrowableFunctionTable)>(
      UnwindingRecordsPlatform::GetDeleteGrowableFunctionTableFunc());
  if (function == nullptr) return;
  ASSERT(page->is_executable() && !page->is_image());
  intptr_t unwinding_record_offset =
      page->memory_->size() - UnwindingRecordsPlatform::SizeInBytes();
  CodeRangeUnwindingRecord* record =
      reinterpret_cast<CodeRangeUnwindingRecord*>(
          reinterpret_cast<uint8_t*>(page->memory_->start()) +
          unwinding_record_offset);
  function(record->dynamic_table);
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS)
