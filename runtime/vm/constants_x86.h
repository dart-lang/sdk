// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_X86_H_
#define RUNTIME_VM_CONSTANTS_X86_H_

#include "platform/assert.h"

namespace dart {

enum Condition {
  OVERFLOW = 0,
  NO_OVERFLOW = 1,
  BELOW = 2,
  ABOVE_EQUAL = 3,
  EQUAL = 4,
  NOT_EQUAL = 5,
  BELOW_EQUAL = 6,
  ABOVE = 7,
  SIGN = 8,
  NOT_SIGN = 9,
  PARITY_EVEN = 10,
  PARITY_ODD = 11,
  LESS = 12,
  GREATER_EQUAL = 13,
  LESS_EQUAL = 14,
  GREATER = 15,

  ZERO = EQUAL,
  NOT_ZERO = NOT_EQUAL,
  NEGATIVE = SIGN,
  POSITIVE = NOT_SIGN,
  CARRY = BELOW,
  NOT_CARRY = ABOVE_EQUAL,

  // Platform-independent variants declared for all platforms
  // EQUAL,
  // NOT_EQUAL,
  // LESS,
  // LESS_EQUAL,
  // GREATER_EQUAL,
  // GREATER,
  UNSIGNED_LESS = BELOW,
  UNSIGNED_LESS_EQUAL = BELOW_EQUAL,
  UNSIGNED_GREATER = ABOVE,
  UNSIGNED_GREATER_EQUAL = ABOVE_EQUAL,

  kInvalidCondition = 16
};

static inline Condition InvertCondition(Condition c) {
  COMPILE_ASSERT((OVERFLOW ^ NO_OVERFLOW) == 1);
  COMPILE_ASSERT((BELOW ^ ABOVE_EQUAL) == 1);
  COMPILE_ASSERT((EQUAL ^ NOT_EQUAL) == 1);
  COMPILE_ASSERT((BELOW_EQUAL ^ ABOVE) == 1);
  COMPILE_ASSERT((SIGN ^ NOT_SIGN) == 1);
  COMPILE_ASSERT((PARITY_EVEN ^ PARITY_ODD) == 1);
  COMPILE_ASSERT((LESS ^ GREATER_EQUAL) == 1);
  COMPILE_ASSERT((LESS_EQUAL ^ GREATER) == 1);
  ASSERT(c != kInvalidCondition);
  return static_cast<Condition>(c ^ 1);
}

#define X86_ZERO_OPERAND_1_BYTE_INSTRUCTIONS(F)                                \
  F(ret, 0xC3)                                                                 \
  F(leave, 0xC9)                                                               \
  F(hlt, 0xF4)                                                                 \
  F(cld, 0xFC)                                                                 \
  F(int3, 0xCC)                                                                \
  F(pushad, 0x60)                                                              \
  F(popad, 0x61)                                                               \
  F(pushfd, 0x9C)                                                              \
  F(popfd, 0x9D)                                                               \
  F(sahf, 0x9E)                                                                \
  F(cdq, 0x99)                                                                 \
  F(fwait, 0x9B)                                                               \
  F(movsb, 0xA4)                                                               \
  F(movs, 0xA5) /* Size suffix added in code */                                \
  F(cmpsb, 0xA6)                                                               \
  F(cmps, 0xA7) /* Size suffix added in code */

// clang-format off
#define X86_ALU_CODES(F)                                                       \
  F(and, 4)                                                                    \
  F(or, 1)                                                                     \
  F(xor, 6)                                                                    \
  F(add, 0)                                                                    \
  F(adc, 2)                                                                    \
  F(sub, 5)                                                                    \
  F(sbb, 3)                                                                    \
  F(cmp, 7)

#define XMM_ALU_CODES(F)                                                       \
  F(bad0, 0)                                                                   \
  F(sqrt, 1)                                                                   \
  F(rsqrt, 2)                                                                  \
  F(rcp, 3)                                                                    \
  F(and, 4)                                                                    \
  F(bad1, 5)                                                                   \
  F(or, 6)                                                                     \
  F(xor, 7)                                                                    \
  F(add, 8)                                                                    \
  F(mul, 9)                                                                    \
  F(bad2, 0xA)                                                                 \
  F(bad3, 0xB)                                                                 \
  F(sub, 0xC)                                                                  \
  F(min, 0xD)                                                                  \
  F(div, 0xE)                                                                  \
  F(max, 0xF)
// clang-format on

// Table 3-1, first part
#define XMM_CONDITIONAL_CODES(F)                                               \
  F(eq, 0)                                                                     \
  F(lt, 1)                                                                     \
  F(le, 2)                                                                     \
  F(unord, 3)                                                                  \
  F(neq, 4)                                                                    \
  F(nlt, 5)                                                                    \
  F(nle, 6)                                                                    \
  F(ord, 7)

#define X86_CONDITIONAL_SUFFIXES(F)                                            \
  F(o, OVERFLOW)                                                               \
  F(no, NO_OVERFLOW)                                                           \
  F(c, CARRY)                                                                  \
  F(nc, NOT_CARRY)                                                             \
  F(z, ZERO)                                                                   \
  F(nz, NOT_ZERO)                                                              \
  F(na, BELOW_EQUAL)                                                           \
  F(a, ABOVE)                                                                  \
  F(s, SIGN)                                                                   \
  F(ns, NOT_SIGN)                                                              \
  F(pe, PARITY_EVEN)                                                           \
  F(po, PARITY_ODD)                                                            \
  F(l, LESS)                                                                   \
  F(ge, GREATER_EQUAL)                                                         \
  F(le, LESS_EQUAL)                                                            \
  F(g, GREATER)                                                                \
  /* Some alternative names */                                                 \
  F(e, EQUAL)                                                                  \
  F(ne, NOT_EQUAL)

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_X86_H_
