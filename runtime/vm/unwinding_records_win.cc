// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#include "vm/unwinding_records.h"

#if defined(DART_HOST_OS_WINDOWS) && defined(TARGET_ARCH_X64)

namespace dart {

static HMODULE ntdll_module;
static decltype(
    &::RtlAddGrowableFunctionTable) add_growable_function_table_func = nullptr;
static decltype(
    &::RtlDeleteGrowableFunctionTable) delete_growable_function_table_func =
    nullptr;

void UnwindingRecords::Init() {
  ntdll_module =
      LoadLibraryEx(L"ntdll.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
  ASSERT(ntdll_module != nullptr);
  // This pair of functions is not available on Windows 7.
  add_growable_function_table_func =
      reinterpret_cast<decltype(&::RtlAddGrowableFunctionTable)>(
          ::GetProcAddress(ntdll_module, "RtlAddGrowableFunctionTable"));
  delete_growable_function_table_func =
      reinterpret_cast<decltype(&::RtlDeleteGrowableFunctionTable)>(
          ::GetProcAddress(ntdll_module, "RtlDeleteGrowableFunctionTable"));
  // Either both available, or both not available.
  ASSERT((add_growable_function_table_func == nullptr) ==
         (delete_growable_function_table_func == nullptr));
}

void UnwindingRecords::Cleanup() {
  FreeLibrary(ntdll_module);
}

#pragma pack(push, 1)
//
// Refer to https://learn.microsoft.com/en-us/cpp/build/exception-handling-x64
//
typedef unsigned char UBYTE;
typedef union _UNWIND_CODE {
  struct {
    UBYTE CodeOffset;
    UBYTE UnwindOp : 4;
    UBYTE OpInfo : 4;
  };
  USHORT FrameOffset;
} UNWIND_CODE, *PUNWIND_CODE;

typedef struct _UNWIND_INFO {
  UBYTE Version : 3;
  UBYTE Flags : 5;
  UBYTE SizeOfProlog;
  UBYTE CountOfCodes;
  UBYTE FrameRegister : 4;
  UBYTE FrameOffset : 4;
  UNWIND_CODE UnwindCode[2];
} UNWIND_INFO, *PUNWIND_INFO;

static constexpr int kPushRbpInstructionLength = 1;
static const int kMovRbpRspInstructionLength = 3;
static constexpr int kRbpPrefixLength =
    kPushRbpInstructionLength + kMovRbpRspInstructionLength;
static constexpr int kRBP = 5;

struct GeneratedCodeUnwindInfo {
  UNWIND_INFO unwind_info;

  GeneratedCodeUnwindInfo() {
    unwind_info.Version = 1;
    unwind_info.Flags = UNW_FLAG_NHANDLER;
    unwind_info.SizeOfProlog = kRbpPrefixLength;
    unwind_info.CountOfCodes = 2;
    unwind_info.FrameRegister = kRBP;
    unwind_info.FrameOffset = 0;
    unwind_info.UnwindCode[0].CodeOffset = kRbpPrefixLength;
    unwind_info.UnwindCode[0].UnwindOp = 3;  // UWOP_SET_FPREG
    unwind_info.UnwindCode[0].OpInfo = 0;
    unwind_info.UnwindCode[1].CodeOffset = kPushRbpInstructionLength;
    unwind_info.UnwindCode[1].UnwindOp = 0;  // UWOP_PUSH_NONVOL
    unwind_info.UnwindCode[1].OpInfo = kRBP;
  }
};

struct CodeRangeUnwindingRecord {
  void* dynamic_table;
  uint32_t runtime_function_count;
  GeneratedCodeUnwindInfo unwind_info;
  intptr_t exception_handler;
  RUNTIME_FUNCTION runtime_function[1];
};

#pragma pack(pop)

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

const intptr_t kReservedUnwindingRecordsSizeBytes = 64;
COMPILE_ASSERT(kReservedUnwindingRecordsSizeBytes >
               sizeof(CodeRangeUnwindingRecord));
intptr_t UnwindingRecords::SizeInBytes() {
  return kReservedUnwindingRecordsSizeBytes;
}

// Special exception-unwinding records are put at the end of executable
// page on Windows for 64-bit applications.
void UnwindingRecords::RegisterExecutablePage(Page* page) {
  // Won't set up unwinding records on Windows 7, so users won't be able
  // to benefit from proper unhandled exceptions filtering.
  if (add_growable_function_table_func == nullptr) return;
  ASSERT(page->is_executable());
  page->top_ -= kReservedUnwindingRecordsSizeBytes;
  intptr_t unwinding_record_offset =
      page->memory_->size() - kReservedUnwindingRecordsSizeBytes;
  CodeRangeUnwindingRecord* record =
      new (reinterpret_cast<uint8_t*>(page->memory_->start()) +
           unwinding_record_offset) CodeRangeUnwindingRecord();
  InitUnwindingRecord(unwinding_record_offset, record, page->memory_->size());
  if (add_growable_function_table_func(
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
  if (delete_growable_function_table_func == nullptr) return;
  ASSERT(page->is_executable() && !page->is_image());
  intptr_t unwinding_record_offset =
      page->memory_->size() - kReservedUnwindingRecordsSizeBytes;
  CodeRangeUnwindingRecord* record =
      reinterpret_cast<CodeRangeUnwindingRecord*>(
          reinterpret_cast<uint8_t*>(page->memory_->start()) +
          unwinding_record_offset);
  delete_growable_function_table_func(record->dynamic_table);
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS)
