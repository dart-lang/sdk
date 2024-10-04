// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_TEST_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_TEST_H_

#include "vm/compiler/runtime_api.h"
#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/assembler/assembler_base.h"

namespace dart {

namespace compiler {

void EnterTestFrame(Assembler* assembler);

void LeaveTestFrame(Assembler* assembler);

// Used in AndImmediate, LslImmediate, and ArithmeticRightShiftImmediate tests.

struct RegRegImmTests : AllStatic {
  static const Register kInputReg;
  static const Register kReturnReg;

  static intptr_t And(intptr_t lhs, intptr_t rhs, OperandSize sz);
  static intptr_t Lsl(intptr_t value, intptr_t shift, OperandSize sz);
  static intptr_t Asr(intptr_t value, intptr_t shift, OperandSize sz);

  static intptr_t ExtendValue(intptr_t value, OperandSize sz);
  static intptr_t ZeroExtendValue(intptr_t value, OperandSize sz);
  static intptr_t SignExtendValue(intptr_t value, OperandSize sz);
};

const uintptr_t kRegRegImmInputs[] = {
    0,
    1,
    0x5A,
    kMaxInt8,
    static_cast<uintptr_t>(kMinInt8),
    kMaxUint8,
    kMaxUint8 + 1,
    0x5BDF,
    kMaxInt16,
    static_cast<uintptr_t>(kMinInt16),
    kMaxUint16,
    kMaxUint16 + 1,
    0x12345,
    0x579BDF13,
    kMaxInt32,
    static_cast<uintptr_t>(kMinInt32),
    kMaxUint32,
#if !defined(TARGET_ARCH_IS_32_BIT)
    kMaxUint32 + 1,
    0x123456789ABC,
    0x579BDF13579BDF13,
    kMaxInt64,
    static_cast<uintptr_t>(kMinInt64),
    kMaxUint64,
#endif
};

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_TEST_H_
