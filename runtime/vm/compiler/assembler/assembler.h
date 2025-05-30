// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/compiler/assembler/object_pool_builder.h"
#include "vm/compiler/runtime_api.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"

#if defined(TARGET_ARCH_IA32)
#include "vm/compiler/assembler/assembler_ia32.h"
#elif defined(TARGET_ARCH_X64)
#include "vm/compiler/assembler/assembler_x64.h"
#elif defined(TARGET_ARCH_ARM)
#include "vm/compiler/assembler/assembler_arm.h"
#elif defined(TARGET_ARCH_ARM64)
#include "vm/compiler/assembler/assembler_arm64.h"
#elif defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
#include "vm/compiler/assembler/assembler_riscv.h"
#else
#error Unknown architecture.
#endif

namespace dart {

// Convert comparison Token::Kind to GPR comparison condition.
static inline Condition TokenKindToIntCondition(Token::Kind kind,
                                                bool is_unsigned) {
  // Use platform-independent condition names
  // declared in constant_<arch>.h on all platforms.
  switch (kind) {
    case Token::kEQ:
      return EQUAL;
    case Token::kNE:
      return NOT_EQUAL;
    case Token::kLT:
      return is_unsigned ? UNSIGNED_LESS : LESS;
    case Token::kGT:
      return is_unsigned ? UNSIGNED_GREATER : GREATER;
    case Token::kLTE:
      return is_unsigned ? UNSIGNED_LESS_EQUAL : LESS_EQUAL;
    case Token::kGTE:
      return is_unsigned ? UNSIGNED_GREATER_EQUAL : GREATER_EQUAL;
    default:
      UNREACHABLE();
      return OVERFLOW;
  }
}

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_H_
