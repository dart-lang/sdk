// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/unwinding_records.h"

#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {

#if (defined(DART_TARGET_OS_WINDOWS) || defined(DART_HOST_OS_WINDOWS)) &&      \
    (defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_ARM64))

#if defined(TARGET_ARCH_X64)
const intptr_t kReservedUnwindingRecordsSizeBytes = 64;
#else
const intptr_t kReservedUnwindingRecordsSizeBytes = 4 * KB;
#endif

intptr_t UnwindingRecordsPlatform::SizeInBytes() {
  return kReservedUnwindingRecordsSizeBytes;
}

#endif  // defined(DART_TARGET_OS_WINDOWS) || defined(DART_HOST_OS_WINDOWS)

#if defined(DART_HOST_OS_WINDOWS) &&                                           \
    (defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_ARM64))

void UnwindingRecordsPlatform::RegisterExecutableMemory(
    void* start,
    intptr_t size,
    void** pp_dynamic_table) {
  intptr_t unwinding_record_offset = size - kReservedUnwindingRecordsSizeBytes;
  uint8_t* record_ptr = static_cast<uint8_t*>(start) + unwinding_record_offset;
  CodeRangeUnwindingRecord* record =
      reinterpret_cast<CodeRangeUnwindingRecord*>(record_ptr);
  RELEASE_ASSERT(record->magic == kUnwindingRecordMagic);
  uword start_num = reinterpret_cast<intptr_t>(start);
  uword end_num = start_num + size;
  DWORD status = RtlAddGrowableFunctionTable(
      pp_dynamic_table,
      /*FunctionTable=*/record->runtime_function,
      /*EntryCount=*/record->runtime_function_count,
      /*MaximumEntryCount=*/record->runtime_function_count,
      /*RangeBase=*/start_num,
      /*RangeEnd=*/end_num);
  if (status != 0) {
    FATAL("Failed to add growable function table: 0x%x\n", status);
  }
}

void UnwindingRecordsPlatform::UnregisterDynamicTable(void* p_dynamic_table) {
  RtlDeleteGrowableFunctionTable(p_dynamic_table);
}

#endif  // defined(DART_HOST_OS_WINDOWS)

}  // namespace dart
