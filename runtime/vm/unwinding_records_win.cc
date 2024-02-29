// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unwinding_records.h"

#include "vm/globals.h"

#include "platform/unwinding_records.h"

namespace dart {

#if (defined(DART_TARGET_OS_WINDOWS) || defined(DART_HOST_OS_WINDOWS)) &&      \
    (defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_ARM64))

static void InitUnwindingRecord(intptr_t offset,
                                CodeRangeUnwindingRecord* record,
                                size_t code_size_in_bytes) {
#if defined(TARGET_ARCH_X64)
  // All addresses are 32bit relative offsets to start.
  record->runtime_function[0].BeginAddress = 0;
  record->runtime_function[0].EndAddress = code_size_in_bytes;
  record->runtime_function[0].UnwindData =
      offset + offsetof(CodeRangeUnwindingRecord, unwind_info);
  record->runtime_function_count = 1;
#elif defined(TARGET_ARCH_ARM64)

  const intptr_t kInstrSize = 4;

  // We assume that the first page of the code range is executable and
  // committed and reserved to contain multiple PDATA/XDATA to cover the whole
  // range. All addresses are 32bit relative offsets to start.

  // Maximum RUNTIME_FUNCTION count available in reserved memory, this includes
  // static part in Record as kDefaultRuntimeFunctionCount plus dynamic part in
  // the remaining reserved memory.
  const uint32_t max_runtime_function_count =
      static_cast<uint32_t>((UnwindingRecordsPlatform::SizeInBytes() -
                             sizeof(CodeRangeUnwindingRecord)) /
                                sizeof(RUNTIME_FUNCTION) +
                            kDefaultRuntimeFunctionCount);

  uint32_t runtime_function_index = 0;
  uint32_t current_unwind_start_address = 0;
  int64_t remaining_size_in_bytes = static_cast<int64_t>(code_size_in_bytes);

  // Divide the code range into chunks in size kMaxFunctionLength and create a
  // RUNTIME_FUNCTION for each of them. All the chunks in the same size can
  // share 1 unwind_info struct, but a separate unwind_info is needed for the
  // last chunk if it is smaller than kMaxFunctionLength, because unlike X64,
  // unwind_info encodes the function/chunk length.
  while (remaining_size_in_bytes >= kMaxFunctionLength &&
         runtime_function_index < max_runtime_function_count) {
    record->runtime_function[runtime_function_index].BeginAddress =
        current_unwind_start_address;
    record->runtime_function[runtime_function_index].UnwindData =
        offset +
        static_cast<DWORD>(offsetof(CodeRangeUnwindingRecord, unwind_info));

    runtime_function_index++;
    current_unwind_start_address += kMaxFunctionLength;
    remaining_size_in_bytes -= kMaxFunctionLength;
  }
  // FunctionLength is ensured to be aligned at instruction size and Windows
  // ARM64 doesn't encoding 2 LSB.
  record->unwind_info.unwind_info.FunctionLength = kMaxFunctionLength >> 2;

  if (remaining_size_in_bytes > 0 &&
      runtime_function_index < max_runtime_function_count) {
    ASSERT((remaining_size_in_bytes % kInstrSize) == 0);

    record->unwind_info1.unwind_info.FunctionLength = static_cast<uint32_t>(
        remaining_size_in_bytes >> kFunctionLengthShiftSize);
    record->runtime_function[runtime_function_index].BeginAddress =
        current_unwind_start_address;
    record->runtime_function[runtime_function_index].UnwindData =
        offset +
        static_cast<DWORD>(offsetof(CodeRangeUnwindingRecord, unwind_info1));

    remaining_size_in_bytes -= kMaxFunctionLength;
    record->runtime_function_count = runtime_function_index + 1;
  } else {
    record->runtime_function_count = runtime_function_index;
  }

  // 1 page can cover kMaximalCodeRangeSize for ARM64 (128MB). If
  // kMaximalCodeRangeSize is changed for ARM64 and makes 1 page insufficient to
  // cover it, more pages will need to reserved for unwind data.
  ASSERT(remaining_size_in_bytes <= 0);
#else
#error What architecture?
#endif
  record->magic = kUnwindingRecordMagic;
}

const void* UnwindingRecords::GenerateRecordsInto(intptr_t offset,
                                                  uint8_t* target_buffer) {
  CodeRangeUnwindingRecord* record =
      new (target_buffer) CodeRangeUnwindingRecord();
  InitUnwindingRecord(offset, record, offset);
  return target_buffer;
}

#endif  // (defined(DART_TARGET_OS_WINDOWS) || defined(DART_HOST_OS_WINDOWS))

#if defined(DART_HOST_OS_WINDOWS) &&                                           \
    (defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_ARM64))

// Special exception-unwinding records are put at the end of executable
// page on Windows for 64-bit applications.
void UnwindingRecords::RegisterExecutablePage(Page* page) {
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
  RELEASE_ASSERT(record->magic == kUnwindingRecordMagic);
  DWORD status = RtlAddGrowableFunctionTable(
      /*DynamicTable=*/&record->dynamic_table,
      /*FunctionTable=*/record->runtime_function,
      /*EntryCount=*/record->runtime_function_count,
      /*MaximumEntryCount=*/record->runtime_function_count,
      /*RangeBase=*/page->memory_->start(),
      /*RangeEnd=*/page->memory_->end());
  if (status != 0) {
    FATAL("Failed to add growable function table: 0x%x\n", status);
  }
}

void UnwindingRecords::UnregisterExecutablePage(Page* page) {
  ASSERT(page->is_executable() && !page->is_image());
  intptr_t unwinding_record_offset =
      page->memory_->size() - UnwindingRecordsPlatform::SizeInBytes();
  CodeRangeUnwindingRecord* record =
      reinterpret_cast<CodeRangeUnwindingRecord*>(
          reinterpret_cast<uint8_t*>(page->memory_->start()) +
          unwinding_record_offset);
  RELEASE_ASSERT(record->magic == kUnwindingRecordMagic);
  RtlDeleteGrowableFunctionTable(record->dynamic_table);
}

#endif  // defined(DART_HOST_OS_WINDOWS)

}  // namespace dart
