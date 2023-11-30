// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/unwinding_records.h"

#include "platform/assert.h"
#include "platform/globals.h"

#if defined(DART_HOST_OS_WINDOWS) &&                                           \
    (defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_ARM64))

namespace dart {

static HMODULE ntdll_module;
static decltype(&::RtlAddGrowableFunctionTable)
    add_growable_function_table_func_ = nullptr;
static decltype(&::RtlDeleteGrowableFunctionTable)
    delete_growable_function_table_func_ = nullptr;

#if defined(TARGET_ARCH_X64)
const intptr_t kReservedUnwindingRecordsSizeBytes = 64;
#else
const intptr_t kReservedUnwindingRecordsSizeBytes = 4 * KB;
#endif

intptr_t UnwindingRecordsPlatform::SizeInBytes() {
  return kReservedUnwindingRecordsSizeBytes;
}

void* UnwindingRecordsPlatform::GetAddGrowableFunctionTableFunc() {
  return add_growable_function_table_func_;
}

void* UnwindingRecordsPlatform::GetDeleteGrowableFunctionTableFunc() {
  return delete_growable_function_table_func_;
}

void UnwindingRecordsPlatform::Init() {
  ntdll_module =
      LoadLibraryEx(L"ntdll.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
  ASSERT(ntdll_module != nullptr);
  // This pair of functions is not available on Windows 7.
  add_growable_function_table_func_ =
      reinterpret_cast<decltype(&::RtlAddGrowableFunctionTable)>(
          ::GetProcAddress(ntdll_module, "RtlAddGrowableFunctionTable"));
  delete_growable_function_table_func_ =
      reinterpret_cast<decltype(&::RtlDeleteGrowableFunctionTable)>(
          ::GetProcAddress(ntdll_module, "RtlDeleteGrowableFunctionTable"));
  // Either both available, or both not available.
  ASSERT((add_growable_function_table_func_ == nullptr) ==
         (delete_growable_function_table_func_ == nullptr));
}

void UnwindingRecordsPlatform::Cleanup() {
  FreeLibrary(ntdll_module);
}

void UnwindingRecordsPlatform::RegisterExecutableMemory(
    void* start,
    intptr_t size,
    void** pp_dynamic_table) {
  auto func = add_growable_function_table_func_;
  if (func == nullptr) {
    return;
  }
  intptr_t unwinding_record_offset = size - kReservedUnwindingRecordsSizeBytes;
  uint8_t* record_ptr = static_cast<uint8_t*>(start) + unwinding_record_offset;
  CodeRangeUnwindingRecord* record =
      reinterpret_cast<CodeRangeUnwindingRecord*>(record_ptr);
  uword start_num = reinterpret_cast<intptr_t>(start);
  uword end_num = start_num + size;
  DWORD status = func(pp_dynamic_table,
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
  auto func = delete_growable_function_table_func_;
  if (func == nullptr) return;
  func(p_dynamic_table);
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS)
