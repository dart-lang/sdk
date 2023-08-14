// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for patching compiled code.

#ifndef RUNTIME_PLATFORM_UNWINDING_RECORDS_H_
#define RUNTIME_PLATFORM_UNWINDING_RECORDS_H_

#include "platform/allocation.h"

namespace dart {

class UnwindingRecordsPlatform : public AllStatic {
 public:
  static void Init();
  static void Cleanup();

  static intptr_t SizeInBytes();

  static void RegisterExecutableMemory(void* start,
                                       intptr_t size,
                                       void** pp_dynamic_table);
  static void UnregisterDynamicTable(void* p_dynamic_table);

  static void* GetAddGrowableFunctionTableFunc();
  static void* GetDeleteGrowableFunctionTableFunc();
};

#if defined(DART_HOST_OS_WINDOWS) && defined(TARGET_ARCH_X64)

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

#endif  // defined(DART_HOST_OS_WINDOWS) && defined(TARGET_ARCH_X64)

}  // namespace dart

#endif  // RUNTIME_PLATFORM_UNWINDING_RECORDS_H_
