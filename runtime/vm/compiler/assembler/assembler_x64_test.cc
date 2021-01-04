// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/cpu.h"
#include "vm/os.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {
namespace compiler {

#define __ assembler->

#if defined(PRODUCT)
#define EXPECT_DISASSEMBLY(expected)
#define EXPECT_DISASSEMBLY_ENDS_WITH(expected)
#define EXPECT_DISASSEMBLY_NOT_WINDOWS(expected)
#define EXPECT_DISASSEMBLY_NOT_WINDOWS_ENDS_WITH(expected)
#else
#define EXPECT_DISASSEMBLY(expected)                                           \
  EXPECT_STREQ(expected, test->BlankedDisassembly())
#define EXPECT_DISASSEMBLY_ENDS_WITH(expected_arg)                             \
  char* disassembly = test->BlankedDisassembly();                              \
  const char* expected = expected_arg;                                         \
  intptr_t dis_len = strlen(disassembly);                                      \
  intptr_t exp_len = strlen(expected);                                         \
  EXPECT_GT(dis_len, exp_len);                                                 \
  EXPECT_STREQ(expected, disassembly + dis_len - exp_len);
#if defined(TARGET_OS_WINDOWS)
// Windows has different calling conventions on x64, which means the
// disassembly looks different on some tests.  We skip testing the
// disassembly output for those tests on Windows.
#define EXPECT_DISASSEMBLY_NOT_WINDOWS(expected)
#define EXPECT_DISASSEMBLY_NOT_WINDOWS_ENDS_WITH(expected)
#else
#define EXPECT_DISASSEMBLY_NOT_WINDOWS(expected) EXPECT_DISASSEMBLY(expected)
#define EXPECT_DISASSEMBLY_NOT_WINDOWS_ENDS_WITH(expected)                     \
  EXPECT_DISASSEMBLY_ENDS_WITH(expected)
#endif
#endif

ASSEMBLER_TEST_GENERATE(ReadArgument, assembler) {
  __ pushq(CallingConventions::kArg1Reg);
  __ movq(RAX, Address(RSP, 0));
  __ popq(RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(ReadArgument, test) {
  typedef int64_t (*ReadArgumentCode)(int64_t n);
  ReadArgumentCode id = reinterpret_cast<ReadArgumentCode>(test->entry());
  EXPECT_EQ(42, id(42));
  EXPECT_EQ(87, id(87));
  static const int64_t kLargeConstant = 0x1234567812345678LL;
  EXPECT_EQ(kLargeConstant, id(kLargeConstant));
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rdi\n"
      "movq rax,[rsp]\n"
      "pop rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AddressingModes, assembler) {
  __ movq(RAX, Address(RSP, 0));
  __ movq(RAX, Address(RBP, 0));
  __ movq(RAX, Address(RAX, 0));
  __ movq(RAX, Address(R10, 0));
  __ movq(RAX, Address(R12, 0));
  __ movq(RAX, Address(R13, 0));
  __ movq(R10, Address(RAX, 0));

  __ movq(RAX, Address(RSP, target::kWordSize));
  __ movq(RAX, Address(RBP, target::kWordSize));
  __ movq(RAX, Address(RAX, target::kWordSize));
  __ movq(RAX, Address(R10, target::kWordSize));
  __ movq(RAX, Address(R12, target::kWordSize));
  __ movq(RAX, Address(R13, target::kWordSize));

  __ movq(RAX, Address(RSP, -target::kWordSize));
  __ movq(RAX, Address(RBP, -target::kWordSize));
  __ movq(RAX, Address(RAX, -target::kWordSize));
  __ movq(RAX, Address(R10, -target::kWordSize));
  __ movq(RAX, Address(R12, -target::kWordSize));
  __ movq(RAX, Address(R13, -target::kWordSize));

  __ movq(RAX, Address(RSP, 256 * target::kWordSize));
  __ movq(RAX, Address(RBP, 256 * target::kWordSize));
  __ movq(RAX, Address(RAX, 256 * target::kWordSize));
  __ movq(RAX, Address(R10, 256 * target::kWordSize));
  __ movq(RAX, Address(R12, 256 * target::kWordSize));
  __ movq(RAX, Address(R13, 256 * target::kWordSize));

  __ movq(RAX, Address(RSP, -256 * target::kWordSize));
  __ movq(RAX, Address(RBP, -256 * target::kWordSize));
  __ movq(RAX, Address(RAX, -256 * target::kWordSize));
  __ movq(RAX, Address(R10, -256 * target::kWordSize));
  __ movq(RAX, Address(R12, -256 * target::kWordSize));
  __ movq(RAX, Address(R13, -256 * target::kWordSize));

  __ movq(RAX, Address(RAX, TIMES_1, 0));
  __ movq(RAX, Address(RAX, TIMES_2, 0));
  __ movq(RAX, Address(RAX, TIMES_4, 0));
  __ movq(RAX, Address(RAX, TIMES_8, 0));

  __ movq(RAX, Address(RBP, TIMES_2, 0));
  __ movq(RAX, Address(RAX, TIMES_2, 0));
  __ movq(RAX, Address(R10, TIMES_2, 0));
  __ movq(RAX, Address(R12, TIMES_2, 0));
  __ movq(RAX, Address(R13, TIMES_2, 0));

  __ movq(RAX, Address(RBP, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(RAX, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R10, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R12, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R13, TIMES_2, target::kWordSize));

  __ movq(RAX, Address(RBP, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(RAX, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R10, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R12, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R13, TIMES_2, 256 * target::kWordSize));

  __ movq(RAX, Address(RAX, RBP, TIMES_2, 0));
  __ movq(RAX, Address(RAX, RAX, TIMES_2, 0));
  __ movq(RAX, Address(RAX, R10, TIMES_2, 0));
  __ movq(RAX, Address(RAX, R12, TIMES_2, 0));
  __ movq(RAX, Address(RAX, R13, TIMES_2, 0));

  __ movq(RAX, Address(RBP, RBP, TIMES_2, 0));
  __ movq(RAX, Address(RBP, RAX, TIMES_2, 0));
  __ movq(RAX, Address(RBP, R10, TIMES_2, 0));
  __ movq(RAX, Address(RBP, R12, TIMES_2, 0));
  __ movq(RAX, Address(RBP, R13, TIMES_2, 0));

  __ movq(RAX, Address(RSP, RBP, TIMES_2, 0));
  __ movq(RAX, Address(RSP, RAX, TIMES_2, 0));
  __ movq(RAX, Address(RSP, R10, TIMES_2, 0));
  __ movq(RAX, Address(RSP, R12, TIMES_2, 0));
  __ movq(RAX, Address(RSP, R13, TIMES_2, 0));

  __ movq(RAX, Address(R10, RBP, TIMES_2, 0));
  __ movq(RAX, Address(R10, RAX, TIMES_2, 0));
  __ movq(RAX, Address(R10, R10, TIMES_2, 0));
  __ movq(RAX, Address(R10, R12, TIMES_2, 0));
  __ movq(RAX, Address(R10, R13, TIMES_2, 0));

  __ movq(RAX, Address(R12, RBP, TIMES_2, 0));
  __ movq(RAX, Address(R12, RAX, TIMES_2, 0));
  __ movq(RAX, Address(R12, R10, TIMES_2, 0));
  __ movq(RAX, Address(R12, R12, TIMES_2, 0));
  __ movq(RAX, Address(R12, R13, TIMES_2, 0));

  __ movq(RAX, Address(R13, RBP, TIMES_2, 0));
  __ movq(RAX, Address(R13, RAX, TIMES_2, 0));
  __ movq(RAX, Address(R13, R10, TIMES_2, 0));
  __ movq(RAX, Address(R13, R12, TIMES_2, 0));
  __ movq(RAX, Address(R13, R13, TIMES_2, 0));

  __ movq(RAX, Address(RAX, RBP, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(RAX, RAX, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(RAX, R10, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(RAX, R12, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(RAX, R13, TIMES_2, target::kWordSize));

  __ movq(RAX, Address(RBP, RBP, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(RBP, RAX, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(RBP, R10, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(RBP, R12, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(RBP, R13, TIMES_2, target::kWordSize));

  __ movq(RAX, Address(RSP, RBP, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(RSP, RAX, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(RSP, R10, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(RSP, R12, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(RSP, R13, TIMES_2, target::kWordSize));

  __ movq(RAX, Address(R10, RBP, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R10, RAX, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R10, R10, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R10, R12, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R10, R13, TIMES_2, target::kWordSize));

  __ movq(RAX, Address(R12, RBP, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R12, RAX, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R12, R10, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R12, R12, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R12, R13, TIMES_2, target::kWordSize));

  __ movq(RAX, Address(R13, RBP, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R13, RAX, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R13, R10, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R13, R12, TIMES_2, target::kWordSize));
  __ movq(RAX, Address(R13, R13, TIMES_2, target::kWordSize));

  __ movq(RAX, Address(RAX, RBP, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(RAX, RAX, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(RAX, R10, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(RAX, R12, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(RAX, R13, TIMES_2, 256 * target::kWordSize));

  __ movq(RAX, Address(RBP, RBP, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(RBP, RAX, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(RBP, R10, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(RBP, R12, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(RBP, R13, TIMES_2, 256 * target::kWordSize));

  __ movq(RAX, Address(RSP, RBP, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(RSP, RAX, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(RSP, R10, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(RSP, R12, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(RSP, R13, TIMES_2, 256 * target::kWordSize));

  __ movq(RAX, Address(R10, RBP, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R10, RAX, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R10, R10, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R10, R12, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R10, R13, TIMES_2, 256 * target::kWordSize));

  __ movq(RAX, Address(R12, RBP, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R12, RAX, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R12, R10, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R12, R12, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R12, R13, TIMES_2, 256 * target::kWordSize));

  __ movq(RAX, Address(R13, RBP, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R13, RAX, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R13, R10, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R13, R12, TIMES_2, 256 * target::kWordSize));
  __ movq(RAX, Address(R13, R13, TIMES_2, 256 * target::kWordSize));

  __ movq(RAX, Address::AddressBaseImm32(RSP, 0));
  __ movq(RAX, Address::AddressBaseImm32(RBP, 0));
  __ movq(RAX, Address::AddressBaseImm32(RAX, 0));
  __ movq(RAX, Address::AddressBaseImm32(R10, 0));
  __ movq(RAX, Address::AddressBaseImm32(R12, 0));
  __ movq(RAX, Address::AddressBaseImm32(R13, 0));
  __ movq(R10, Address::AddressBaseImm32(RAX, 0));

  __ movq(RAX, Address::AddressBaseImm32(RSP, target::kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(RBP, target::kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(RAX, target::kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(R10, target::kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(R12, target::kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(R13, target::kWordSize));

  __ movq(RAX, Address::AddressBaseImm32(RSP, -target::kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(RBP, -target::kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(RAX, -target::kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(R10, -target::kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(R12, -target::kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(R13, -target::kWordSize));
}

ASSEMBLER_TEST_RUN(AddressingModes, test) {
  // Avoid running the code since it is constructed to lead to crashes.
  EXPECT_DISASSEMBLY(
      "movq rax,[rsp]\n"
      "movq rax,[rbp+0]\n"
      "movq rax,[rax]\n"
      "movq rax,[r10]\n"
      "movq rax,[r12]\n"
      "movq rax,[r13+0]\n"
      "movq r10,[rax]\n"
      "movq rax,[rsp+0x8]\n"
      "movq rax,[rbp+0x8]\n"
      "movq rax,[rax+0x8]\n"
      "movq rax,[r10+0x8]\n"
      "movq rax,[r12+0x8]\n"
      "movq rax,[r13+0x8]\n"
      "movq rax,[rsp-0x8]\n"
      "movq rax,[rbp-0x8]\n"
      "movq rax,[rax-0x8]\n"
      "movq rax,[r10-0x8]\n"
      "movq rax,[r12-0x8]\n"
      "movq rax,[r13-0x8]\n"
      "movq rax,[rsp+0x...]\n"
      "movq rax,[rbp+0x...]\n"
      "movq rax,[rax+0x...]\n"
      "movq rax,[r10+0x...]\n"
      "movq rax,[r12+0x...]\n"
      "movq rax,[r13+0x...]\n"
      "movq rax,[rsp-0x...]\n"
      "movq rax,[rbp-0x...]\n"
      "movq rax,[rax-0x...]\n"
      "movq rax,[r10-0x...]\n"
      "movq rax,[r12-0x...]\n"
      "movq rax,[r13-0x...]\n"
      "movq rax,[rax*1+0]\n"
      "movq rax,[rax*2+0]\n"
      "movq rax,[rax*4+0]\n"
      "movq rax,[rax*8+0]\n"
      "movq rax,[rbp*2+0]\n"
      "movq rax,[rax*2+0]\n"
      "movq rax,[r10*2+0]\n"
      "movq rax,[r12*2+0]\n"
      "movq rax,[r13*2+0]\n"
      "movq rax,[rbp*2+0x8]\n"
      "movq rax,[rax*2+0x8]\n"
      "movq rax,[r10*2+0x8]\n"
      "movq rax,[r12*2+0x8]\n"
      "movq rax,[r13*2+0x8]\n"
      "movq rax,[rbp*2+0x...]\n"
      "movq rax,[rax*2+0x...]\n"
      "movq rax,[r10*2+0x...]\n"
      "movq rax,[r12*2+0x...]\n"
      "movq rax,[r13*2+0x...]\n"
      "movq rax,[rax+rbp*2]\n"
      "movq rax,[rax+rax*2]\n"
      "movq rax,[rax+r10*2]\n"
      "movq rax,[rax+r12*2]\n"
      "movq rax,[rax+r13*2]\n"
      "movq rax,[rbp+rbp*2+0]\n"
      "movq rax,[rbp+rax*2+0]\n"
      "movq rax,[rbp+r10*2+0]\n"
      "movq rax,[rbp+r12*2+0]\n"
      "movq rax,[rbp+r13*2+0]\n"
      "movq rax,[rsp+rbp*2]\n"
      "movq rax,[rsp+rax*2]\n"
      "movq rax,[rsp+r10*2]\n"
      "movq rax,[rsp+r12*2]\n"
      "movq rax,[rsp+r13*2]\n"
      "movq rax,[r10+rbp*2]\n"
      "movq rax,[r10+rax*2]\n"
      "movq rax,[r10+r10*2]\n"
      "movq rax,[r10+r12*2]\n"
      "movq rax,[r10+r13*2]\n"
      "movq rax,[r12+rbp*2]\n"
      "movq rax,[r12+rax*2]\n"
      "movq rax,[r12+r10*2]\n"
      "movq rax,[r12+r12*2]\n"
      "movq rax,[r12+r13*2]\n"
      "movq rax,[r13+rbp*2+0]\n"
      "movq rax,[r13+rax*2+0]\n"
      "movq rax,[r13+r10*2+0]\n"
      "movq rax,[r13+r12*2+0]\n"
      "movq rax,[r13+r13*2+0]\n"
      "movq rax,[rax+rbp*2+0x8]\n"
      "movq rax,[rax+rax*2+0x8]\n"
      "movq rax,[rax+r10*2+0x8]\n"
      "movq rax,[rax+r12*2+0x8]\n"
      "movq rax,[rax+r13*2+0x8]\n"
      "movq rax,[rbp+rbp*2+0x8]\n"
      "movq rax,[rbp+rax*2+0x8]\n"
      "movq rax,[rbp+r10*2+0x8]\n"
      "movq rax,[rbp+r12*2+0x8]\n"
      "movq rax,[rbp+r13*2+0x8]\n"
      "movq rax,[rsp+rbp*2+0x8]\n"
      "movq rax,[rsp+rax*2+0x8]\n"
      "movq rax,[rsp+r10*2+0x8]\n"
      "movq rax,[rsp+r12*2+0x8]\n"
      "movq rax,[rsp+r13*2+0x8]\n"
      "movq rax,[r10+rbp*2+0x8]\n"
      "movq rax,[r10+rax*2+0x8]\n"
      "movq rax,[r10+r10*2+0x8]\n"
      "movq rax,[r10+r12*2+0x8]\n"
      "movq rax,[r10+r13*2+0x8]\n"
      "movq rax,[r12+rbp*2+0x8]\n"
      "movq rax,[r12+rax*2+0x8]\n"
      "movq rax,[r12+r10*2+0x8]\n"
      "movq rax,[r12+r12*2+0x8]\n"
      "movq rax,[r12+r13*2+0x8]\n"
      "movq rax,[r13+rbp*2+0x8]\n"
      "movq rax,[r13+rax*2+0x8]\n"
      "movq rax,[r13+r10*2+0x8]\n"
      "movq rax,[r13+r12*2+0x8]\n"
      "movq rax,[r13+r13*2+0x8]\n"
      "movq rax,[rax+rbp*2+0x...]\n"
      "movq rax,[rax+rax*2+0x...]\n"
      "movq rax,[rax+r10*2+0x...]\n"
      "movq rax,[rax+r12*2+0x...]\n"
      "movq rax,[rax+r13*2+0x...]\n"
      "movq rax,[rbp+rbp*2+0x...]\n"
      "movq rax,[rbp+rax*2+0x...]\n"
      "movq rax,[rbp+r10*2+0x...]\n"
      "movq rax,[rbp+r12*2+0x...]\n"
      "movq rax,[rbp+r13*2+0x...]\n"
      "movq rax,[rsp+rbp*2+0x...]\n"
      "movq rax,[rsp+rax*2+0x...]\n"
      "movq rax,[rsp+r10*2+0x...]\n"
      "movq rax,[rsp+r12*2+0x...]\n"
      "movq rax,[rsp+r13*2+0x...]\n"
      "movq rax,[r10+rbp*2+0x...]\n"
      "movq rax,[r10+rax*2+0x...]\n"
      "movq rax,[r10+r10*2+0x...]\n"
      "movq rax,[r10+r12*2+0x...]\n"
      "movq rax,[r10+r13*2+0x...]\n"
      "movq rax,[r12+rbp*2+0x...]\n"
      "movq rax,[r12+rax*2+0x...]\n"
      "movq rax,[r12+r10*2+0x...]\n"
      "movq rax,[r12+r12*2+0x...]\n"
      "movq rax,[r12+r13*2+0x...]\n"
      "movq rax,[r13+rbp*2+0x...]\n"
      "movq rax,[r13+rax*2+0x...]\n"
      "movq rax,[r13+r10*2+0x...]\n"
      "movq rax,[r13+r12*2+0x...]\n"
      "movq rax,[r13+r13*2+0x...]\n"
      "movq rax,[rsp+0]\n"
      "movq rax,[rbp+0]\n"
      "movq rax,[rax+0]\n"
      "movq rax,[r10+0]\n"
      "movq rax,[r12+0]\n"
      "movq rax,[r13+0]\n"
      "movq r10,[rax+0]\n"
      "movq rax,[rsp+0x8]\n"
      "movq rax,[rbp+0x8]\n"
      "movq rax,[rax+0x8]\n"
      "movq rax,[r10+0x8]\n"
      "movq rax,[r12+0x8]\n"
      "movq rax,[r13+0x8]\n"
      "movq rax,[rsp-0x8]\n"
      "movq rax,[rbp-0x8]\n"
      "movq rax,[rax-0x8]\n"
      "movq rax,[r10-0x8]\n"
      "movq rax,[r12-0x8]\n"
      "movq rax,[r13-0x8]\n");
}

ASSEMBLER_TEST_GENERATE(JumpAroundCrash, assembler) {
  Label done;
  // Make sure all the condition jumps work.
  for (Condition condition = OVERFLOW; condition <= GREATER;
       condition = static_cast<Condition>(condition + 1)) {
    __ j(condition, &done);
  }
  // This isn't strictly necessary, but we do an unconditional
  // jump around the crashing code anyway.
  __ jmp(&done);

  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);

  __ Bind(&done);
  __ ret();
}

ASSEMBLER_TEST_RUN(JumpAroundCrash, test) {
  Instr* instr = Instr::At(test->entry());
  EXPECT(!instr->IsBreakPoint());
  typedef void (*JumpAroundCrashCode)();
  reinterpret_cast<JumpAroundCrashCode>(test->entry())();
  EXPECT_DISASSEMBLY(
      "jo 0x................\n"
      "jno 0x................\n"
      "jc 0x................\n"
      "jnc 0x................\n"
      "jz 0x................\n"
      "jnz 0x................\n"
      "jna 0x................\n"
      "ja 0x................\n"
      "js 0x................\n"
      "jns 0x................\n"
      "jpe 0x................\n"
      "jpo 0x................\n"
      "jl 0x................\n"
      "jge 0x................\n"
      "jle 0x................\n"
      "jg 0x................\n"
      "jmp 0x................\n"
      "movl rax,0\n"
      "movq [rax],rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SimpleLoop, assembler) {
  __ movq(RAX, Immediate(0));
  __ movq(RCX, Immediate(0));
  Label loop;
  __ Bind(&loop);
  __ addq(RAX, Immediate(2));
  __ incq(RCX);
  __ cmpq(RCX, Immediate(87));
  __ j(LESS, &loop);
  __ ret();
}

ASSEMBLER_TEST_RUN(SimpleLoop, test) {
  typedef int (*SimpleLoopCode)();
  EXPECT_EQ(2 * 87, reinterpret_cast<SimpleLoopCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,0\n"
      "movl rcx,0\n"
      "addq rax,2\n"
      "incq rcx\n"
      "cmpq rcx,0x57\n"
      "jl 0x................\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Cmpb, assembler) {
  Label done;
  __ movq(RAX, Immediate(1));
  __ pushq(Immediate(0xffffff11));
  __ cmpb(Address(RSP, 0), Immediate(0x11));
  __ j(EQUAL, &done, Assembler::kNearJump);
  __ movq(RAX, Immediate(0));
  __ Bind(&done);
  __ popq(RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Cmpb, test) {
  typedef int (*CmpbCode)();
  EXPECT_EQ(1, reinterpret_cast<CmpbCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,1\n"
      "movl r11,0x........\n"
      "push r11\n"
      "cmpb [rsp],0x11\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "pop rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Testb, assembler) {
  Label done;
  __ movq(RAX, Immediate(1));
  __ movq(RCX, Immediate(0));
  __ pushq(Immediate(0xffffff11));
  __ testb(Address(RSP, 0), Immediate(0x10));
  // Fail if zero flag set.
  __ cmoveq(RAX, RCX);
  __ testb(Address(RSP, 0), Immediate(0x20));
  // Fail if zero flag not set.
  __ j(ZERO, &done);
  __ movq(RAX, Immediate(0));
  __ Bind(&done);
  __ popq(RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Testb, test) {
  typedef int (*TestbCode)();
  EXPECT_EQ(1, reinterpret_cast<TestbCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,1\n"
      "movl rcx,0\n"
      "movl r11,0x........\n"
      "push r11\n"
      "testb [rsp],0x10\n"
      "cmovzq rax,rcx\n"
      "testb [rsp],0x20\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "pop rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Testb2, assembler) {
  Label done, ok1, ok2, ok3, ok4, ok5, ok6, ok7;

  __ movq(RAX, Immediate(0xffffefff));
  __ bsrq(RCX, RAX);
  __ cmpq(RCX, Immediate(31));
  __ j(EQUAL, &ok1);
  __ int3();
  __ Bind(&ok1);

  __ sarq(RAX, Immediate(1));
  __ cmpq(RAX, Immediate(0x7ffff7ff));
  __ j(EQUAL, &ok2);
  __ int3();
  __ Bind(&ok2);

  __ movq(RAX, Immediate(0x7fffffff));
  __ bsrq(RCX, RAX);
  __ cmpq(RCX, Immediate(30));
  __ j(EQUAL, &ok3);
  __ int3();
  __ Bind(&ok3);

  __ cmpq(RAX, Immediate(0x7fffffff));
  __ j(EQUAL, &ok4);
  __ int3();
  __ Bind(&ok4);

  __ movq(RAX, Immediate(0x101020408));
  __ andq(RAX, Immediate(0xffffffff));
  __ cmpq(RAX, Immediate(0x1020408));
  __ j(EQUAL, &ok5);
  __ int3();
  __ Bind(&ok5);

  __ movq(RCX, Immediate(0x101020408));
  __ andq(RCX, Immediate(0xffffffff));
  __ cmpq(RCX, Immediate(0x1020408));
  __ j(EQUAL, &ok6);
  __ int3();
  __ Bind(&ok6);

  __ movq(RAX, Immediate(0x0fffeff0));
  __ bsfq(RCX, RAX);
  __ cmpq(RCX, Immediate(4));
  __ j(EQUAL, &ok7);
  __ int3();
  __ Bind(&ok7);

  __ movq(RAX, Immediate(42));
  __ ret();
}

ASSEMBLER_TEST_RUN(Testb2, test) {
  typedef int64_t (*Testb2Code)();
  EXPECT_EQ(42, reinterpret_cast<Testb2Code>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "bsrq rcx,rax\n"
      "cmpq rcx,0x1f\n"
      "jz 0x................\n"
      "int3\n"

      "sarq rax,1\n"
      "cmpq rax,0x........\n"
      "jz 0x................\n"
      "int3\n"

      "movl rax,0x........\n"
      "bsrq rcx,rax\n"
      "cmpq rcx,0x1e\n"
      "jz 0x................\n"
      "int3\n"

      "cmpq rax,0x........\n"
      "jz 0x................\n"
      "int3\n"

      "movq rax,0x................\n"
      "andl rax,0x........\n"
      "cmpq rax,0x........\n"
      "jz 0x................\n"
      "int3\n"

      "movq rcx,0x................\n"
      "andl rcx,0x........\n"
      "cmpq rcx,0x........\n"
      "jz 0x................\n"
      "int3\n"

      "movl rax,0x........\n"
      "bsfq rcx,rax\n"
      "cmpq rcx,4\n"
      "jz 0x................\n"
      "int3\n"

      "movl rax,0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Testb3, assembler) {
  Label zero;
  __ pushq(CallingConventions::kArg1Reg);
  __ movq(RDX, Immediate(0x10));
  __ testb(Address(RSP, 0), RDX);
  __ j(ZERO, &zero);
  __ movq(RAX, Immediate(1));
  __ popq(RCX);
  __ ret();
  __ Bind(&zero);
  __ movq(RAX, Immediate(0));
  __ popq(RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Testb3, test) {
  typedef int (*TestbCode)(int);
  EXPECT_EQ(1, reinterpret_cast<TestbCode>(test->entry())(0x11));
  EXPECT_EQ(0, reinterpret_cast<TestbCode>(test->entry())(0x101));
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rdi\n"
      "movl rdx,0x10\n"
      "testb rdx,[rsp]\n"
      "jz 0x................\n"
      "movl rax,1\n"
      "pop rcx\n"
      "ret\n"
      "movl rax,0\n"
      "pop rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Popcnt, assembler) {
  __ movq(RCX, Immediate(-1));
  __ popcntq(RAX, RCX);
  __ movq(RCX, Immediate(0xf));
  __ popcntq(RCX, RCX);
  __ addq(RAX, RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Popcnt, test) {
  if (!HostCPUFeatures::popcnt_supported()) {
    return;
  }
  typedef int64_t (*PopcntCode)();
  EXPECT_EQ(68, reinterpret_cast<PopcntCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movq rcx,-1\n"
      "popcntq rax,rcx\n"
      "movl rcx,0xf\n"
      "popcntq rcx,rcx\n"
      "addq rax,rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Lzcnt, assembler) {
  __ movq(RCX, Immediate(0x0f00));
  __ lzcntq(RAX, RCX);
  __ movq(RCX, Immediate(0x00f0));
  __ lzcntq(RCX, RCX);
  __ addq(RAX, RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Lzcnt, test) {
  if (!HostCPUFeatures::abm_supported()) {
    return;
  }
  typedef int64_t (*LzcntCode)();
  EXPECT_EQ(108, reinterpret_cast<LzcntCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rcx,0x...\n"
      "lzcntq rax,rcx\n"
      "movl rcx,0xf0\n"
      "lzcntq rcx,rcx\n"
      "addq rax,rcx\n"
      "ret\n");
}

struct JumpAddress {
  uword filler1;
  uword filler2;
  uword filler3;
  uword filler4;
  uword filler5;
  uword target;
  uword filler6;
  uword filler7;
  uword filler8;
};
static JumpAddress jump_address;
static uword jump_address_offset;

ASSEMBLER_TEST_GENERATE(JumpAddress, assembler) {
  __ jmp(Address(CallingConventions::kArg1Reg, OFFSET_OF(JumpAddress, target)));
  __ int3();
  __ int3();
  __ int3();
  __ int3();
  __ int3();
  jump_address_offset = __ CodeSize();
  __ movl(RAX, Immediate(42));
  __ ret();
}

ASSEMBLER_TEST_RUN(JumpAddress, test) {
  memset(&jump_address, 0, sizeof(jump_address));
  jump_address.target = test->entry() + jump_address_offset;

  typedef int (*TestCode)(void*);
  EXPECT_EQ(42, reinterpret_cast<TestCode>(test->entry())(&jump_address));
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "jmp [rdi+0x28]\n"
      "int3\n"
      "int3\n"
      "int3\n"
      "int3\n"
      "int3\n"
      "movl rax,0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Increment, assembler) {
  __ movq(RAX, Immediate(0));
  __ pushq(RAX);
  __ incl(Address(RSP, 0));
  __ incq(Address(RSP, 0));
  __ movq(RCX, Address(RSP, 0));
  __ incq(RCX);
  __ popq(RAX);
  __ movq(RAX, RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Increment, test) {
  typedef int (*IncrementCode)();
  EXPECT_EQ(3, reinterpret_cast<IncrementCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,0\n"
      "push rax\n"
      "incl [rsp]\n"
      "incq [rsp]\n"
      "movq rcx,[rsp]\n"
      "incq rcx\n"
      "pop rax\n"
      "movq rax,rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(IncrementLong, assembler) {
  __ movq(RAX, Immediate(0xffffffff));
  __ pushq(RAX);
  __ incq(Address(RSP, 0));
  __ movq(RCX, Address(RSP, 0));
  __ incq(RCX);
  __ popq(RAX);
  __ movq(RAX, RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(IncrementLong, test) {
  typedef int64_t (*IncrementCodeLong)();
  EXPECT_EQ(0x100000001, reinterpret_cast<IncrementCodeLong>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "push rax\n"
      "incq [rsp]\n"
      "movq rcx,[rsp]\n"
      "incq rcx\n"
      "pop rax\n"
      "movq rax,rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Decrement, assembler) {
  __ movq(RAX, Immediate(3));
  __ pushq(RAX);
  __ decl(Address(RSP, 0));
  __ decq(Address(RSP, 0));
  __ movq(RCX, Address(RSP, 0));
  __ decq(RCX);
  __ popq(RAX);
  __ movq(RAX, RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Decrement, test) {
  typedef int (*DecrementCode)();
  EXPECT_EQ(0, reinterpret_cast<DecrementCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,3\n"
      "push rax\n"
      "decl [rsp]\n"
      "decq [rsp]\n"
      "movq rcx,[rsp]\n"
      "decq rcx\n"
      "pop rax\n"
      "movq rax,rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(DecrementLong, assembler) {
  __ movq(RAX, Immediate(0x100000001));
  __ pushq(RAX);
  __ decq(Address(RSP, 0));
  __ movq(RCX, Address(RSP, 0));
  __ decq(RCX);
  __ popq(RAX);
  __ movq(RAX, RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(DecrementLong, test) {
  typedef int64_t (*DecrementCodeLong)();
  EXPECT_EQ(0xffffffff, reinterpret_cast<DecrementCodeLong>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "push rax\n"
      "decq [rsp]\n"
      "movq rcx,[rsp]\n"
      "decq rcx\n"
      "pop rax\n"
      "movq rax,rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SignedMultiply, assembler) {
  __ movl(RAX, Immediate(2));
  __ movl(RCX, Immediate(4));
  __ imull(RAX, RCX);
  __ imull(RAX, Immediate(1000));
  __ ret();
}

ASSEMBLER_TEST_RUN(SignedMultiply, test) {
  typedef int (*SignedMultiply)();
  EXPECT_EQ(8000, reinterpret_cast<SignedMultiply>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,2\n"
      "movl rcx,4\n"
      "imull rax,rcx\n"
      "imull rax,rax,0x...\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(UnsignedMultiply, assembler) {
  __ movl(RAX, Immediate(-1));  // RAX = 0xFFFFFFFF
  __ movl(RCX, Immediate(16));  // RCX = 0x10
  __ mull(RCX);                 // RDX:RAX = RAX * RCX = 0x0FFFFFFFF0
  __ movq(RAX, RDX);            // Return high32(0x0FFFFFFFF0) == 0x0F
  __ ret();
}

ASSEMBLER_TEST_RUN(UnsignedMultiply, test) {
  typedef int (*UnsignedMultiply)();
  EXPECT_EQ(15, reinterpret_cast<UnsignedMultiply>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,-1\n"
      "movl rcx,0x10\n"
      "mull (rax,rdx),rcx\n"
      "movq rax,rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SignedMultiply64Implicit, assembler) {
  __ movq(RAX, Immediate(7));
  __ movq(RDX, Immediate(-3));
  __ imulq(RDX);  // // RDX:RAX = -21
  __ addq(RAX, RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SignedMultiply64Implicit, test) {
  typedef int (*SignedMultiply64Implicit)();
  EXPECT_EQ(-22, reinterpret_cast<SignedMultiply64Implicit>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,7\n"
      "movq rdx,-3\n"
      "imulq (rax,rdx),rdx\n"
      "addq rax,rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SignedMultiply64, assembler) {
  __ pushq(R15);  // Callee saved.
  __ movq(RAX, Immediate(2));
  __ movq(RCX, Immediate(4));
  __ imulq(RAX, RCX);

  __ movq(R8, Immediate(2));
  __ movq(R9, Immediate(4));
  __ pushq(R9);
  __ imulq(R8, Address(RSP, 0));
  __ popq(R9);
  __ addq(RAX, R8);

  __ movq(R10, Immediate(2));
  __ movq(R11, Immediate(4));
  __ imulq(R10, R11);
  __ addq(RAX, R10);

  __ movq(R15, Immediate(2));
  __ imulq(R15, Immediate(4));
  __ addq(RAX, R15);
  __ popq(R15);
  __ ret();
}

ASSEMBLER_TEST_RUN(SignedMultiply64, test) {
  typedef int64_t (*SignedMultiply64)();
  EXPECT_EQ(32, reinterpret_cast<SignedMultiply64>(test->entry())());
  EXPECT_DISASSEMBLY(
      "push pp\n"
      "movl rax,2\n"
      "movl rcx,4\n"
      "imulq rax,rcx\n"
      "movl r8,2\n"
      "movl r9,4\n"
      "push r9\n"
      "imulq r8,[rsp]\n"
      "pop r9\n"
      "addq rax,r8\n"
      "movl r10,2\n"
      "movl r11,4\n"
      "imulq r10,r11\n"
      "addq rax,r10\n"
      "movl pp,2\n"
      "imulq pp,pp,4\n"
      "addq rax,pp\n"
      "pop pp\n"
      "ret\n");
}

static const int64_t kLargeConstant = 0x1234567887654321;
static const int64_t kAnotherLargeConstant = 987654321987654321LL;
static const int64_t kProductLargeConstants = 0x5bbb29a7f52fbbd1;

ASSEMBLER_TEST_GENERATE(SignedMultiplyLong, assembler) {
  Label done;
  __ movq(RAX, Immediate(kLargeConstant));
  __ movq(RCX, Immediate(kAnotherLargeConstant));
  __ imulq(RAX, RCX);
  __ MulImmediate(RCX, Immediate(kLargeConstant));
  __ cmpq(RAX, RCX);
  __ j(EQUAL, &done);
  __ int3();
  __ Bind(&done);
  __ ret();
}

ASSEMBLER_TEST_RUN(SignedMultiplyLong, test) {
  typedef int64_t (*SignedMultiplyLong)();
  EXPECT_EQ(kProductLargeConstants,
            reinterpret_cast<SignedMultiplyLong>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "movq rcx,0x................\n"
      "imulq rax,rcx\n"
      "movq r11,0x................\n"
      "imulq rcx,r11\n"
      "cmpq rax,rcx\n"
      "jz 0x................\n"
      "int3\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(OverflowSignedMultiply, assembler) {
  __ movl(RDX, Immediate(0));
  __ movl(RAX, Immediate(0x0fffffff));
  __ movl(RCX, Immediate(0x0fffffff));
  __ imull(RAX, RCX);
  __ imull(RAX, RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(OverflowSignedMultiply, test) {
  typedef int (*OverflowSignedMultiply)();
  EXPECT_EQ(0, reinterpret_cast<OverflowSignedMultiply>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rdx,0\n"
      "movl rax,0x........\n"
      "movl rcx,0x........\n"
      "imull rax,rcx\n"
      "imull rax,rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SignedMultiply1, assembler) {
  __ movl(RDX, Immediate(2));
  __ movl(RCX, Immediate(4));
  __ imull(RDX, RCX);
  __ imull(RDX, Immediate(1000));
  __ movl(RAX, RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SignedMultiply1, test) {
  typedef int (*SignedMultiply1)();
  EXPECT_EQ(8000, reinterpret_cast<SignedMultiply1>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rdx,2\n"
      "movl rcx,4\n"
      "imull rdx,rcx\n"
      "imull rdx,rdx,0x...\n"
      "movl rax,rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SignedMultiply2, assembler) {
  __ pushq(R15);  // Callee saved.
  __ movl(R15, Immediate(2));
  __ imull(R15, Immediate(1000));
  __ movl(RAX, R15);
  __ popq(R15);
  __ ret();
}

ASSEMBLER_TEST_RUN(SignedMultiply2, test) {
  typedef int (*SignedMultiply2)();
  EXPECT_EQ(2000, reinterpret_cast<SignedMultiply2>(test->entry())());
  EXPECT_DISASSEMBLY(
      "push pp\n"
      "movl pp,2\n"
      "imull pp,pp,0x...\n"
      "movl rax,pp\n"
      "pop pp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(UnsignedMultiplyLong, assembler) {
  __ movq(RAX, Immediate(-1));  // RAX = 0xFFFFFFFFFFFFFFFF
  __ movq(RCX, Immediate(16));  // RCX = 0x10
  __ mulq(RCX);                 // RDX:RAX = RAX * RCX = 0x0FFFFFFFFFFFFFFFF0
  __ movq(RAX, RDX);            // Return high64(0x0FFFFFFFFFFFFFFFF0) == 0x0F
  __ ret();
}

ASSEMBLER_TEST_RUN(UnsignedMultiplyLong, test) {
  typedef int64_t (*UnsignedMultiplyLong)();
  EXPECT_EQ(15, reinterpret_cast<UnsignedMultiplyLong>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movq rax,-1\n"
      "movl rcx,0x10\n"
      "mulq (rax,rdx),rcx\n"
      "movq rax,rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SignedDivide, assembler) {
  __ movl(RAX, Immediate(-87));
  __ movl(RDX, Immediate(123));
  __ cdq();
  __ movl(RCX, Immediate(42));
  __ idivl(RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SignedDivide, test) {
  typedef int32_t (*SignedDivide)();
  EXPECT_EQ(-87 / 42, reinterpret_cast<SignedDivide>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,-0x........\n"
      "movl rdx,0x7b\n"
      "cdq\n"
      "movl rcx,0x2a\n"
      "idivl (rax,rdx),rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(UnsignedDivide, assembler) {
  const int32_t low = 0;
  const int32_t high = 0xf0000000;
  const int32_t divisor = 0xffffffff;
  __ movl(RAX, Immediate(low));
  __ movl(RDX, Immediate(high));
  __ movl(RCX, Immediate(divisor));
  __ divl(RCX);  // RAX = RDX:RAX / RCX =
                 //     = 0xf000000000000000 / 0xffffffff = 0xf0000000
  __ ret();
}

ASSEMBLER_TEST_RUN(UnsignedDivide, test) {
  typedef uint32_t (*UnsignedDivide)();
  EXPECT_EQ(0xf0000000, reinterpret_cast<UnsignedDivide>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,0\n"
      "movl rdx,-0x........\n"
      "movl rcx,-1\n"
      "divl (rax,rdx),rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SignedDivideLong, assembler) {
  __ movq(RAX, Immediate(kLargeConstant));
  __ movq(RDX, Immediate(123));
  __ cqo();  // Clear RDX.
  __ movq(RCX, Immediate(42));
  __ idivq(RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SignedDivideLong, test) {
  typedef int64_t (*SignedDivideLong)();
  EXPECT_EQ(kLargeConstant / 42,
            reinterpret_cast<SignedDivideLong>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "movl rdx,0x7b\n"
      "cqo\n"
      "movl rcx,0x2a\n"
      "idivq (rax,rdx),rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(UnsignedDivideLong, assembler) {
  const int64_t low = 0;
  const int64_t high = 0xf000000000000000;
  const int64_t divisor = 0xffffffffffffffff;
  __ movq(RAX, Immediate(low));
  __ movq(RDX, Immediate(high));
  __ movq(RCX, Immediate(divisor));
  __ divq(RCX);  // RAX = RDX:RAX / RCX =
                 //     = 0xf0000000000000000000000000000000 /
                 //       0xffffffffffffffff = 0xf000000000000000
  __ ret();
}

ASSEMBLER_TEST_RUN(UnsignedDivideLong, test) {
  typedef uint64_t (*UnsignedDivideLong)();
  EXPECT_EQ(0xf000000000000000,
            reinterpret_cast<UnsignedDivideLong>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,0\n"
      "movq rdx,0x................\n"
      "movq rcx,-1\n"
      "divq (rax,rdx),rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Negate, assembler) {
  __ movq(RCX, Immediate(42));
  __ negq(RCX);
  __ movq(RAX, RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Negate, test) {
  typedef int (*Negate)();
  EXPECT_EQ(-42, reinterpret_cast<Negate>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rcx,0x2a\n"
      "negq rcx\n"
      "movq rax,rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(BitScanReverseTest, assembler) {
  __ pushq(CallingConventions::kArg1Reg);
  __ movq(RCX, Address(RSP, 0));
  __ movq(RAX, Immediate(666));  // Marker for conditional write.
  __ bsrq(RAX, RCX);
  __ popq(RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(BitScanReverseTest, test) {
  typedef int (*Bsr)(int input);
  Bsr call = reinterpret_cast<Bsr>(test->entry());
  EXPECT_EQ(666, call(0));
  EXPECT_EQ(0, call(1));
  EXPECT_EQ(1, call(2));
  EXPECT_EQ(1, call(3));
  EXPECT_EQ(2, call(4));
  EXPECT_EQ(5, call(42));
  EXPECT_EQ(31, call(-1));
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rdi\n"
      "movq rcx,[rsp]\n"
      "movl rax,0x...\n"
      "bsrq rax,rcx\n"
      "pop rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(MoveExtend, assembler) {
  __ movq(RDX, Immediate(0xffff));
  __ movzxb(RAX, RDX);  // RAX = 0xff
  __ movsxw(R8, RDX);   // R8 = -1
  __ movzxw(RCX, RDX);  // RCX = 0xffff
  __ addq(R8, RCX);
  __ addq(RAX, R8);
  __ ret();
}

ASSEMBLER_TEST_RUN(MoveExtend, test) {
  typedef int (*MoveExtend)();
  EXPECT_EQ(0xff - 1 + 0xffff, reinterpret_cast<MoveExtend>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rdx,0x....\n"
      "movzxbq rax,rdx\n"
      "movsxwq r8,rdx\n"
      "movzxwq rcx,rdx\n"
      "addq r8,rcx\n"
      "addq rax,r8\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(MoveExtend32, assembler) {
  __ movq(RDX, Immediate(0xffffffff));
  __ movsxd(RDX, RDX);
  __ movq(RAX, Immediate(0x7fffffff));
  __ movsxd(RAX, RAX);
  __ addq(RAX, RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(MoveExtend32, test) {
  typedef intptr_t (*MoveExtend)();
  EXPECT_EQ(0x7ffffffe, reinterpret_cast<MoveExtend>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rdx,0x........\n"
      "movsxdq rdx,rdx\n"
      "movl rax,0x........\n"
      "movsxdq rax,rax\n"
      "addq rax,rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(MoveExtendMemory, assembler) {
  __ movq(RDX, Immediate(0x123456781234ffff));

  __ pushq(RDX);
  __ movzxb(RAX, Address(RSP, 0));  // RAX = 0xff
  __ movsxw(R8, Address(RSP, 0));   // R8 = -1
  __ movzxw(RCX, Address(RSP, 0));  // RCX = 0xffff
  __ addq(RSP, Immediate(target::kWordSize));

  __ addq(R8, RCX);
  __ addq(RAX, R8);
  __ ret();
}

ASSEMBLER_TEST_RUN(MoveExtendMemory, test) {
  typedef int (*MoveExtendMemory)();
  EXPECT_EQ(0xff - 1 + 0xffff,
            reinterpret_cast<MoveExtendMemory>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movq rdx,0x................\n"
      "push rdx\n"
      "movzxbq rax,[rsp]\n"
      "movsxwq r8,[rsp]\n"
      "movzxwq rcx,[rsp]\n"
      "addq rsp,8\n"
      "addq r8,rcx\n"
      "addq rax,r8\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(MoveExtend32Memory, assembler) {
  __ pushq(Immediate(0xffffffff));
  __ pushq(Immediate(0x7fffffff));
  __ movsxd(RDX, Address(RSP, target::kWordSize));
  __ movsxd(RAX, Address(RSP, 0));
  __ addq(RSP, Immediate(target::kWordSize * 2));

  __ addq(RAX, RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(MoveExtend32Memory, test) {
  typedef intptr_t (*MoveExtend)();
  EXPECT_EQ(0x7ffffffe, reinterpret_cast<MoveExtend>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl r11,0x........\n"
      "push r11\n"
      "push 0x........\n"
      "movsxdq rdx,[rsp+0x8]\n"
      "movsxdq rax,[rsp]\n"
      "addq rsp,0x10\n"
      "addq rax,rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(MoveWord, assembler) {
  __ xorq(RAX, RAX);
  __ pushq(Immediate(0));
  __ movq(RAX, RSP);
  __ movq(RCX, Immediate(-1));
  __ movw(Address(RAX, 0), RCX);
  __ movzxw(RAX, Address(RAX, 0));  // RAX = 0xffff
  __ addq(RSP, Immediate(target::kWordSize));
  __ ret();
}

ASSEMBLER_TEST_RUN(MoveWord, test) {
  typedef int (*MoveWord)();
  EXPECT_EQ(0xffff, reinterpret_cast<MoveWord>(test->entry())());
  EXPECT_DISASSEMBLY(
      "xorq rax,rax\n"
      "push 0\n"
      "movq rax,rsp\n"
      "movq rcx,-1\n"
      "movw [rax],rcx\n"
      "movzxwq rax,[rax]\n"
      "addq rsp,8\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(WordOps, assembler) {
  __ movq(RAX, Immediate(0x0102030405060708));
  __ pushq(RAX);
  __ addw(Address(RSP, 0), Immediate(-0x201));
  __ subw(Address(RSP, 2), Immediate(0x201));
  __ xorw(Address(RSP, 4), Immediate(0x201));
  __ andw(Address(RSP, 6), Immediate(0x301));
  __ andw(Address(RSP, 0), Immediate(-1));
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(WordOps, test) {
  typedef int64_t (*WordOps)();
  EXPECT_EQ(0x0100010503050507, reinterpret_cast<WordOps>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "push rax\n"
      "addw [rsp],0x....\n"
      "subw [rsp+0x2],0x...\n"
      "xorw [rsp+0x4],0x...\n"
      "andw [rsp+0x6],0x...\n"
      "andw [rsp],-1\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(ByteOps, assembler) {
  __ movq(RAX, Immediate(0x0102030405060708));
  __ pushq(RAX);
  __ addb(Address(RSP, 0), Immediate(0xff));
  __ subb(Address(RSP, 2), Immediate(1));
  __ xorb(Address(RSP, 4), Immediate(1));
  __ andb(Address(RSP, 6), Immediate(1));
  __ andb(Address(RSP, 0), Immediate(-1));
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(ByteOps, test) {
  typedef int64_t (*ByteOps)();
  EXPECT_EQ(0x0100030505050707, reinterpret_cast<ByteOps>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "push rax\n"
      "addb [rsp],-1\n"
      "subb [rsp+0x2],1\n"
      "xorb [rsp+0x4],1\n"
      "andb [rsp+0x6],1\n"
      "andb [rsp],-1\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(MoveWordRex, assembler) {
  __ pushq(Immediate(0));
  __ movq(R8, RSP);
  __ movq(R9, Immediate(-1));
  __ movw(Address(R8, 0), R9);
  __ movzxw(R8, Address(R8, 0));  // 0xffff
  __ xorq(RAX, RAX);
  __ addq(RAX, R8);  // RAX = 0xffff
  __ addq(RSP, Immediate(target::kWordSize));
  __ ret();
}

ASSEMBLER_TEST_RUN(MoveWordRex, test) {
  typedef int (*MoveWordRex)();
  EXPECT_EQ(0xffff, reinterpret_cast<MoveWordRex>(test->entry())());
  EXPECT_DISASSEMBLY(
      "push 0\n"
      "movq r8,rsp\n"
      "movq r9,-1\n"
      "movw [r8],r9\n"
      "movzxwq r8,[r8]\n"
      "xorq rax,rax\n"
      "addq rax,r8\n"
      "addq rsp,8\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LongAddReg, assembler) {
  __ pushq(CallingConventions::kArg2Reg);
  __ pushq(CallingConventions::kArg1Reg);
  __ movl(RAX, Address(RSP, 0));  // left low.
  __ movl(RDX, Address(RSP, 4));  // left high.
  __ movl(RCX, Address(RSP, 8));  // right low.
  __ movl(R8, Address(RSP, 12));  // right high
  __ addl(RAX, RCX);
  __ adcl(RDX, R8);
  // Result is in RAX/RDX.
  __ movl(Address(RSP, 0), RAX);  // result low.
  __ movl(Address(RSP, 4), RDX);  // result high.
  __ popq(RAX);
  __ popq(RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(LongAddReg, test) {
  typedef int64_t (*LongAddRegCode)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongAddRegCode>(test->entry())(a, b);
  EXPECT_EQ((a + b), res);
  a = 2147483647;
  b = 600000;
  res = reinterpret_cast<LongAddRegCode>(test->entry())(a, b);
  EXPECT_EQ((a + b), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rsi\n"
      "push rdi\n"
      "movl rax,[rsp]\n"
      "movl rdx,[rsp+0x4]\n"
      "movl rcx,[rsp+0x8]\n"
      "movl r8,[rsp+0xc]\n"
      "addl rax,rcx\n"
      "adcl rdx,r8\n"
      "movl [rsp],rax\n"
      "movl [rsp+0x4],rdx\n"
      "pop rax\n"
      "pop rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LongAddImmediate, assembler) {
  __ pushq(CallingConventions::kArg1Reg);
  __ movl(RAX, Address(RSP, 0));  // left low.
  __ movl(RDX, Address(RSP, 4));  // left high.
  __ addl(RAX, Immediate(12));    // right low immediate.
  __ adcl(RDX, Immediate(11));    // right high immediate.
  // Result is in RAX/RDX.
  __ movl(Address(RSP, 0), RAX);  // result low.
  __ movl(Address(RSP, 4), RDX);  // result high.
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(LongAddImmediate, test) {
  typedef int64_t (*LongAddImmediateCode)(int64_t a);
  int64_t a = (13LL << 32) + 14;
  int64_t b = (11LL << 32) + 12;
  int64_t res = reinterpret_cast<LongAddImmediateCode>(test->entry())(a);
  EXPECT_EQ((a + b), res);
  a = (13LL << 32) - 1;
  res = reinterpret_cast<LongAddImmediateCode>(test->entry())(a);
  EXPECT_EQ((a + b), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rdi\n"
      "movl rax,[rsp]\n"
      "movl rdx,[rsp+0x4]\n"
      "addl rax,0xc\n"
      "adcl rdx,0xb\n"
      "movl [rsp],rax\n"
      "movl [rsp+0x4],rdx\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LongAddAddress, assembler) {
  __ pushq(CallingConventions::kArg2Reg);
  __ pushq(CallingConventions::kArg1Reg);
  __ movl(RAX, Address(RSP, 0));   // left low.
  __ movl(RDX, Address(RSP, 4));   // left high.
  __ addl(RAX, Address(RSP, 8));   // low.
  __ adcl(RDX, Address(RSP, 12));  // high.
  // Result is in RAX/RDX.
  __ movl(Address(RSP, 0), RAX);  // result low.
  __ movl(Address(RSP, 4), RDX);  // result high.
  __ popq(RAX);
  __ popq(RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(LongAddAddress, test) {
  typedef int64_t (*LongAddAddressCode)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongAddAddressCode>(test->entry())(a, b);
  EXPECT_EQ((a + b), res);
  a = 2147483647;
  b = 600000;
  res = reinterpret_cast<LongAddAddressCode>(test->entry())(a, b);
  EXPECT_EQ((a + b), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rsi\n"
      "push rdi\n"
      "movl rax,[rsp]\n"
      "movl rdx,[rsp+0x4]\n"
      "addl rax,[rsp+0x8]\n"
      "adcl rdx,[rsp+0xc]\n"
      "movl [rsp],rax\n"
      "movl [rsp+0x4],rdx\n"
      "pop rax\n"
      "pop rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LongSubReg, assembler) {
  __ pushq(CallingConventions::kArg2Reg);
  __ pushq(CallingConventions::kArg1Reg);
  __ movl(RAX, Address(RSP, 0));  // left low.
  __ movl(RDX, Address(RSP, 4));  // left high.
  __ movl(RCX, Address(RSP, 8));  // right low.
  __ movl(R8, Address(RSP, 12));  // right high
  __ subl(RAX, RCX);
  __ sbbl(RDX, R8);
  // Result is in RAX/RDX.
  __ movl(Address(RSP, 0), RAX);  // result low.
  __ movl(Address(RSP, 4), RDX);  // result high.
  __ popq(RAX);
  __ popq(RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(LongSubReg, test) {
  typedef int64_t (*LongSubRegCode)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongSubRegCode>(test->entry())(a, b);
  EXPECT_EQ((a - b), res);
  a = 600000;
  b = 2147483647;
  res = reinterpret_cast<LongSubRegCode>(test->entry())(a, b);
  EXPECT_EQ((a - b), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rsi\n"
      "push rdi\n"
      "movl rax,[rsp]\n"
      "movl rdx,[rsp+0x4]\n"
      "movl rcx,[rsp+0x8]\n"
      "movl r8,[rsp+0xc]\n"
      "subl rax,rcx\n"
      "sbbl rdx,r8\n"
      "movl [rsp],rax\n"
      "movl [rsp+0x4],rdx\n"
      "pop rax\n"
      "pop rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LongSubImmediate, assembler) {
  __ pushq(CallingConventions::kArg1Reg);
  __ movl(RAX, Immediate(0));
  __ subl(
      RAX,
      Immediate(1));  // Set the carry flag so we can test that subl ignores it.
  __ movl(RAX, Address(RSP, 0));  // left low.
  __ movl(RDX, Address(RSP, 4));  // left high.
  __ subl(RAX, Immediate(12));    // right low immediate.
  __ sbbl(RDX, Immediate(11));    // right high immediate.
  // Result is in RAX/RDX.
  __ movl(Address(RSP, 0), RAX);  // result low.
  __ movl(Address(RSP, 4), RDX);  // result high.
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(LongSubImmediate, test) {
  typedef int64_t (*LongSubImmediateCode)(int64_t a);
  int64_t a = (13LL << 32) + 14;
  int64_t b = (11LL << 32) + 12;
  int64_t res = reinterpret_cast<LongSubImmediateCode>(test->entry())(a);
  EXPECT_EQ((a - b), res);
  a = (13LL << 32) + 10;
  res = reinterpret_cast<LongSubImmediateCode>(test->entry())(a);
  EXPECT_EQ((a - b), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rdi\n"
      "movl rax,0\n"
      "subl rax,1\n"
      "movl rax,[rsp]\n"
      "movl rdx,[rsp+0x4]\n"
      "subl rax,0xc\n"
      "sbbl rdx,0xb\n"
      "movl [rsp],rax\n"
      "movl [rsp+0x4],rdx\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LongSubAddress, assembler) {
  __ pushq(CallingConventions::kArg2Reg);
  __ pushq(CallingConventions::kArg1Reg);
  __ movl(RAX, Address(RSP, 0));   // left low.
  __ movl(RDX, Address(RSP, 4));   // left high.
  __ subl(RAX, Address(RSP, 8));   // low.
  __ sbbl(RDX, Address(RSP, 12));  // high.
  // Result is in RAX/RDX.
  __ movl(Address(RSP, 0), RAX);  // result low.
  __ movl(Address(RSP, 4), RDX);  // result high.
  __ popq(RAX);
  __ popq(RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(LongSubAddress, test) {
  typedef int64_t (*LongSubAddressCode)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongSubAddressCode>(test->entry())(a, b);
  EXPECT_EQ((a - b), res);
  a = 600000;
  b = 2147483647;
  res = reinterpret_cast<LongSubAddressCode>(test->entry())(a, b);
  EXPECT_EQ((a - b), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rsi\n"
      "push rdi\n"
      "movl rax,[rsp]\n"
      "movl rdx,[rsp+0x4]\n"
      "subl rax,[rsp+0x8]\n"
      "sbbl rdx,[rsp+0xc]\n"
      "movl [rsp],rax\n"
      "movl [rsp+0x4],rdx\n"
      "pop rax\n"
      "pop rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AddReg, assembler) {
  __ movq(R10, CallingConventions::kArg1Reg);  // al.
  __ addq(R10, CallingConventions::kArg3Reg);  // bl.
  __ movq(RAX, CallingConventions::kArg2Reg);  // ah.
  __ adcq(RAX, CallingConventions::kArg4Reg);  // bh.
  // RAX = high64(ah:al + bh:bl).
  __ ret();
}

ASSEMBLER_TEST_RUN(AddReg, test) {
  typedef int64_t (*AddRegCode)(int64_t al, int64_t ah, int64_t bl, int64_t bh);
  int64_t al = 11;
  int64_t ah = 12;
  int64_t bl = 13;
  int64_t bh = 14;
  int64_t res = reinterpret_cast<AddRegCode>(test->entry())(al, ah, bl, bh);
  EXPECT_EQ((ah + bh), res);
  al = -1;
  res = reinterpret_cast<AddRegCode>(test->entry())(al, ah, bl, bh);
  EXPECT_EQ((ah + bh + 1), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "movq r10,rdi\n"
      "addq r10,rdx\n"
      "movq rax,rsi\n"
      "adcq rax,rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AddImmediate, assembler) {
  __ movq(R10, CallingConventions::kArg1Reg);  // al.
  __ addq(R10, Immediate(13));                 // bl.
  __ movq(RAX, CallingConventions::kArg2Reg);  // ah.
  __ adcq(RAX, Immediate(14));                 // bh.
  // RAX = high64(ah:al + bh:bl).
  __ ret();
}

ASSEMBLER_TEST_RUN(AddImmediate, test) {
  typedef int64_t (*AddImmediateCode)(int64_t al, int64_t ah);
  int64_t al = 11;
  int64_t ah = 12;
  int64_t bh = 14;
  int64_t res = reinterpret_cast<AddImmediateCode>(test->entry())(al, ah);
  EXPECT_EQ((ah + bh), res);
  al = -1;
  res = reinterpret_cast<AddImmediateCode>(test->entry())(al, ah);
  EXPECT_EQ((ah + bh + 1), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "movq r10,rdi\n"
      "addq r10,0xd\n"
      "movq rax,rsi\n"
      "adcq rax,0xe\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AddAddress, assembler) {
  __ pushq(CallingConventions::kArg4Reg);
  __ pushq(CallingConventions::kArg3Reg);
  __ pushq(CallingConventions::kArg2Reg);
  __ pushq(CallingConventions::kArg1Reg);
  __ movq(R10, Address(RSP, 0 * target::kWordSize));  // al.
  __ addq(R10, Address(RSP, 2 * target::kWordSize));  // bl.
  __ movq(RAX, Address(RSP, 1 * target::kWordSize));  // ah.
  __ adcq(RAX, Address(RSP, 3 * target::kWordSize));  // bh.
  // RAX = high64(ah:al + bh:bl).
  __ Drop(4);
  __ ret();
}

ASSEMBLER_TEST_RUN(AddAddress, test) {
  typedef int64_t (*AddCode)(int64_t al, int64_t ah, int64_t bl, int64_t bh);
  int64_t al = 11;
  int64_t ah = 12;
  int64_t bl = 13;
  int64_t bh = 14;
  int64_t res = reinterpret_cast<AddCode>(test->entry())(al, ah, bl, bh);
  EXPECT_EQ((ah + bh), res);
  al = -1;
  res = reinterpret_cast<AddCode>(test->entry())(al, ah, bl, bh);
  EXPECT_EQ((ah + bh + 1), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rcx\n"
      "push rdx\n"
      "push rsi\n"
      "push rdi\n"
      "movq r10,[rsp]\n"
      "addq r10,[rsp+0x10]\n"
      "movq rax,[rsp+0x8]\n"
      "adcq rax,[rsp+0x18]\n"
      "pop r11\n"
      "pop r11\n"
      "pop r11\n"
      "pop r11\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SubReg, assembler) {
  __ movq(R10, CallingConventions::kArg1Reg);  // al.
  __ subq(R10, CallingConventions::kArg3Reg);  // bl.
  __ movq(RAX, CallingConventions::kArg2Reg);  // ah.
  __ sbbq(RAX, CallingConventions::kArg4Reg);  // bh.
  // RAX = high64(ah:al - bh:bl).
  __ ret();
}

ASSEMBLER_TEST_RUN(SubReg, test) {
  typedef int64_t (*SubRegCode)(int64_t al, int64_t ah, int64_t bl, int64_t bh);
  int64_t al = 14;
  int64_t ah = 13;
  int64_t bl = 12;
  int64_t bh = 11;
  int64_t res = reinterpret_cast<SubRegCode>(test->entry())(al, ah, bl, bh);
  EXPECT_EQ((ah - bh), res);
  al = 10;
  res = reinterpret_cast<SubRegCode>(test->entry())(al, ah, bl, bh);
  EXPECT_EQ((ah - bh - 1), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "movq r10,rdi\n"
      "subq r10,rdx\n"
      "movq rax,rsi\n"
      "sbbq rax,rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SubImmediate, assembler) {
  __ movq(R10, CallingConventions::kArg1Reg);  // al.
  __ subq(R10, Immediate(12));                 // bl.
  __ movq(RAX, CallingConventions::kArg2Reg);  // ah.
  __ sbbq(RAX, Immediate(11));                 // bh.
  // RAX = high64(ah:al - bh:bl).
  __ ret();
}

ASSEMBLER_TEST_RUN(SubImmediate, test) {
  typedef int64_t (*SubImmediateCode)(int64_t al, int64_t ah);
  int64_t al = 14;
  int64_t ah = 13;
  int64_t bh = 11;
  int64_t res = reinterpret_cast<SubImmediateCode>(test->entry())(al, ah);
  EXPECT_EQ((ah - bh), res);
  al = 10;
  res = reinterpret_cast<SubImmediateCode>(test->entry())(al, ah);
  EXPECT_EQ((ah - bh - 1), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "movq r10,rdi\n"
      "subq r10,0xc\n"
      "movq rax,rsi\n"
      "sbbq rax,0xb\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SubAddress, assembler) {
  __ pushq(CallingConventions::kArg4Reg);
  __ pushq(CallingConventions::kArg3Reg);
  __ pushq(CallingConventions::kArg2Reg);
  __ pushq(CallingConventions::kArg1Reg);
  __ movq(R10, Address(RSP, 0 * target::kWordSize));  // al.
  __ subq(R10, Address(RSP, 2 * target::kWordSize));  // bl.
  __ movq(RAX, Address(RSP, 1 * target::kWordSize));  // ah.
  __ sbbq(RAX, Address(RSP, 3 * target::kWordSize));  // bh.
  // RAX = high64(ah:al - bh:bl).
  __ Drop(4);
  __ ret();
}

ASSEMBLER_TEST_RUN(SubAddress, test) {
  typedef int64_t (*SubCode)(int64_t al, int64_t ah, int64_t bl, int64_t bh);
  int64_t al = 14;
  int64_t ah = 13;
  int64_t bl = 12;
  int64_t bh = 11;
  int64_t res = reinterpret_cast<SubCode>(test->entry())(al, ah, bl, bh);
  EXPECT_EQ((ah - bh), res);
  al = 10;
  res = reinterpret_cast<SubCode>(test->entry())(al, ah, bl, bh);
  EXPECT_EQ((ah - bh - 1), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rcx\n"
      "push rdx\n"
      "push rsi\n"
      "push rdi\n"
      "movq r10,[rsp]\n"
      "subq r10,[rsp+0x10]\n"
      "movq rax,[rsp+0x8]\n"
      "sbbq rax,[rsp+0x18]\n"
      "pop r11\n"
      "pop r11\n"
      "pop r11\n"
      "pop r11\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Bitwise, assembler) {
  __ movq(R10, Immediate(-1));
  __ orl(Address(CallingConventions::kArg1Reg, 0), R10);
  __ orl(Address(CallingConventions::kArg2Reg, 0), R10);
  __ movl(RCX, Immediate(42));
  __ xorl(RCX, RCX);
  __ orl(RCX, Immediate(256));
  __ movl(RAX, Immediate(4));
  __ orl(RCX, RAX);
  __ movl(RAX, Immediate(0xfff0));
  __ andl(RCX, RAX);
  __ movl(RAX, Immediate(1));
  __ orl(RCX, RAX);
  __ movl(RAX, RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Bitwise, test) {
  uint64_t f1 = 0;
  uint64_t f2 = 0;
  typedef int (*Bitwise)(void*, void*);
  int result = reinterpret_cast<Bitwise>(test->entry())(&f1, &f2);
  EXPECT_EQ(256 + 1, result);
  EXPECT_EQ(kMaxUint32, f1);
  EXPECT_EQ(kMaxUint32, f2);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "movq r10,-1\n"
      "orl [rdi],r10\n"
      "orl [rsi],r10\n"
      "movl rcx,0x2a\n"
      "xorl rcx,rcx\n"
      "orl rcx,0x...\n"
      "movl rax,4\n"
      "orl rcx,rax\n"
      "movl rax,0x....\n"
      "andl rcx,rax\n"
      "movl rax,1\n"
      "orl rcx,rax\n"
      "movl rax,rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Bitwise64, assembler) {
  Label error;
  __ movq(RAX, Immediate(42));
  __ pushq(RAX);
  __ xorq(RAX, Address(RSP, 0));
  __ popq(RCX);
  __ cmpq(RAX, Immediate(0));
  __ j(NOT_EQUAL, &error);
  __ movq(RCX, Immediate(0xFF));
  __ movq(RAX, Immediate(0x5));
  __ xorq(RCX, RAX);
  __ cmpq(RCX, Immediate(0xFF ^ 0x5));
  __ j(NOT_EQUAL, &error);
  __ pushq(Immediate(0xFF));
  __ movq(RCX, Immediate(0x5));
  __ xorq(Address(RSP, 0), RCX);
  __ popq(RCX);
  __ cmpq(RCX, Immediate(0xFF ^ 0x5));
  __ j(NOT_EQUAL, &error);
  __ xorq(RCX, RCX);
  __ orq(RCX, Immediate(256));
  __ movq(RAX, Immediate(4));
  __ orq(RCX, RAX);
  __ movq(RAX, Immediate(0xfff0));
  __ andq(RCX, RAX);
  __ movq(RAX, Immediate(1));
  __ pushq(RAX);
  __ orq(RCX, Address(RSP, 0));
  __ xorq(RCX, Immediate(0));
  __ popq(RAX);
  __ movq(RAX, RCX);
  __ ret();
  __ Bind(&error);
  __ movq(RAX, Immediate(-1));
  __ ret();
}

ASSEMBLER_TEST_RUN(Bitwise64, test) {
  typedef int (*Bitwise64)();
  EXPECT_EQ(256 + 1, reinterpret_cast<Bitwise64>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,0x2a\n"
      "push rax\n"
      "xorq rax,[rsp]\n"
      "pop rcx\n"
      "cmpq rax,0\n"
      "jnz 0x................\n"
      "movl rcx,0xff\n"
      "movl rax,5\n"
      "xorq rcx,rax\n"
      "cmpq rcx,0xfa\n"
      "jnz 0x................\n"
      "push 0xff\n"
      "movl rcx,5\n"
      "xorq [rsp],rcx\n"
      "pop rcx\n"
      "cmpq rcx,0xfa\n"
      "jnz 0x................\n"
      "xorq rcx,rcx\n"
      "orq rcx,0x...\n"
      "movl rax,4\n"
      "orq rcx,rax\n"
      "movl rax,0x....\n"
      "andq rcx,rax\n"
      "movl rax,1\n"
      "push rax\n"
      "orq rcx,[rsp]\n"
      "xorq rcx,0\n"
      "pop rax\n"
      "movq rax,rcx\n"
      "ret\n"
      "movq rax,-1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LogicalOps, assembler) {
  Label donetest1;
  __ movl(RAX, Immediate(4));
  __ andl(RAX, Immediate(2));
  __ cmpl(RAX, Immediate(0));
  __ j(EQUAL, &donetest1);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest1);

  Label donetest2;
  __ movl(RCX, Immediate(4));
  __ andl(RCX, Immediate(4));
  __ cmpl(RCX, Immediate(0));
  __ j(NOT_EQUAL, &donetest2);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest2);

  Label donetest3;
  __ movl(RAX, Immediate(0));
  __ orl(RAX, Immediate(0));
  __ cmpl(RAX, Immediate(0));
  __ j(EQUAL, &donetest3);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest3);

  Label donetest4;
  __ movl(RAX, Immediate(4));
  __ orl(RAX, Immediate(0));
  __ cmpl(RAX, Immediate(0));
  __ j(NOT_EQUAL, &donetest4);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest4);

  Label donetest5;
  __ pushq(RAX);
  __ movl(RAX, Immediate(0xff));
  __ movl(Address(RSP, 0), RAX);
  __ cmpl(Address(RSP, 0), Immediate(0xff));
  __ j(EQUAL, &donetest5);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest5);
  __ popq(RAX);

  Label donetest6;
  __ movl(RAX, Immediate(1));
  __ shll(RAX, Immediate(3));
  __ cmpl(RAX, Immediate(8));
  __ j(EQUAL, &donetest6);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest6);

  Label donetest7;
  __ movl(RAX, Immediate(2));
  __ shrl(RAX, Immediate(1));
  __ cmpl(RAX, Immediate(1));
  __ j(EQUAL, &donetest7);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest7);

  Label donetest8;
  __ movl(RAX, Immediate(8));
  __ shrl(RAX, Immediate(3));
  __ cmpl(RAX, Immediate(1));
  __ j(EQUAL, &donetest8);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest8);

  Label donetest9;
  __ movl(RAX, Immediate(1));
  __ movl(RCX, Immediate(3));
  __ shll(RAX, RCX);
  __ cmpl(RAX, Immediate(8));
  __ j(EQUAL, &donetest9);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest9);

  Label donetest10;
  __ movl(RAX, Immediate(8));
  __ movl(RCX, Immediate(3));
  __ shrl(RAX, RCX);
  __ cmpl(RAX, Immediate(1));
  __ j(EQUAL, &donetest10);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest10);

  Label donetest6a;
  __ movl(RAX, Immediate(1));
  __ shlq(RAX, Immediate(3));
  __ cmpl(RAX, Immediate(8));
  __ j(EQUAL, &donetest6a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest6a);

  Label donetest7a;
  __ movl(RAX, Immediate(2));
  __ shrq(RAX, Immediate(1));
  __ cmpl(RAX, Immediate(1));
  __ j(EQUAL, &donetest7a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest7a);

  Label donetest8a;
  __ movl(RAX, Immediate(8));
  __ shrq(RAX, Immediate(3));
  __ cmpl(RAX, Immediate(1));
  __ j(EQUAL, &donetest8a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest8a);

  Label donetest9a;
  __ movl(RAX, Immediate(1));
  __ movl(RCX, Immediate(3));
  __ shlq(RAX, RCX);
  __ cmpl(RAX, Immediate(8));
  __ j(EQUAL, &donetest9a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest9a);

  Label donetest10a;
  __ movl(RAX, Immediate(8));
  __ movl(RCX, Immediate(3));
  __ shrq(RAX, RCX);
  __ cmpl(RAX, Immediate(1));
  __ j(EQUAL, &donetest10a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest10a);

  Label donetest11a;
  __ movl(RAX, Immediate(1));
  __ shlq(RAX, Immediate(31));
  __ shrq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(0x10000000));
  __ j(EQUAL, &donetest11a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest11a);

  Label donetest12a;
  __ movl(RAX, Immediate(1));
  __ shlq(RAX, Immediate(31));
  __ sarl(RAX, Immediate(3));
  __ cmpl(RAX, Immediate(0xfffffffff0000000));
  __ j(EQUAL, &donetest12a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest12a);

  Label donetest13a;
  __ movl(RAX, Immediate(1));
  __ movl(RCX, Immediate(3));
  __ shlq(RAX, Immediate(31));
  __ sarl(RAX, RCX);
  __ cmpl(RAX, Immediate(0xfffffffff0000000));
  __ j(EQUAL, &donetest13a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest13a);

  {
    Label donetest15a;
    const int32_t left = 0xff000000;
    const int32_t right = 0xffffffff;
    const int32_t shifted = 0xf0000003;
    __ movl(RDX, Immediate(left));
    __ movl(R8, Immediate(right));
    __ movl(RCX, Immediate(2));
    __ shll(RDX, RCX);  // RDX = 0xff000000 << 2 == 0xfc000000
    __ shldl(RDX, R8, Immediate(2));
    // RDX = high32(0xfc000000:0xffffffff << 2) == 0xf0000003
    __ cmpl(RDX, Immediate(shifted));
    __ j(EQUAL, &donetest15a);
    __ int3();
    __ Bind(&donetest15a);
  }

  {
    Label donetest15b;
    const int64_t left = 0xff00000000000000;
    const int64_t right = 0xffffffffffffffff;
    const int64_t shifted = 0xf000000000000003;
    __ movq(RDX, Immediate(left));
    __ movq(R8, Immediate(right));
    __ movq(RCX, Immediate(2));
    __ shlq(RDX, RCX);  // RDX = 0xff00000000000000 << 2 == 0xfc00000000000000
    __ shldq(RDX, R8, Immediate(2));
    // RDX = high64(0xfc00000000000000:0xffffffffffffffff << 2)
    //     == 0xf000000000000003
    __ cmpq(RDX, Immediate(shifted));
    __ j(EQUAL, &donetest15b);
    __ int3();
    __ Bind(&donetest15b);
  }

  {
    Label donetest15c;
    const int64_t left = 0xff00000000000000;
    const int64_t right = 0xffffffffffffffff;
    const int64_t shifted = 0xf000000000000003;
    __ movq(RDX, Immediate(left));
    __ movq(R8, Immediate(right));
    __ movq(RCX, Immediate(2));
    __ shlq(RDX, RCX);  // RDX = 0xff00000000000000 << 2 == 0xfc00000000000000
    __ shldq(RDX, R8, RCX);
    // RDX = high64(0xfc00000000000000:0xffffffffffffffff << 2)
    //     == 0xf000000000000003
    __ cmpq(RDX, Immediate(shifted));
    __ j(EQUAL, &donetest15c);
    __ int3();
    __ Bind(&donetest15c);
  }

  {
    Label donetest15d;
    const int64_t left = 0xff00000000000000;
    const int64_t right = 0xffffffffffffffff;
    const int64_t shifted = 0xcff0000000000000;
    __ movq(RDX, Immediate(left));
    __ movq(R8, Immediate(right));
    __ movq(RCX, Immediate(2));
    __ shrq(RDX, RCX);  // RDX = 0xff00000000000000 >> 2 == 0x3fc0000000000000
    __ shrdq(RDX, R8, RCX);
    // RDX = low64(0xffffffffffffffff:0x3fc0000000000000 >> 2)
    //     == 0xcff0000000000000
    __ cmpq(RDX, Immediate(shifted));
    __ j(EQUAL, &donetest15d);
    __ int3();
    __ Bind(&donetest15d);
  }

  __ movl(RAX, Immediate(0));
  __ ret();
}

ASSEMBLER_TEST_RUN(LogicalOps, test) {
  typedef int (*LogicalOpsCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalOpsCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,4\n"
      "andl rax,2\n"
      "cmpl rax,0\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rcx,4\n"
      "andl rcx,4\n"
      "cmpl rcx,0\n"
      "jnz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,0\n"
      "orl rax,0\n"
      "cmpl rax,0\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,4\n"
      "orl rax,0\n"
      "cmpl rax,0\n"
      "jnz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "push rax\n"
      "movl rax,0xff\n"
      "movl [rsp],rax\n"
      "cmpl [rsp],0xff\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movq [rax],rax\n"
      "pop rax\n"
      "movl rax,1\n"
      "shll rax,3\n"
      "cmpl rax,8\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,2\n"
      "shrl rax,1\n"
      "cmpl rax,1\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,8\n"
      "shrl rax,3\n"
      "cmpl rax,1\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,1\n"
      "movl rcx,3\n"
      "shll rax,cl\n"
      "cmpl rax,8\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,8\n"
      "movl rcx,3\n"
      "shrl rax,cl\n"
      "cmpl rax,1\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,1\n"
      "shlq rax,3\n"
      "cmpl rax,8\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,2\n"
      "shrq rax,1\n"
      "cmpl rax,1\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,8\n"
      "shrq rax,3\n"
      "cmpl rax,1\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,1\n"
      "movl rcx,3\n"
      "shlq rax,cl\n"
      "cmpl rax,8\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,8\n"
      "movl rcx,3\n"
      "shrq rax,cl\n"
      "cmpl rax,1\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,1\n"
      "shlq rax,31\n"
      "shrq rax,3\n"
      "cmpq rax,0x........\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,1\n"
      "shlq rax,31\n"
      "sarl rax,3\n"
      "cmpl rax,0x........\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,1\n"
      "movl rcx,3\n"
      "shlq rax,31\n"
      "sarl rax,cl\n"
      "cmpl rax,0x........\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rdx,-0x........\n"
      "movl r8,-1\n"
      "movl rcx,2\n"
      "shll rdx,cl\n"
      "shldl rdx,r8,2\n"
      "cmpl rdx,0x........\n"
      "jz 0x................\n"
      "int3\n"
      "movq rdx,0x................\n"
      "movq r8,-1\n"
      "movl rcx,2\n"
      "shlq rdx,cl\n"
      "shldq rdx,r8,2\n"
      "movq r11,0x................\n"
      "cmpq rdx,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movq rdx,0x................\n"
      "movq r8,-1\n"
      "movl rcx,2\n"
      "shlq rdx,cl\n"
      "shldq rdx,r8,cl\n"
      "movq r11,0x................\n"
      "cmpq rdx,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movq rdx,0x................\n"
      "movq r8,-1\n"
      "movl rcx,2\n"
      "shrq rdx,cl\n"
      "shrdq rdx,r8,cl\n"
      "movq r11,0x................\n"
      "cmpq rdx,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LogicalOps64, assembler) {
  Label donetest1;
  __ movq(RAX, Immediate(4));
  __ andq(RAX, Immediate(2));
  __ cmpq(RAX, Immediate(0));
  __ j(EQUAL, &donetest1);
  __ int3();
  __ Bind(&donetest1);

  Label donetest2;
  __ movq(RCX, Immediate(4));
  __ pushq(RCX);
  __ andq(RCX, Address(RSP, 0));
  __ popq(RAX);
  __ cmpq(RCX, Immediate(0));
  __ j(NOT_EQUAL, &donetest2);
  __ int3();
  __ Bind(&donetest2);

  Label donetest3;
  __ movq(RAX, Immediate(0));
  __ orq(RAX, Immediate(0));
  __ cmpq(RAX, Immediate(0));
  __ j(EQUAL, &donetest3);
  __ int3();
  __ Bind(&donetest3);

  Label donetest4;
  __ movq(RAX, Immediate(4));
  __ orq(RAX, Immediate(0));
  __ cmpq(RAX, Immediate(0));
  __ j(NOT_EQUAL, &donetest4);
  __ int3();
  __ Bind(&donetest4);

  Label donetest5;
  __ pushq(RAX);
  __ movq(RAX, Immediate(0xff));
  __ movq(Address(RSP, 0), RAX);
  __ cmpq(Address(RSP, 0), Immediate(0xff));
  __ j(EQUAL, &donetest5);
  __ int3();
  __ Bind(&donetest5);
  __ popq(RAX);

  Label donetest6;
  __ movq(RAX, Immediate(1));
  __ shlq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(8));
  __ j(EQUAL, &donetest6);
  __ int3();
  __ Bind(&donetest6);

  Label donetest7;
  __ movq(RAX, Immediate(2));
  __ shrq(RAX, Immediate(1));
  __ cmpq(RAX, Immediate(1));
  __ j(EQUAL, &donetest7);
  __ int3();
  __ Bind(&donetest7);

  Label donetest8;
  __ movq(RAX, Immediate(8));
  __ shrq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(1));
  __ j(EQUAL, &donetest8);
  __ int3();
  __ Bind(&donetest8);

  Label donetest9;
  __ movq(RAX, Immediate(1));
  __ movq(RCX, Immediate(3));
  __ shlq(RAX, RCX);
  __ cmpq(RAX, Immediate(8));
  __ j(EQUAL, &donetest9);
  __ int3();
  __ Bind(&donetest9);

  Label donetest10;
  __ movq(RAX, Immediate(8));
  __ movq(RCX, Immediate(3));
  __ shrq(RAX, RCX);
  __ cmpq(RAX, Immediate(1));
  __ j(EQUAL, &donetest10);
  __ int3();
  __ Bind(&donetest10);

  Label donetest6a;
  __ movq(RAX, Immediate(1));
  __ shlq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(8));
  __ j(EQUAL, &donetest6a);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest6a);

  Label donetest7a;
  __ movq(RAX, Immediate(2));
  __ shrq(RAX, Immediate(1));
  __ cmpq(RAX, Immediate(1));
  __ j(EQUAL, &donetest7a);
  __ int3();
  __ Bind(&donetest7a);

  Label donetest8a;
  __ movq(RAX, Immediate(8));
  __ shrq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(1));
  __ j(EQUAL, &donetest8a);
  __ int3();
  __ Bind(&donetest8a);

  Label donetest9a;
  __ movq(RAX, Immediate(1));
  __ movq(RCX, Immediate(3));
  __ shlq(RAX, RCX);
  __ cmpq(RAX, Immediate(8));
  __ j(EQUAL, &donetest9a);
  __ int3();
  __ Bind(&donetest9a);

  Label donetest10a;
  __ movq(RAX, Immediate(8));
  __ movq(RCX, Immediate(3));
  __ shrq(RAX, RCX);
  __ cmpq(RAX, Immediate(1));
  __ j(EQUAL, &donetest10a);
  __ int3();
  __ Bind(&donetest10a);

  Label donetest11a;
  __ movq(RAX, Immediate(1));
  __ shlq(RAX, Immediate(31));
  __ shrq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(0x10000000));
  __ j(EQUAL, &donetest11a);
  __ int3();
  __ Bind(&donetest11a);

  Label donetest12a;
  __ movq(RAX, Immediate(1));
  __ shlq(RAX, Immediate(63));
  __ sarq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(0xf000000000000000));
  __ j(EQUAL, &donetest12a);
  __ int3();
  __ Bind(&donetest12a);

  Label donetest13a;
  __ movq(RAX, Immediate(1));
  __ movq(RCX, Immediate(3));
  __ shlq(RAX, Immediate(63));
  __ sarq(RAX, RCX);
  __ cmpq(RAX, Immediate(0xf000000000000000));
  __ j(EQUAL, &donetest13a);
  __ int3();
  __ Bind(&donetest13a);

  Label donetest14, donetest15;
  __ pushq(R15);  // Callee saved.
  __ movq(R15, Immediate(0xf000000000000001));
  __ andq(R15, Immediate(-1));
  __ andq(R15, Immediate(0x8000000000000001));
  __ orq(R15, Immediate(2));
  __ orq(R15, Immediate(0xf800000000000000));
  __ xorq(R15, Immediate(1));
  __ xorq(R15, Immediate(0x0800000000000000));
  __ cmpq(R15, Immediate(0xf000000000000002));
  __ j(EQUAL, &donetest14);
  __ int3();
  __ Bind(&donetest14);
  __ andq(R15, Immediate(2));
  __ cmpq(R15, Immediate(2));
  __ j(EQUAL, &donetest15);
  __ int3();
  __ Bind(&donetest15);
  __ popq(R15);  // Callee saved.

  __ movq(RAX, Immediate(0));
  __ ret();
}

ASSEMBLER_TEST_RUN(LogicalOps64, test) {
  typedef int (*LogicalOpsCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalOpsCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,4\n"
      "andl rax,2\n"
      "cmpq rax,0\n"
      "jz 0x................\n"
      "int3\n"
      "movl rcx,4\n"
      "push rcx\n"
      "andq rcx,[rsp]\n"
      "pop rax\n"
      "cmpq rcx,0\n"
      "jnz 0x................\n"
      "int3\n"
      "movl rax,0\n"
      "orq rax,0\n"
      "cmpq rax,0\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,4\n"
      "orq rax,0\n"
      "cmpq rax,0\n"
      "jnz 0x................\n"
      "int3\n"
      "push rax\n"
      "movl rax,0xff\n"
      "movq [rsp],rax\n"
      "cmpq [rsp],0xff\n"
      "jz 0x................\n"
      "int3\n"
      "pop rax\n"
      "movl rax,1\n"
      "shlq rax,3\n"
      "cmpq rax,8\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,2\n"
      "shrq rax,1\n"
      "cmpq rax,1\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,8\n"
      "shrq rax,3\n"
      "cmpq rax,1\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,1\n"
      "movl rcx,3\n"
      "shlq rax,cl\n"
      "cmpq rax,8\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,8\n"
      "movl rcx,3\n"
      "shrq rax,cl\n"
      "cmpq rax,1\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,1\n"
      "shlq rax,3\n"
      "cmpq rax,8\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movq [rax],rax\n"
      "movl rax,2\n"
      "shrq rax,1\n"
      "cmpq rax,1\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,8\n"
      "shrq rax,3\n"
      "cmpq rax,1\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,1\n"
      "movl rcx,3\n"
      "shlq rax,cl\n"
      "cmpq rax,8\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,8\n"
      "movl rcx,3\n"
      "shrq rax,cl\n"
      "cmpq rax,1\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,1\n"
      "shlq rax,31\n"
      "shrq rax,3\n"
      "cmpq rax,0x........\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,1\n"
      "shlq rax,63\n"
      "sarq rax,3\n"
      "movq r11,0x................\n"
      "cmpq rax,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,1\n"
      "movl rcx,3\n"
      "shlq rax,63\n"
      "sarq rax,cl\n"
      "movq r11,0x................\n"
      "cmpq rax,r11\n"
      "jz 0x................\n"
      "int3\n"
      "push pp\n"
      "movq pp,0x................\n"
      "andq pp,-1\n"
      "movq r11,0x................\n"
      "andq pp,r11\n"
      "orq pp,2\n"
      "movq r11,0x................\n"
      "orq pp,r11\n"
      "xorq pp,1\n"
      "movq r11,0x................\n"
      "xorq pp,r11\n"
      "movq r11,0x................\n"
      "cmpq pp,r11\n"
      "jz 0x................\n"
      "int3\n"
      "andl pp,2\n"
      "cmpq pp,2\n"
      "jz 0x................\n"
      "int3\n"
      "pop pp\n"
      "movl rax,0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LogicalTestL, assembler) {
  Label donetest1;
  __ movl(RAX, Immediate(4));
  __ movl(RCX, Immediate(2));
  __ testl(RAX, RCX);
  __ j(EQUAL, &donetest1);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest1);

  Label donetest2;
  __ movl(RDX, Immediate(4));
  __ movl(RCX, Immediate(4));
  __ testl(RDX, RCX);
  __ j(NOT_EQUAL, &donetest2);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest2);

  Label donetest3;
  __ movl(RAX, Immediate(0));
  __ testl(RAX, Immediate(0));
  __ j(EQUAL, &donetest3);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest3);

  Label donetest4;
  __ movl(RCX, Immediate(4));
  __ testl(RCX, Immediate(4));
  __ j(NOT_EQUAL, &donetest4);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest4);

  __ movl(RAX, Immediate(0));
  __ ret();
}

ASSEMBLER_TEST_RUN(LogicalTestL, test) {
  typedef int (*LogicalTestCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalTestCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,4\n"
      "movl rcx,2\n"
      "testl rax,rcx\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rdx,4\n"
      "movl rcx,4\n"
      "testl rdx,rcx\n"
      "jnz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,0\n"
      "test al,0\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rcx,4\n"
      "testb rcx,4\n"
      "jnz 0x................\n"
      "movl rax,0\n"
      "movl [rax],rax\n"
      "movl rax,0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LogicalTestQ, assembler) {
  Label donetest1;
  __ movq(RAX, Immediate(4));
  __ movq(RCX, Immediate(2));
  __ testq(RAX, RCX);
  __ j(EQUAL, &donetest1);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest1);

  Label donetest2;
  __ movq(RDX, Immediate(4));
  __ movq(RCX, Immediate(4));
  __ testq(RDX, RCX);
  __ j(NOT_EQUAL, &donetest2);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest2);

  Label donetest3;
  __ movq(RAX, Immediate(0));
  __ testq(RAX, Immediate(0));
  __ j(EQUAL, &donetest3);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest3);

  Label donetest4;
  __ movq(RCX, Immediate(4));
  __ testq(RCX, Immediate(4));
  __ j(NOT_EQUAL, &donetest4);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest4);

  Label donetest5;
  __ movq(RCX, Immediate(0xff));
  __ testq(RCX, Immediate(0xff));
  __ j(NOT_EQUAL, &donetest5);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest5);

  Label donetest6;
  __ movq(RAX, Immediate(0xff));
  __ testq(RAX, Immediate(0xff));
  __ j(NOT_EQUAL, &donetest6);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest6);

  __ movq(RAX, Immediate(0));
  __ ret();
}

ASSEMBLER_TEST_RUN(LogicalTestQ, test) {
  typedef int (*LogicalTestCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalTestCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,4\n"
      "movl rcx,2\n"
      "testq rax,rcx\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movq [rax],rax\n"
      "movl rdx,4\n"
      "movl rcx,4\n"
      "testq rdx,rcx\n"
      "jnz 0x................\n"
      "movl rax,0\n"
      "movq [rax],rax\n"
      "movl rax,0\n"
      "test al,0\n"
      "jz 0x................\n"
      "movl rax,0\n"
      "movq [rax],rax\n"
      "movl rcx,4\n"
      "testb rcx,4\n"
      "jnz 0x................\n"
      "movl rax,0\n"
      "movq [rax],rax\n"
      "movl rcx,0xff\n"
      "testb rcx,0xff\n"
      "jnz 0x................\n"
      "movl rax,0\n"
      "movq [rax],rax\n"
      "movl rax,0xff\n"
      "test al,0xff\n"
      "jnz 0x................\n"
      "movl rax,0\n"
      "movq [rax],rax\n"
      "movl rax,0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CompareSwapEQ, assembler) {
  __ movq(RAX, Immediate(0));
  __ pushq(RAX);
  __ movq(RAX, Immediate(4));
  __ movq(RCX, Immediate(0));
  __ movq(Address(RSP, 0), RAX);
  __ LockCmpxchgq(Address(RSP, 0), RCX);
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(CompareSwapEQ, test) {
  typedef int (*CompareSwapEQCode)();
  EXPECT_EQ(0, reinterpret_cast<CompareSwapEQCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,0\n"
      "push rax\n"
      "movl rax,4\n"
      "movl rcx,0\n"
      "movq [rsp],rax\n"
      "lock cmpxchgq rcx,[rsp]\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CompareSwapNEQ, assembler) {
  __ movq(RAX, Immediate(0));
  __ pushq(RAX);
  __ movq(RAX, Immediate(2));
  __ movq(RCX, Immediate(4));
  __ movq(Address(RSP, 0), RCX);
  __ LockCmpxchgq(Address(RSP, 0), RCX);
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(CompareSwapNEQ, test) {
  typedef int (*CompareSwapNEQCode)();
  EXPECT_EQ(4, reinterpret_cast<CompareSwapNEQCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,0\n"
      "push rax\n"
      "movl rax,2\n"
      "movl rcx,4\n"
      "movq [rsp],rcx\n"
      "lock cmpxchgq rcx,[rsp]\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CompareSwapEQ32, assembler) {
  __ movq(RAX, Immediate(0x100000000));
  __ pushq(RAX);
  __ movq(RAX, Immediate(4));
  __ movq(RCX, Immediate(0));
  // 32 bit store of 4.
  __ movl(Address(RSP, 0), RAX);
  // Compare 32 bit memory location with RAX (4) and write 0.
  __ LockCmpxchgl(Address(RSP, 0), RCX);
  // Pop unchanged high word and zeroed out low word.
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(CompareSwapEQ32, test) {
  typedef intptr_t (*CompareSwapEQ32Code)();
  EXPECT_EQ(0x100000000,
            reinterpret_cast<CompareSwapEQ32Code>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "push rax\n"
      "movl rax,4\n"
      "movl rcx,0\n"
      "movl [rsp],rax\n"
      "lock cmpxchgl rcx,[rsp]\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CompareSwapNEQ32, assembler) {
  __ movq(RAX, Immediate(0x100000000));
  __ pushq(RAX);
  __ movq(RAX, Immediate(2));
  __ movq(RCX, Immediate(4));
  __ movl(Address(RSP, 0), RCX);
  __ LockCmpxchgl(Address(RSP, 0), RCX);
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(CompareSwapNEQ32, test) {
  typedef intptr_t (*CompareSwapNEQ32Code)();
  EXPECT_EQ(0x100000004l,
            reinterpret_cast<CompareSwapNEQ32Code>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "push rax\n"
      "movl rax,2\n"
      "movl rcx,4\n"
      "movl [rsp],rcx\n"
      "lock cmpxchgl rcx,[rsp]\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Exchange, assembler) {
  __ movq(RAX, Immediate(kLargeConstant));
  __ movq(RDX, Immediate(kAnotherLargeConstant));
  __ xchgq(RAX, RDX);
  __ subq(RAX, RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Exchange, test) {
  typedef int64_t (*Exchange)();
  EXPECT_EQ(kAnotherLargeConstant - kLargeConstant,
            reinterpret_cast<Exchange>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "movq rdx,0x................\n"
      "xchgq rax,rdx\n"
      "subq rax,rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LargeConstant, assembler) {
  __ movq(RAX, Immediate(kLargeConstant));
  __ ret();
}

ASSEMBLER_TEST_RUN(LargeConstant, test) {
  typedef int64_t (*LargeConstantCode)();
  EXPECT_EQ(kLargeConstant,
            reinterpret_cast<LargeConstantCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "ret\n");
}

static int ComputeStackSpaceReservation(int needed, int fixed) {
  return (OS::ActivationFrameAlignment() > 1)
             ? Utils::RoundUp(needed + fixed, OS::ActivationFrameAlignment()) -
                   fixed
             : needed;
}

static int LeafReturn42() {
  return 42;
}

static int LeafReturnArgument(int x) {
  return x + 87;
}

ASSEMBLER_TEST_GENERATE(CallSimpleLeaf, assembler) {
  ExternalLabel call1(reinterpret_cast<uword>(LeafReturn42));
  ExternalLabel call2(reinterpret_cast<uword>(LeafReturnArgument));
  int space = ComputeStackSpaceReservation(0, 8);
  __ subq(RSP, Immediate(space));
  __ call(&call1);
  __ addq(RSP, Immediate(space));
  space = ComputeStackSpaceReservation(0, 8);
  __ subq(RSP, Immediate(space));
  __ movl(CallingConventions::kArg1Reg, RAX);
  __ call(&call2);
  __ addq(RSP, Immediate(space));
  __ ret();
}

ASSEMBLER_TEST_RUN(CallSimpleLeaf, test) {
  typedef int (*CallSimpleLeafCode)();
  EXPECT_EQ(42 + 87, reinterpret_cast<CallSimpleLeafCode>(test->entry())());
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "call r11\n"
      "addq rsp,8\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(JumpSimpleLeaf, assembler) {
  ExternalLabel call1(reinterpret_cast<uword>(LeafReturn42));
  Label L;
  int space = ComputeStackSpaceReservation(0, 8);
  __ subq(RSP, Immediate(space));
  __ call(&L);
  __ addq(RSP, Immediate(space));
  __ ret();
  __ Bind(&L);
  __ jmp(&call1);
}

ASSEMBLER_TEST_RUN(JumpSimpleLeaf, test) {
  typedef int (*JumpSimpleLeafCode)();
  EXPECT_EQ(42, reinterpret_cast<JumpSimpleLeafCode>(test->entry())());
  EXPECT_DISASSEMBLY_ENDS_WITH("jmp r11\n");
}

ASSEMBLER_TEST_GENERATE(JumpIndirect, assembler) {
  ExternalLabel call1(reinterpret_cast<uword>(LeafReturn42));
  __ movq(Address(CallingConventions::kArg1Reg, 0), Immediate(call1.address()));
  __ jmp(Address(CallingConventions::kArg1Reg, 0));
}

ASSEMBLER_TEST_RUN(JumpIndirect, test) {
  uword temp = 0;
  typedef int (*JumpIndirect)(uword*);
  EXPECT_EQ(42, reinterpret_cast<JumpIndirect>(test->entry())(&temp));
}

ASSEMBLER_TEST_GENERATE(SingleFPMoves, assembler) {
  __ movq(RAX, Immediate(bit_cast<int32_t, float>(234.0f)));
  __ movd(XMM0, RAX);
  __ movss(XMM1, XMM0);
  __ movss(XMM2, XMM1);
  __ movss(XMM3, XMM2);
  __ movss(XMM4, XMM3);
  __ movss(XMM5, XMM4);
  __ movss(XMM6, XMM5);
  __ movss(XMM7, XMM6);
  __ movss(XMM8, XMM7);
  __ movss(XMM9, XMM8);
  __ movss(XMM10, XMM9);
  __ movss(XMM11, XMM10);
  __ movss(XMM12, XMM11);
  __ movss(XMM13, XMM12);
  __ movss(XMM14, XMM13);
  __ movss(XMM15, XMM14);
  __ pushq(R15);  // Callee saved.
  __ pushq(RAX);
  __ movq(Address(RSP, 0), Immediate(0));
  __ movss(XMM0, Address(RSP, 0));
  __ movss(Address(RSP, 0), XMM7);
  __ movss(XMM1, Address(RSP, 0));
  __ movq(R10, RSP);
  __ movss(Address(R10, 0), XMM1);
  __ movss(XMM2, Address(R10, 0));
  __ movq(R15, RSP);
  __ movss(Address(R15, 0), XMM2);
  __ movss(XMM3, Address(R15, 0));
  __ movq(RAX, RSP);
  __ movss(Address(RAX, 0), XMM3);
  __ movss(XMM1, Address(RAX, 0));
  __ movss(XMM15, Address(RAX, 0));
  __ movss(XMM14, XMM15);
  __ movss(XMM13, XMM14);
  __ movss(XMM12, XMM13);
  __ movss(XMM11, XMM12);
  __ movss(XMM10, XMM11);
  __ movss(XMM9, XMM10);
  __ movss(XMM8, XMM9);
  __ movss(XMM7, XMM8);
  __ movss(XMM6, XMM7);
  __ movss(XMM5, XMM6);
  __ movss(XMM4, XMM5);
  __ movss(XMM3, XMM4);
  __ movss(XMM2, XMM3);
  __ movss(XMM1, XMM2);
  __ movss(XMM0, XMM1);
  __ popq(RAX);
  __ popq(R15);  // Callee saved.
  __ ret();
}

ASSEMBLER_TEST_RUN(SingleFPMoves, test) {
  typedef float (*SingleFPMovesCode)();
  EXPECT_EQ(234, reinterpret_cast<SingleFPMovesCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "movss rcx,xmm0\n"
      "movss rdx,xmm1\n"
      "movss rbx,xmm2\n"
      "movss rsp,xmm3\n"
      "movss rbp,xmm4\n"
      "movss rsi,xmm5\n"
      "movss rdi,xmm6\n"
      "movss r8,xmm7\n"
      "movss r9,xmm8\n"
      "movss r10,xmm9\n"
      "movss r11,xmm10\n"
      "movss r12,xmm11\n"
      "movss r13,xmm12\n"
      "movss thr,xmm13\n"
      "movss pp,xmm14\n"
      "push pp\n"
      "push rax\n"
      "movq [rsp],0\n"
      "movss xmm0,[rsp]\n"
      "movss [rsp],xmm7\n"
      "movss xmm1,[rsp]\n"
      "movq r10,rsp\n"
      "movss [r10],xmm1\n"
      "movss xmm2,[r10]\n"
      "movq pp,rsp\n"
      "movss [pp],xmm2\n"
      "movss xmm3,[pp]\n"
      "movq rax,rsp\n"
      "movss [rax],xmm3\n"
      "movss xmm1,[rax]\n"
      "movss xmm15,[rax]\n"
      "movss thr,xmm15\n"
      "movss r13,xmm14\n"
      "movss r12,xmm13\n"
      "movss r11,xmm12\n"
      "movss r10,xmm11\n"
      "movss r9,xmm10\n"
      "movss r8,xmm9\n"
      "movss rdi,xmm8\n"
      "movss rsi,xmm7\n"
      "movss rbp,xmm6\n"
      "movss rsp,xmm5\n"
      "movss rbx,xmm4\n"
      "movss rdx,xmm3\n"
      "movss rcx,xmm2\n"
      "movss rax,xmm1\n"
      "pop rax\n"
      "pop pp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SingleFPMoves2, assembler) {
  __ movq(RAX, Immediate(bit_cast<int32_t, float>(234.0f)));
  __ movd(XMM0, RAX);
  __ movd(XMM8, RAX);
  __ movss(XMM1, XMM8);
  __ pushq(RAX);
  __ movq(Address(RSP, 0), Immediate(0));
  __ movss(XMM0, Address(RSP, 0));
  __ movss(Address(RSP, 0), XMM1);
  __ movss(XMM0, Address(RSP, 0));
  __ movq(Address(RSP, 0), Immediate(0));
  __ movss(XMM9, XMM8);
  __ movss(Address(RSP, 0), XMM9);
  __ movss(XMM8, Address(RSP, 0));
  __ movss(XMM0, XMM8);
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SingleFPMoves2, test) {
  typedef float (*SingleFPMoves2Code)();
  EXPECT_EQ(234, reinterpret_cast<SingleFPMoves2Code>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "movd xmm8,rax\n"
      "movss rcx,xmm8\n"
      "push rax\n"
      "movq [rsp],0\n"
      "movss xmm0,[rsp]\n"
      "movss [rsp],xmm1\n"
      "movss xmm0,[rsp]\n"
      "movq [rsp],0\n"
      "movss r9,xmm8\n"
      "movss [rsp],xmm9\n"
      "movss xmm8,[rsp]\n"
      "movss rax,xmm8\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(MovqXmmToCpu, assembler) {
  __ movq(RAX, Immediate(bit_cast<int32_t, float>(234.5f)));
  __ movd(XMM0, RAX);
  __ cvtss2sd(XMM0, XMM0);
  __ movq(RAX, XMM0);
  __ ret();
}

ASSEMBLER_TEST_RUN(MovqXmmToCpu, test) {
  typedef uint64_t (*MovqXmmToCpuCode)();
  EXPECT_EQ((bit_cast<uint64_t, double>(234.5f)),
            reinterpret_cast<MovqXmmToCpuCode>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "cvtss2sd xmm0,xmm0\n"
      "movq rax,xmm0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedDoubleAdd, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = {1.0, 2.0};
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = {3.0, 4.0};
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant1)));
  __ movups(XMM11, Address(RAX, 0));
  __ addpd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedDoubleAdd, test) {
  typedef double (*PackedDoubleAdd)();
  double res = reinterpret_cast<PackedDoubleAdd>(test->entry())();
  EXPECT_FLOAT_EQ(4.0, res, 0.000001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm11,[rax]\n"
      "addpd xmm10,xmm11\n"
      "movaps xmm0,xmm10\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedDoubleSub, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = {1.0, 2.0};
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = {3.0, 4.0};
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant1)));
  __ movups(XMM11, Address(RAX, 0));
  __ subpd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedDoubleSub, test) {
  typedef double (*PackedDoubleSub)();
  double res = reinterpret_cast<PackedDoubleSub>(test->entry())();
  EXPECT_FLOAT_EQ(-2.0, res, 0.000001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm11,[rax]\n"
      "subpd xmm10,xmm11\n"
      "movaps xmm0,xmm10\n"
      "ret\n");
}

static void EnterTestFrame(Assembler* assembler) {
  COMPILE_ASSERT(THR != CallingConventions::kArg1Reg);
  COMPILE_ASSERT(CODE_REG != CallingConventions::kArg2Reg);
  __ EnterFrame(0);
  __ pushq(CODE_REG);
  __ pushq(PP);
  __ pushq(THR);
  __ movq(CODE_REG, Address(CallingConventions::kArg1Reg,
                            VMHandles::kOffsetOfRawPtrInHandle));
  __ movq(THR, CallingConventions::kArg2Reg);
  __ LoadPoolPointer(PP);
}

static void LeaveTestFrame(Assembler* assembler) {
  __ popq(THR);
  __ popq(PP);
  __ popq(CODE_REG);
  __ LeaveFrame();
}

ASSEMBLER_TEST_GENERATE(PackedDoubleNegate, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = {1.0, 2.0};
  EnterTestFrame(assembler);
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ negatepd(XMM10, XMM10);
  __ movaps(XMM0, XMM10);
  LeaveTestFrame(assembler);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedDoubleNegate, test) {
  double res = test->InvokeWithCodeAndThread<double>();
  EXPECT_FLOAT_EQ(-1.0, res, 0.000001f);
  EXPECT_DISASSEMBLY_NOT_WINDOWS_ENDS_WITH(
      "movups xmm10,[rax]\n"
      "movq r11,[thr+0x...]\n"
      "xorpd xmm10,[r11]\n"
      "movaps xmm0,xmm10\n"
      "pop thr\n"
      "pop pp\n"
      "pop r12\n"
      "movq rsp,rbp\n"
      "pop rbp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedDoubleAbsolute, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = {-1.0, 2.0};
  EnterTestFrame(assembler);
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ abspd(XMM0, XMM10);
  LeaveTestFrame(assembler);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedDoubleAbsolute, test) {
  double res = test->InvokeWithCodeAndThread<double>();
  EXPECT_FLOAT_EQ(1.0, res, 0.000001f);
  EXPECT_DISASSEMBLY_NOT_WINDOWS_ENDS_WITH(
      "movups xmm10,[rax]\n"
      "movq r11,[thr+0x...]\n"
      "movups xmm0,[r11]\n"
      "andpd xmm0,xmm10\n"
      "pop thr\n"
      "pop pp\n"
      "pop r12\n"
      "movq rsp,rbp\n"
      "pop rbp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedDoubleMul, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = {3.0, 2.0};
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = {3.0, 4.0};
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant1)));
  __ movups(XMM11, Address(RAX, 0));
  __ mulpd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedDoubleMul, test) {
  typedef double (*PackedDoubleMul)();
  double res = reinterpret_cast<PackedDoubleMul>(test->entry())();
  EXPECT_FLOAT_EQ(9.0, res, 0.000001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm11,[rax]\n"
      "mulpd xmm10,xmm11\n"
      "movaps xmm0,xmm10\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedDoubleDiv, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = {9.0, 2.0};
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = {3.0, 4.0};
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant1)));
  __ movups(XMM11, Address(RAX, 0));
  __ divpd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedDoubleDiv, test) {
  typedef double (*PackedDoubleDiv)();
  double res = reinterpret_cast<PackedDoubleDiv>(test->entry())();
  EXPECT_FLOAT_EQ(3.0, res, 0.000001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm11,[rax]\n"
      "divpd xmm10,xmm11\n"
      "movaps xmm0,xmm10\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedDoubleSqrt, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = {16.0, 2.0};
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ sqrtpd(XMM10, XMM10);
  __ movaps(XMM0, XMM10);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedDoubleSqrt, test) {
  typedef double (*PackedDoubleSqrt)();
  double res = reinterpret_cast<PackedDoubleSqrt>(test->entry())();
  EXPECT_FLOAT_EQ(4.0, res, 0.000001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm10,[rax]\n"
      "sqrtpd xmm10,xmm10\n"
      "movaps xmm0,xmm10\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedDoubleMin, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = {9.0, 2.0};
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = {3.0, 4.0};
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant1)));
  __ movups(XMM11, Address(RAX, 0));
  __ minpd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedDoubleMin, test) {
  typedef double (*PackedDoubleMin)();
  double res = reinterpret_cast<PackedDoubleMin>(test->entry())();
  EXPECT_FLOAT_EQ(3.0, res, 0.000001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm11,[rax]\n"
      "minpd xmm10,xmm11\n"
      "movaps xmm0,xmm10\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedDoubleMax, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = {9.0, 2.0};
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = {3.0, 4.0};
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant1)));
  __ movups(XMM11, Address(RAX, 0));
  __ maxpd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedDoubleMax, test) {
  typedef double (*PackedDoubleMax)();
  double res = reinterpret_cast<PackedDoubleMax>(test->entry())();
  EXPECT_FLOAT_EQ(9.0, res, 0.000001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm11,[rax]\n"
      "maxpd xmm10,xmm11\n"
      "movaps xmm0,xmm10\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedDoubleShuffle, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = {2.0, 9.0};
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  // Splat Y across all lanes.
  __ shufpd(XMM10, XMM10, Immediate(0x33));
  // Splat X across all lanes.
  __ shufpd(XMM10, XMM10, Immediate(0x0));
  // Set return value.
  __ movaps(XMM0, XMM10);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedDoubleShuffle, test) {
  typedef double (*PackedDoubleShuffle)();
  double res = reinterpret_cast<PackedDoubleShuffle>(test->entry())();
  EXPECT_FLOAT_EQ(9.0, res, 0.000001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm10,[rax]\n"
      "shufpd xmm10, xmm10 [33]\n"
      "shufpd xmm10, xmm10 [0]\n"
      "movaps xmm0,xmm10\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedDoubleToSingle, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = {9.0, 2.0};
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM11, Address(RAX, 0));
  __ cvtpd2ps(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedDoubleToSingle, test) {
  typedef float (*PackedDoubleToSingle)();
  float res = reinterpret_cast<PackedDoubleToSingle>(test->entry())();
  EXPECT_FLOAT_EQ(9.0f, res, 0.000001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm11,[rax]\n"
      "cvtpd2ps xmm10,xmm11\n"
      "movaps xmm0,xmm10\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedSingleToDouble, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = {9.0f, 2.0f, 3.0f, 4.0f};
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM11, Address(RAX, 0));
  __ cvtps2pd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedSingleToDouble, test) {
  typedef double (*PackedSingleToDouble)();
  double res = reinterpret_cast<PackedSingleToDouble>(test->entry())();
  EXPECT_FLOAT_EQ(9.0f, res, 0.000001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm11,[rax]\n"
      "cvtps2pd xmm10,xmm11\n"
      "movaps xmm0,xmm10\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SingleFPOperations, assembler) {
  __ pushq(RBX);
  __ pushq(RCX);
  __ movq(RBX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ movd(XMM0, RBX);
  __ movd(XMM8, RBX);
  __ movq(RCX, Immediate(bit_cast<int32_t, float>(3.4f)));
  __ movd(XMM1, RCX);
  __ movd(XMM9, RCX);
  __ addss(XMM0, XMM1);  // 15.7f
  __ mulss(XMM0, XMM1);  // 53.38f
  __ subss(XMM0, XMM1);  // 49.98f
  __ divss(XMM0, XMM1);  // 14.7f
  __ addss(XMM8, XMM9);  // 15.7f
  __ mulss(XMM8, XMM9);  // 53.38f
  __ subss(XMM8, XMM9);  // 49.98f
  __ divss(XMM8, XMM9);  // 14.7f
  __ subss(XMM0, XMM8);  // 0.0f
  __ popq(RCX);
  __ popq(RBX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SingleFPOperations, test) {
  typedef float (*SingleFPOperationsCode)();
  float res = reinterpret_cast<SingleFPOperationsCode>(test->entry())();
  EXPECT_FLOAT_EQ(0.0f, res, 0.001f);
  EXPECT_DISASSEMBLY(
      "push rbx\n"
      "push rcx\n"
      "movl rbx,0x........\n"
      "movd xmm0,rbx\n"
      "movd xmm8,rbx\n"
      "movl rcx,0x........\n"
      "movd xmm1,rcx\n"
      "movd xmm9,rcx\n"
      "addss xmm0,xmm1\n"
      "mulss xmm0,xmm1\n"
      "subss xmm0,xmm1\n"
      "divss xmm0,xmm1\n"
      "addss xmm8,xmm9\n"
      "mulss xmm8,xmm9\n"
      "subss xmm8,xmm9\n"
      "divss xmm8,xmm9\n"
      "subss xmm0,xmm8\n"
      "pop rcx\n"
      "pop rbx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedFPOperations, assembler) {
  __ movq(RAX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ movd(XMM10, RAX);
  __ shufps(XMM10, XMM10, Immediate(0x0));
  __ movq(RAX, Immediate(bit_cast<int32_t, float>(3.4f)));
  __ movd(XMM9, RAX);
  __ shufps(XMM9, XMM9, Immediate(0x0));
  __ addps(XMM10, XMM9);  // 15.7f
  __ mulps(XMM10, XMM9);  // 53.38f
  __ subps(XMM10, XMM9);  // 49.98f
  __ divps(XMM10, XMM9);  // 14.7f
  __ movaps(XMM0, XMM10);
  __ shufps(XMM0, XMM0, Immediate(0x55));  // Copy second lane into all 4 lanes.
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedFPOperations, test) {
  typedef float (*PackedFPOperationsCode)();
  float res = reinterpret_cast<PackedFPOperationsCode>(test->entry())();
  EXPECT_FLOAT_EQ(14.7f, res, 0.001f);
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "movd xmm10,rax\n"
      "shufps xmm10,xmm10 [0]\n"
      "movl rax,0x........\n"
      "movd xmm9,rax\n"
      "shufps xmm9,xmm9 [0]\n"
      "addps xmm10,xmm9\n"
      "mulps xmm10,xmm9\n"
      "subps xmm10,xmm9\n"
      "divps xmm10,xmm9\n"
      "movaps xmm0,xmm10\n"
      "shufps xmm0,xmm0 [55]\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedIntOperations, assembler) {
  __ movl(RAX, Immediate(0x2));
  __ movd(XMM0, RAX);
  __ shufps(XMM0, XMM0, Immediate(0x0));
  __ movl(RAX, Immediate(0x1));
  __ movd(XMM1, RAX);
  __ shufps(XMM1, XMM1, Immediate(0x0));
  __ addpl(XMM0, XMM1);  // 0x3
  __ addpl(XMM0, XMM0);  // 0x6
  __ subpl(XMM0, XMM1);  // 0x5
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedIntOperations, test) {
  typedef uint32_t (*PackedIntOperationsCode)();
  uint32_t res = reinterpret_cast<PackedIntOperationsCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x5), res);
  EXPECT_DISASSEMBLY(
      "movl rax,2\n"
      "movd xmm0,rax\n"
      "shufps xmm0,xmm0 [0]\n"
      "movl rax,1\n"
      "movd xmm1,rax\n"
      "shufps xmm1,xmm1 [0]\n"
      "paddd xmm0,xmm1\n"
      "paddd xmm0,xmm0\n"
      "psubd xmm0,xmm1\n"
      "push rax\n"
      "movss [rsp],xmm0\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedIntOperations2, assembler) {
  // Note: on Windows 64 XMM6-XMM15 are callee save.
  const intptr_t cpu_register_set = 0;
  const intptr_t fpu_register_set =
      ((1 << XMM10) | (1 << XMM11)) & CallingConventions::kVolatileXmmRegisters;
  const RegisterSet register_set(cpu_register_set, fpu_register_set);
  __ PushRegisters(register_set);
  __ movl(RAX, Immediate(0x2));
  __ movd(XMM10, RAX);
  __ shufps(XMM10, XMM10, Immediate(0x0));
  __ movl(RAX, Immediate(0x1));
  __ movd(XMM11, RAX);
  __ shufps(XMM11, XMM11, Immediate(0x0));
  __ addpl(XMM10, XMM11);  // 0x3
  __ addpl(XMM10, XMM10);  // 0x6
  __ subpl(XMM10, XMM11);  // 0x5
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM10);
  __ popq(RAX);
  __ PopRegisters(register_set);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedIntOperations2, test) {
  typedef uint32_t (*PackedIntOperationsCode)();
  uint32_t res = reinterpret_cast<PackedIntOperationsCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x5), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "subq rsp,0x20\n"
      "movups [rsp],xmm10\n"
      "movups [rsp+0x10],xmm11\n"
      "movl rax,2\n"
      "movd xmm10,rax\n"
      "shufps xmm10,xmm10 [0]\n"
      "movl rax,1\n"
      "movd xmm11,rax\n"
      "shufps xmm11,xmm11 [0]\n"
      "paddd xmm10,xmm11\n"
      "paddd xmm10,xmm10\n"
      "psubd xmm10,xmm11\n"
      "push rax\n"
      "movss [rsp],xmm10\n"
      "pop rax\n"
      "movups xmm10,[rsp]\n"
      "movups xmm11,[rsp+0x10]\n"
      "addq rsp,0x20\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedFPOperations2, assembler) {
  __ movq(RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ movd(XMM0, RAX);
  __ shufps(XMM0, XMM0, Immediate(0x0));

  __ movaps(XMM11, XMM0);                  // Copy XMM0
  __ rcpps(XMM11, XMM11);                  // 0.25
  __ sqrtps(XMM11, XMM11);                 // 0.5
  __ rsqrtps(XMM0, XMM0);                  // ~0.5
  __ subps(XMM0, XMM11);                   // ~0.0
  __ shufps(XMM0, XMM0, Immediate(0x00));  // Copy second lane into all 4 lanes.
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedFPOperations2, test) {
  typedef float (*PackedFPOperations2Code)();
  float res = reinterpret_cast<PackedFPOperations2Code>(test->entry())();
  EXPECT_FLOAT_EQ(0.0f, res, 0.001f);
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "shufps xmm0,xmm0 [0]\n"
      "movaps xmm11,xmm0\n"
      "rcpps xmm11,xmm11\n"
      "sqrtps xmm11,xmm11\n"
      "rsqrtps xmm0,xmm0\n"
      "subps xmm0,xmm11\n"
      "shufps xmm0,xmm0 [0]\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedCompareEQ, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppseq(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedCompareEQ, test) {
  typedef uint32_t (*PackedCompareEQCode)();
  uint32_t res = reinterpret_cast<PackedCompareEQCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x0), res);
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "shufps xmm0,xmm0 [0]\n"
      "movl rax,0x........\n"
      "movd xmm1,rax\n"
      "shufps xmm1,xmm1 [0]\n"
      "cmpps xmm0,xmm1 [eq]\n"
      "push rax\n"
      "movss [rsp],xmm0\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(XmmAlu, assembler) {
  // Test the disassembler.
  __ addss(XMM0, XMM0);
  __ addsd(XMM0, XMM0);
  __ addps(XMM0, XMM0);
  __ addpd(XMM0, XMM0);
  __ cvtss2sd(XMM0, XMM0);
  __ cvtsd2ss(XMM0, XMM0);
  __ cvtps2pd(XMM0, XMM0);
  __ cvtpd2ps(XMM0, XMM0);
  __ movl(RAX, Immediate(0));
  __ ret();
}

ASSEMBLER_TEST_RUN(XmmAlu, test) {
  typedef intptr_t (*XmmAluTest)();
  intptr_t res = reinterpret_cast<XmmAluTest>(test->entry())();
  EXPECT_EQ(res, 0);
  EXPECT_DISASSEMBLY(
      "addss xmm0,xmm0\n"
      "addsd xmm0,xmm0\n"
      "addps xmm0,xmm0\n"
      "addpd xmm0,xmm0\n"
      "cvtss2sd xmm0,xmm0\n"
      "cvtsd2ss xmm0,xmm0\n"
      "cvtps2pd xmm0,xmm0\n"
      "cvtpd2ps xmm0,xmm0\n"
      "movl rax,0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedCompareNEQ, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppsneq(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedCompareNEQ, test) {
  typedef uint32_t (*PackedCompareNEQCode)();
  uint32_t res = reinterpret_cast<PackedCompareNEQCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0xFFFFFFFF), res);
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "shufps xmm0,xmm0 [0]\n"
      "movl rax,0x........\n"
      "movd xmm1,rax\n"
      "shufps xmm1,xmm1 [0]\n"
      "cmpps xmm0,xmm1 [neq]\n"
      "push rax\n"
      "movss [rsp],xmm0\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedCompareLT, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppslt(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedCompareLT, test) {
  typedef uint32_t (*PackedCompareLTCode)();
  uint32_t res = reinterpret_cast<PackedCompareLTCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0xFFFFFFFF), res);
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "shufps xmm0,xmm0 [0]\n"
      "movl rax,0x........\n"
      "movd xmm1,rax\n"
      "shufps xmm1,xmm1 [0]\n"
      "cmpps xmm0,xmm1 [lt]\n"
      "push rax\n"
      "movss [rsp],xmm0\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedCompareLE, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppsle(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedCompareLE, test) {
  typedef uint32_t (*PackedCompareLECode)();
  uint32_t res = reinterpret_cast<PackedCompareLECode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0xFFFFFFFF), res);
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "shufps xmm0,xmm0 [0]\n"
      "movl rax,0x........\n"
      "movd xmm1,rax\n"
      "shufps xmm1,xmm1 [0]\n"
      "cmpps xmm0,xmm1 [le]\n"
      "push rax\n"
      "movss [rsp],xmm0\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedCompareNLT, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppsnlt(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedCompareNLT, test) {
  typedef uint32_t (*PackedCompareNLTCode)();
  uint32_t res = reinterpret_cast<PackedCompareNLTCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x0), res);
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "shufps xmm0,xmm0 [0]\n"
      "movl rax,0x........\n"
      "movd xmm1,rax\n"
      "shufps xmm1,xmm1 [0]\n"
      "cmpps xmm0,xmm1 [nlt]\n"
      "push rax\n"
      "movss [rsp],xmm0\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedCompareNLE, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppsnle(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedCompareNLE, test) {
  typedef uint32_t (*PackedCompareNLECode)();
  uint32_t res = reinterpret_cast<PackedCompareNLECode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x0), res);
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "shufps xmm0,xmm0 [0]\n"
      "movl rax,0x........\n"
      "movd xmm1,rax\n"
      "shufps xmm1,xmm1 [0]\n"
      "cmpps xmm0,xmm1 [nle]\n"
      "push rax\n"
      "movss [rsp],xmm0\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedNegate, assembler) {
  EnterTestFrame(assembler);
  __ movl(RAX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ movd(XMM0, RAX);
  __ shufps(XMM0, XMM0, Immediate(0x0));
  __ negateps(XMM0, XMM0);
  __ shufps(XMM0, XMM0, Immediate(0xAA));  // Copy third lane into all 4 lanes.
  LeaveTestFrame(assembler);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedNegate, test) {
  float res = test->InvokeWithCodeAndThread<float>();
  EXPECT_FLOAT_EQ(-12.3f, res, 0.001f);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rbp\n"
      "movq rbp,rsp\n"
      "push r12\n"
      "push pp\n"
      "push thr\n"
      "movq r12,[rdi+0x8]\n"
      "movq thr,rsi\n"
      "movq pp,[r12+0x27]\n"
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "shufps xmm0,xmm0 [0]\n"
      "movq r11,[thr+0x...]\n"
      "xorps xmm0,[r11]\n"
      "shufps xmm0,xmm0 [aa]\n"
      "pop thr\n"
      "pop pp\n"
      "pop r12\n"
      "movq rsp,rbp\n"
      "pop rbp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedAbsolute, assembler) {
  EnterTestFrame(assembler);
  __ movl(RAX, Immediate(bit_cast<int32_t, float>(-15.3f)));
  __ movd(XMM0, RAX);
  __ shufps(XMM0, XMM0, Immediate(0x0));
  __ absps(XMM0, XMM0);
  __ shufps(XMM0, XMM0, Immediate(0xAA));  // Copy third lane into all 4 lanes.
  LeaveTestFrame(assembler);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedAbsolute, test) {
  float res = test->InvokeWithCodeAndThread<float>();
  EXPECT_FLOAT_EQ(15.3f, res, 0.001f);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rbp\n"
      "movq rbp,rsp\n"
      "push r12\n"
      "push pp\n"
      "push thr\n"
      "movq r12,[rdi+0x8]\n"
      "movq thr,rsi\n"
      "movq pp,[r12+0x27]\n"
      "movl rax,-0x........\n"
      "movd xmm0,rax\n"
      "shufps xmm0,xmm0 [0]\n"
      "movq r11,[thr+0x...]\n"
      "andps xmm0,[r11]\n"
      "shufps xmm0,xmm0 [aa]\n"
      "pop thr\n"
      "pop pp\n"
      "pop r12\n"
      "movq rsp,rbp\n"
      "pop rbp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedSetWZero, assembler) {
  EnterTestFrame(assembler);
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ zerowps(XMM0, XMM0);
  __ shufps(XMM0, XMM0, Immediate(0xFF));  // Copy the W lane which is now 0.0.
  LeaveTestFrame(assembler);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedSetWZero, test) {
  float res = test->InvokeWithCodeAndThread<float>();
  EXPECT_FLOAT_EQ(0.0f, res, 0.001f);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rbp\n"
      "movq rbp,rsp\n"
      "push r12\n"
      "push pp\n"
      "push thr\n"
      "movq r12,[rdi+0x8]\n"
      "movq thr,rsi\n"
      "movq pp,[r12+0x27]\n"
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "shufps xmm0,xmm0 [0]\n"
      "movq r11,[thr+0x...]\n"
      "andps xmm0,[r11]\n"
      "shufps xmm0,xmm0 [ff]\n"
      "pop thr\n"
      "pop pp\n"
      "pop r12\n"
      "movq rsp,rbp\n"
      "pop rbp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedMin, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ minps(XMM0, XMM1);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedMin, test) {
  typedef float (*PackedMinCode)();
  float res = reinterpret_cast<PackedMinCode>(test->entry())();
  EXPECT_FLOAT_EQ(2.0f, res, 0.001f);
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "shufps xmm0,xmm0 [0]\n"
      "movl rax,0x........\n"
      "movd xmm1,rax\n"
      "shufps xmm1,xmm1 [0]\n"
      "minps xmm0,xmm1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedMax, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ maxps(XMM0, XMM1);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedMax, test) {
  typedef float (*PackedMaxCode)();
  float res = reinterpret_cast<PackedMaxCode>(test->entry())();
  EXPECT_FLOAT_EQ(4.0f, res, 0.001f);
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "movd xmm0,rax\n"
      "shufps xmm0,xmm0 [0]\n"
      "movl rax,0x........\n"
      "movd xmm1,rax\n"
      "shufps xmm1,xmm1 [0]\n"
      "maxps xmm0,xmm1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedLogicalOr, assembler) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } constant1 = {0xF0F0F0F0, 0xF0F0F0F0, 0xF0F0F0F0, 0xF0F0F0F0};
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } constant2 = {0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F};
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM0, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant2)));
  __ movups(XMM1, Address(RAX, 0));
  __ orps(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedLogicalOr, test) {
  typedef uint32_t (*PackedLogicalOrCode)();
  uint32_t res = reinterpret_cast<PackedLogicalOrCode>(test->entry())();
  EXPECT_EQ(0xFFFFFFFF, res);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm1,[rax]\n"
      "orps xmm0,xmm1\n"
      "push rax\n"
      "movss [rsp],xmm0\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedLogicalAnd, assembler) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } constant1 = {0xF0F0F0F0, 0xF0F0F0F0, 0xF0F0F0F0, 0xF0F0F0F0};
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } constant2 = {0x0F0FFF0F, 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F};
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM0, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant2)));
  __ andps(XMM0, Address(RAX, 0));
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedLogicalAnd, test) {
  typedef uint32_t (*PackedLogicalAndCode)();
  uint32_t res = reinterpret_cast<PackedLogicalAndCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x0000F000), res);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "andps xmm0,[rax]\n"
      "push rax\n"
      "movss [rsp],xmm0\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedLogicalNot, assembler) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } constant1 = {0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF};
  EnterTestFrame(assembler);
  __ LoadImmediate(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM9, Address(RAX, 0));
  __ notps(XMM0, XMM9);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  LeaveTestFrame(assembler);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedLogicalNot, test) {
  uint32_t res = test->InvokeWithCodeAndThread<uint32_t>();
  EXPECT_EQ(static_cast<uword>(0x0), res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS_ENDS_WITH(
      "movups xmm9,[rax]\n"
      "movq r11,[thr+0x...]\n"
      "movups xmm0,[r11]\n"
      "xorps xmm0,xmm9\n"
      "push rax\n"
      "movss [rsp],xmm0\n"
      "pop rax\n"
      "pop thr\n"
      "pop pp\n"
      "pop r12\n"
      "movq rsp,rbp\n"
      "pop rbp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedMoveHighLow, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = {1.0, 2.0, 3.0, 4.0};
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = {5.0, 6.0, 7.0, 8.0};
  // XMM9 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant0)));
  __ movups(XMM9, Address(RAX, 0));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM1, Address(RAX, 0));
  // XMM9 = 7.0f, 8.0f, 3.0f, 4.0f.
  __ movhlps(XMM9, XMM1);
  __ xorps(XMM1, XMM1);
  // XMM1 = 7.0f, 8.0f, 3.0f, 4.0f.
  __ movaps(XMM1, XMM9);
  __ shufps(XMM9, XMM9, Immediate(0x00));  // 7.0f.
  __ shufps(XMM1, XMM1, Immediate(0x55));  // 8.0f.
  __ addss(XMM9, XMM1);                    // 15.0f.
  __ movaps(XMM0, XMM9);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedMoveHighLow, test) {
  typedef float (*PackedMoveHighLow)();
  float res = reinterpret_cast<PackedMoveHighLow>(test->entry())();
  EXPECT_FLOAT_EQ(15.0f, res, 0.001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm1,[rax]\n"
      "movhlps xmm9,xmm1\n"
      "xorps xmm1,xmm1\n"
      "movaps xmm1,xmm9\n"
      "shufps xmm9,xmm9 [0]\n"
      "shufps xmm1,xmm1 [55]\n"
      "addss xmm9,xmm1\n"
      "movaps xmm0,xmm9\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedMoveLowHigh, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = {1.0, 2.0, 3.0, 4.0};
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = {5.0, 6.0, 7.0, 8.0};
  // XMM9 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant0)));
  __ movups(XMM9, Address(RAX, 0));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM1, Address(RAX, 0));
  // XMM9 = 1.0f, 2.0f, 5.0f, 6.0f
  __ movlhps(XMM9, XMM1);
  __ xorps(XMM1, XMM1);
  // XMM1 = 1.0f, 2.0f, 5.0f, 6.0f
  __ movaps(XMM1, XMM9);
  __ shufps(XMM9, XMM9, Immediate(0xAA));  // 5.0f.
  __ shufps(XMM1, XMM1, Immediate(0xFF));  // 6.0f.
  __ addss(XMM9, XMM1);                    // 11.0f.
  __ movaps(XMM0, XMM9);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedMoveLowHigh, test) {
  typedef float (*PackedMoveLowHigh)();
  float res = reinterpret_cast<PackedMoveLowHigh>(test->entry())();
  EXPECT_FLOAT_EQ(11.0f, res, 0.001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm1,[rax]\n"
      "movlhps xmm9,xmm1\n"
      "xorps xmm1,xmm1\n"
      "movaps xmm1,xmm9\n"
      "shufps xmm9,xmm9 [aa]\n"
      "shufps xmm1,xmm1 [ff]\n"
      "addss xmm9,xmm1\n"
      "movaps xmm0,xmm9\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedUnpackLow, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = {1.0, 2.0, 3.0, 4.0};
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = {5.0, 6.0, 7.0, 8.0};
  // XMM9 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant0)));
  __ movups(XMM9, Address(RAX, 0));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM1, Address(RAX, 0));
  // XMM9 = 1.0f, 5.0f, 2.0f, 6.0f.
  __ unpcklps(XMM9, XMM1);
  // XMM1 = 1.0f, 5.0f, 2.0f, 6.0f.
  __ movaps(XMM1, XMM9);
  __ shufps(XMM9, XMM9, Immediate(0x55));
  __ shufps(XMM1, XMM1, Immediate(0xFF));
  __ addss(XMM9, XMM1);  // 11.0f.
  __ movaps(XMM0, XMM9);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedUnpackLow, test) {
  typedef float (*PackedUnpackLow)();
  float res = reinterpret_cast<PackedUnpackLow>(test->entry())();
  EXPECT_FLOAT_EQ(11.0f, res, 0.001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm1,[rax]\n"
      "unpcklps xmm9,xmm1\n"
      "movaps xmm1,xmm9\n"
      "shufps xmm9,xmm9 [55]\n"
      "shufps xmm1,xmm1 [ff]\n"
      "addss xmm9,xmm1\n"
      "movaps xmm0,xmm9\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedUnpackHigh, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = {1.0, 2.0, 3.0, 4.0};
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = {5.0, 6.0, 7.0, 8.0};
  // XMM9 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant0)));
  __ movups(XMM9, Address(RAX, 0));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM1, Address(RAX, 0));
  // XMM9 = 3.0f, 7.0f, 4.0f, 8.0f.
  __ unpckhps(XMM9, XMM1);
  // XMM1 = 3.0f, 7.0f, 4.0f, 8.0f.
  __ movaps(XMM1, XMM9);
  __ shufps(XMM9, XMM9, Immediate(0x00));
  __ shufps(XMM1, XMM1, Immediate(0xAA));
  __ addss(XMM9, XMM1);  // 7.0f.
  __ movaps(XMM0, XMM9);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedUnpackHigh, test) {
  typedef float (*PackedUnpackHigh)();
  float res = reinterpret_cast<PackedUnpackHigh>(test->entry())();
  EXPECT_FLOAT_EQ(7.0f, res, 0.001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm1,[rax]\n"
      "unpckhps xmm9,xmm1\n"
      "movaps xmm1,xmm9\n"
      "shufps xmm9,xmm9 [0]\n"
      "shufps xmm1,xmm1 [aa]\n"
      "addss xmm9,xmm1\n"
      "movaps xmm0,xmm9\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedUnpackLowPair, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = {1.0, 2.0, 3.0, 4.0};
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = {5.0, 6.0, 7.0, 8.0};
  // XMM9 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant0)));
  __ movups(XMM9, Address(RAX, 0));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM1, Address(RAX, 0));
  // XMM9 = 1.0f, 2.0f, 5.0f, 6.0f.
  __ unpcklpd(XMM9, XMM1);
  // XMM1 = 1.0f, 2.0f, 5.0f, 6.0f.
  __ movaps(XMM1, XMM9);
  __ shufps(XMM9, XMM9, Immediate(0x00));
  __ shufps(XMM1, XMM1, Immediate(0xAA));
  __ addss(XMM9, XMM1);  // 6.0f.
  __ movaps(XMM0, XMM9);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedUnpackLowPair, test) {
  typedef float (*PackedUnpackLowPair)();
  float res = reinterpret_cast<PackedUnpackLowPair>(test->entry())();
  EXPECT_FLOAT_EQ(6.0f, res, 0.001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm1,[rax]\n"
      "unpcklpd xmm9,xmm1\n"
      "movaps xmm1,xmm9\n"
      "shufps xmm9,xmm9 [0]\n"
      "shufps xmm1,xmm1 [aa]\n"
      "addss xmm9,xmm1\n"
      "movaps xmm0,xmm9\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PackedUnpackHighPair, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = {1.0, 2.0, 3.0, 4.0};
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = {5.0, 6.0, 7.0, 8.0};
  // XMM9 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant0)));
  __ movups(XMM9, Address(RAX, 0));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM1, Address(RAX, 0));
  // XMM9 = 3.0f, 4.0f, 7.0f, 8.0f.
  __ unpckhpd(XMM9, XMM1);
  // XMM1 = 3.0f, 4.0f, 7.0f, 8.0f.
  __ movaps(XMM1, XMM9);
  __ shufps(XMM9, XMM9, Immediate(0x55));
  __ shufps(XMM1, XMM1, Immediate(0xFF));
  __ addss(XMM9, XMM1);  // 12.0f.
  __ movaps(XMM0, XMM9);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedUnpackHighPair, test) {
  typedef float (*PackedUnpackHighPair)();
  float res = reinterpret_cast<PackedUnpackHighPair>(test->entry())();
  EXPECT_FLOAT_EQ(12.0f, res, 0.001f);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movups xmm1,[rax]\n"
      "unpckhpd xmm9,xmm1\n"
      "movaps xmm1,xmm9\n"
      "shufps xmm9,xmm9 [55]\n"
      "shufps xmm1,xmm1 [ff]\n"
      "addss xmm9,xmm1\n"
      "movaps xmm0,xmm9\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(DoubleFPMoves, assembler) {
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(1024.67)));
  __ pushq(R15);  // Callee saved.
  __ pushq(RAX);
  __ movsd(XMM0, Address(RSP, 0));
  __ movsd(XMM1, XMM0);
  __ movsd(XMM2, XMM1);
  __ movsd(XMM3, XMM2);
  __ movsd(XMM4, XMM3);
  __ movsd(XMM5, XMM4);
  __ movsd(XMM6, XMM5);
  __ movsd(XMM7, XMM6);
  __ movsd(XMM8, XMM7);
  __ movsd(XMM9, XMM8);
  __ movsd(XMM10, XMM9);
  __ movsd(XMM11, XMM10);
  __ movsd(XMM12, XMM11);
  __ movsd(XMM13, XMM12);
  __ movsd(XMM14, XMM13);
  __ movsd(XMM15, XMM14);
  __ movq(Address(RSP, 0), Immediate(0));
  __ movsd(XMM0, Address(RSP, 0));
  __ movsd(Address(RSP, 0), XMM15);
  __ movsd(XMM1, Address(RSP, 0));
  __ movq(R10, RSP);
  __ movsd(Address(R10, 0), XMM1);
  __ movsd(XMM2, Address(R10, 0));
  __ movq(R15, RSP);
  __ movsd(Address(R15, 0), XMM2);
  __ movsd(XMM3, Address(R15, 0));
  __ movq(RAX, RSP);
  __ movsd(Address(RAX, 0), XMM3);
  __ movsd(XMM4, Address(RAX, 0));
  __ movsd(XMM15, Address(RSP, 0));
  __ movaps(XMM14, XMM15);
  __ movaps(XMM13, XMM14);
  __ movaps(XMM12, XMM13);
  __ movaps(XMM11, XMM12);
  __ movaps(XMM10, XMM11);
  __ movaps(XMM9, XMM10);
  __ movaps(XMM8, XMM9);
  __ movaps(XMM7, XMM8);
  __ movaps(XMM6, XMM7);
  __ movaps(XMM5, XMM6);
  __ movaps(XMM4, XMM5);
  __ movaps(XMM3, XMM4);
  __ movaps(XMM2, XMM3);
  __ movaps(XMM1, XMM2);
  __ movaps(XMM0, XMM1);
  __ popq(RAX);
  __ popq(R15);  // Callee saved.
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleFPMoves, test) {
  typedef double (*DoubleFPMovesCode)();
  EXPECT_FLOAT_EQ(1024.67, reinterpret_cast<DoubleFPMovesCode>(test->entry())(),
                  0.001);
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "push pp\n"
      "push rax\n"
      "movsd xmm0,[rsp]\n"
      "movsd xmm1,xmm0\n"
      "movsd xmm2,xmm1\n"
      "movsd xmm3,xmm2\n"
      "movsd xmm4,xmm3\n"
      "movsd xmm5,xmm4\n"
      "movsd xmm6,xmm5\n"
      "movsd xmm7,xmm6\n"
      "movsd xmm8,xmm7\n"
      "movsd xmm9,xmm8\n"
      "movsd xmm10,xmm9\n"
      "movsd xmm11,xmm10\n"
      "movsd xmm12,xmm11\n"
      "movsd xmm13,xmm12\n"
      "movsd xmm14,xmm13\n"
      "movsd xmm15,xmm14\n"
      "movq [rsp],0\n"
      "movsd xmm0,[rsp]\n"
      "movsd [rsp],xmm15\n"
      "movsd xmm1,[rsp]\n"
      "movq r10,rsp\n"
      "movsd [r10],xmm1\n"
      "movsd xmm2,[r10]\n"
      "movq pp,rsp\n"
      "movsd [pp],xmm2\n"
      "movsd xmm3,[pp]\n"
      "movq rax,rsp\n"
      "movsd [rax],xmm3\n"
      "movsd xmm4,[rax]\n"
      "movsd xmm15,[rsp]\n"
      "movaps xmm14,xmm15\n"
      "movaps xmm13,xmm14\n"
      "movaps xmm12,xmm13\n"
      "movaps xmm11,xmm12\n"
      "movaps xmm10,xmm11\n"
      "movaps xmm9,xmm10\n"
      "movaps xmm8,xmm9\n"
      "movaps xmm7,xmm8\n"
      "movaps xmm6,xmm7\n"
      "movaps xmm5,xmm6\n"
      "movaps xmm4,xmm5\n"
      "movaps xmm3,xmm4\n"
      "movaps xmm2,xmm3\n"
      "movaps xmm1,xmm2\n"
      "movaps xmm0,xmm1\n"
      "pop rax\n"
      "pop pp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(DoubleFPOperations, assembler) {
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(12.3)));
  __ pushq(RAX);
  __ movsd(XMM0, Address(RSP, 0));
  __ movsd(XMM8, Address(RSP, 0));
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(3.4)));
  __ movq(Address(RSP, 0), RAX);
  __ movsd(XMM12, Address(RSP, 0));
  __ addsd(XMM8, XMM12);  // 15.7
  __ mulsd(XMM8, XMM12);  // 53.38
  __ subsd(XMM8, XMM12);  // 49.98
  __ divsd(XMM8, XMM12);  // 14.7
  __ sqrtsd(XMM8, XMM8);  // 3.834
  __ movsd(XMM1, Address(RSP, 0));
  __ addsd(XMM0, XMM1);   // 15.7
  __ mulsd(XMM0, XMM1);   // 53.38
  __ subsd(XMM0, XMM1);   // 49.98
  __ divsd(XMM0, XMM1);   // 14.7
  __ sqrtsd(XMM0, XMM0);  // 3.834057902
  __ addsd(XMM0, XMM8);   // 7.6681
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleFPOperations, test) {
  typedef double (*SingleFPOperationsCode)();
  double res = reinterpret_cast<SingleFPOperationsCode>(test->entry())();
  EXPECT_FLOAT_EQ(7.668, res, 0.001);
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "push rax\n"
      "movsd xmm0,[rsp]\n"
      "movsd xmm8,[rsp]\n"
      "movq rax,0x................\n"
      "movq [rsp],rax\n"
      "movsd xmm12,[rsp]\n"
      "addsd xmm8,xmm12\n"
      "mulsd xmm8,xmm12\n"
      "subsd xmm8,xmm12\n"
      "divsd xmm8,xmm12\n"
      "sqrtsd xmm8,xmm8\n"
      "movsd xmm1,[rsp]\n"
      "addsd xmm0,xmm1\n"
      "mulsd xmm0,xmm1\n"
      "subsd xmm0,xmm1\n"
      "divsd xmm0,xmm1\n"
      "sqrtsd xmm0,xmm0\n"
      "addsd xmm0,xmm8\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Int32ToDoubleConversion, assembler) {
  // Fill upper bits with garbage.
  __ movq(R11, Immediate(0x1111111100000006));
  __ cvtsi2sdl(XMM0, R11);
  // Fill upper bits with garbage.
  __ movq(R11, Immediate(0x2222222200000008));
  __ cvtsi2sdl(XMM8, R11);
  __ subsd(XMM0, XMM8);
  __ ret();
}

ASSEMBLER_TEST_RUN(Int32ToDoubleConversion, test) {
  typedef double (*Int32ToDoubleConversion)();
  double res = reinterpret_cast<Int32ToDoubleConversion>(test->entry())();
  EXPECT_FLOAT_EQ(-2.0, res, 0.001);
  EXPECT_DISASSEMBLY(
      "movq r11,0x................\n"
      "cvtsi2sd xmm0,r11\n"
      "movq r11,0x................\n"
      "cvtsi2sd xmm8,r11\n"
      "subsd xmm0,xmm8\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Int64ToDoubleConversion, assembler) {
  __ movq(RDX, Immediate(12LL << 32));
  __ cvtsi2sdq(XMM0, RDX);
  __ movsd(XMM15, XMM0);  // Move to high register
  __ addsd(XMM0, XMM0);   // Stomp XMM0
  __ movsd(XMM0, XMM15);  // Move back to XMM0
  __ ret();
}

ASSEMBLER_TEST_RUN(Int64ToDoubleConversion, test) {
  typedef double (*Int64ToDoubleConversionCode)();
  double res = reinterpret_cast<Int64ToDoubleConversionCode>(test->entry())();
  EXPECT_FLOAT_EQ(static_cast<double>(12LL << 32), res, 0.001);
  EXPECT_DISASSEMBLY(
      "movq rdx,0x................\n"
      "cvtsi2sd xmm0,rdx\n"
      "movsd xmm15,xmm0\n"
      "addsd xmm0,xmm0\n"
      "movsd xmm0,xmm15\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(DoubleToInt64Conversion, assembler) {
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(4.2e22)));
  __ pushq(RAX);
  __ movsd(XMM9, Address(RSP, 0));
  __ popq(RAX);
  __ cvttsd2siq(RAX, XMM9);
  __ CompareImmediate(RAX, Immediate(0x8000000000000000ll));
  Label ok;
  __ j(EQUAL, &ok);
  __ int3();  // cvttsd2siq overflow not detected
  __ Bind(&ok);
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(4.2e11)));
  __ pushq(RAX);
  __ movsd(XMM9, Address(RSP, 0));
  __ movsd(XMM6, Address(RSP, 0));
  __ popq(RAX);
  __ cvttsd2siq(R10, XMM6);
  __ cvttsd2siq(RDX, XMM6);
  __ cvttsd2siq(R10, XMM9);
  __ cvttsd2siq(RDX, XMM9);
  __ subq(RDX, R10);
  __ addq(RDX, RDX);
  __ addq(RDX, R10);
  __ movq(RAX, RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleToInt64Conversion, test) {
  typedef int64_t (*DoubleToInt64ConversionCode)();
  int64_t res = reinterpret_cast<DoubleToInt64ConversionCode>(test->entry())();
  EXPECT_EQ(420000000000l, res);
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "push rax\n"
      "movsd xmm9,[rsp]\n"
      "pop rax\n"
      "cvttsd2siq rax,xmm9\n"
      "movq r11,0x................\n"
      "cmpq rax,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movq rax,0x................\n"
      "push rax\n"
      "movsd xmm9,[rsp]\n"
      "movsd xmm6,[rsp]\n"
      "pop rax\n"
      "cvttsd2siq r10,xmm6\n"
      "cvttsd2siq rdx,xmm6\n"
      "cvttsd2siq r10,xmm9\n"
      "cvttsd2siq rdx,xmm9\n"
      "subq rdx,r10\n"
      "addq rdx,rdx\n"
      "addq rdx,r10\n"
      "movq rax,rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(DoubleToInt32Conversion, assembler) {
  // Check that a too big double results in the overflow value for a conversion
  // to signed 32 bit.
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(4.2e11)));
  __ pushq(RAX);
  __ movsd(XMM9, Address(RSP, 0));
  __ popq(RAX);
  __ cvttsd2sil(RAX, XMM9);
  __ CompareImmediate(RAX, Immediate(0x80000000ll));
  {
    Label ok;
    __ j(EQUAL, &ok);
    __ int3();  // cvttsd2sil overflow not detected.
    __ Bind(&ok);
  }

  // Check that negative floats result in signed 32 bit results with the top
  // bits zeroed.
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(-42.0)));
  __ pushq(RAX);
  __ movsd(XMM9, Address(RSP, 0));
  __ popq(RAX);
  // These high 1-bits will be zeroed in the next insn.
  __ movq(R10, Immediate(-1));
  // Put -42 in r10d, zeroing the high bits of r10.
  __ cvttsd2sil(R10, XMM9);
  __ CompareImmediate(R10, Immediate(-42 & 0xffffffffll));
  {
    Label ok;
    __ j(EQUAL, &ok);
    __ int3();  // cvttsd2sil negative result error
    __ Bind(&ok);
  }

  // Check for correct result for positive in-range input.
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(42.0)));
  __ pushq(RAX);
  __ movsd(XMM9, Address(RSP, 0));
  __ movsd(XMM6, Address(RSP, 0));
  __ popq(RAX);
  __ cvttsd2sil(R10, XMM6);
  __ cvttsd2sil(RDX, XMM6);
  __ cvttsd2sil(R10, XMM9);
  __ cvttsd2sil(RDX, XMM9);
  __ subq(RDX, R10);
  __ addq(RDX, RDX);
  __ addq(RDX, R10);
  __ movq(RAX, RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleToInt32Conversion, test) {
  typedef int64_t (*DoubleToInt32ConversionCode)();
  int64_t res = reinterpret_cast<DoubleToInt32ConversionCode>(test->entry())();
  EXPECT_EQ(42, res);
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "push rax\n"
      "movsd xmm9,[rsp]\n"
      "pop rax\n"
      "cvttsd2sil rax,xmm9\n"
      "movl r11,0x........\n"
      "cmpq rax,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movq rax,0x................\n"
      "push rax\n"
      "movsd xmm9,[rsp]\n"
      "pop rax\n"
      "movq r10,-1\n"
      "cvttsd2sil r10,xmm9\n"
      "movl r11,0x........\n"
      "cmpq r10,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movq rax,0x................\n"
      "push rax\n"
      "movsd xmm9,[rsp]\n"
      "movsd xmm6,[rsp]\n"
      "pop rax\n"
      "cvttsd2sil r10,xmm6\n"
      "cvttsd2sil rdx,xmm6\n"
      "cvttsd2sil r10,xmm9\n"
      "cvttsd2sil rdx,xmm9\n"
      "subq rdx,r10\n"
      "addq rdx,rdx\n"
      "addq rdx,r10\n"
      "movq rax,rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestObjectCompare, assembler) {
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Object& obj = Object::ZoneHandle(object_store->smi_class());
  Label fail;
  EnterTestFrame(assembler);
  __ LoadObject(RAX, obj);
  __ CompareObject(RAX, obj);
  __ j(NOT_EQUAL, &fail);
  __ LoadObject(RCX, obj);
  __ CompareObject(RCX, obj);
  __ j(NOT_EQUAL, &fail);
  const Smi& smi = Smi::ZoneHandle(Smi::New(15));
  __ LoadObject(RCX, smi);
  __ CompareObject(RCX, smi);
  __ j(NOT_EQUAL, &fail);
  __ pushq(RAX);
  __ StoreObject(Address(RSP, 0), obj);
  __ popq(RCX);
  __ CompareObject(RCX, obj);
  __ j(NOT_EQUAL, &fail);
  __ pushq(RAX);
  __ StoreObject(Address(RSP, 0), smi);
  __ popq(RCX);
  __ CompareObject(RCX, smi);
  __ j(NOT_EQUAL, &fail);
  __ movl(RAX, Immediate(1));  // OK
  LeaveTestFrame(assembler);
  __ ret();
  __ Bind(&fail);
  __ movl(RAX, Immediate(0));  // Fail.
  LeaveTestFrame(assembler);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestObjectCompare, test) {
  bool res = test->InvokeWithCodeAndThread<bool>();
  EXPECT_EQ(true, res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rbp\n"
      "movq rbp,rsp\n"
      "push r12\n"
      "push pp\n"
      "push thr\n"
      "movq r12,[rdi+0x8]\n"
      "movq thr,rsi\n"
      "movq pp,[r12+0x27]\n"
      "movq rax,[pp+0xf]\n"
      "cmpq rax,[pp+0xf]\n"
      "jnz 0x................\n"
      "movq rcx,[pp+0xf]\n"
      "cmpq rcx,[pp+0xf]\n"
      "jnz 0x................\n"
      "movl rcx,0x1e\n"
      "cmpq rcx,0x1e\n"
      "jnz 0x................\n"
      "push rax\n"
      "movq r11,[pp+0xf]\n"
      "movq [rsp],r11\n"
      "pop rcx\n"
      "cmpq rcx,[pp+0xf]\n"
      "jnz 0x................\n"
      "push rax\n"
      "movq [rsp],0x1e\n"
      "pop rcx\n"
      "cmpq rcx,0x1e\n"
      "jnz 0x................\n"
      "movl rax,1\n"
      "pop thr\n"
      "pop pp\n"
      "pop r12\n"
      "movq rsp,rbp\n"
      "pop rbp\n"
      "ret\n"
      "movl rax,0\n"
      "pop thr\n"
      "pop pp\n"
      "pop r12\n"
      "movq rsp,rbp\n"
      "pop rbp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestNop, assembler) {
  __ nop(1);
  __ nop(2);
  __ nop(3);
  __ nop(4);
  __ nop(5);
  __ nop(6);
  __ nop(7);
  __ nop(8);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}

ASSEMBLER_TEST_RUN(TestNop, test) {
  typedef int (*TestNop)();
  int res = reinterpret_cast<TestNop>(test->payload_start())();
  EXPECT_EQ(36, res);  // 36 nop bytes emitted.
  EXPECT_DISASSEMBLY(
      "nop\n"
      "nop\n"
      "nop\n"
      "nop\n"
      "nop\n"
      "nop\n"
      "nop\n"
      "nop\n"
      "movl rax,0x24\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestAlign0, assembler) {
  __ Align(4, 0);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}

ASSEMBLER_TEST_RUN(TestAlign0, test) {
  typedef int (*TestAlign0)();
  int res = reinterpret_cast<TestAlign0>(test->payload_start())();
  EXPECT_EQ(0, res);  // 0 bytes emitted.
  EXPECT_DISASSEMBLY(
      "movl rax,0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestAlign1, assembler) {
  __ nop(1);
  __ Align(4, 0);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}

ASSEMBLER_TEST_RUN(TestAlign1, test) {
  typedef int (*TestAlign1)();
  int res = reinterpret_cast<TestAlign1>(test->payload_start())();
  EXPECT_EQ(4, res);  // 4 bytes emitted.
  EXPECT_DISASSEMBLY(
      "nop\n"
      "nop\n"
      "movl rax,4\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestAlign1Offset1, assembler) {
  __ nop(1);
  __ Align(4, 1);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}

ASSEMBLER_TEST_RUN(TestAlign1Offset1, test) {
  typedef int (*TestAlign1Offset1)();
  int res = reinterpret_cast<TestAlign1Offset1>(test->payload_start())();
  EXPECT_EQ(3, res);  // 3 bytes emitted.
  EXPECT_DISASSEMBLY(
      "nop\n"
      "nop\n"
      "movl rax,3\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestAlignLarge, assembler) {
  __ nop(1);
  __ Align(16, 0);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}

ASSEMBLER_TEST_RUN(TestAlignLarge, test) {
  typedef int (*TestAlignLarge)();
  int res = reinterpret_cast<TestAlignLarge>(test->payload_start())();
  EXPECT_EQ(16, res);  // 16 bytes emitted.
  EXPECT_DISASSEMBLY(
      "nop\n"
      "nop\n"
      "nop\n"
      "movl rax,0x10\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestAdds, assembler) {
  __ movq(RAX, Immediate(4));
  __ pushq(RAX);
  __ addq(Address(RSP, 0), Immediate(5));
  // TOS: 9
  __ addq(Address(RSP, 0), Immediate(-2));
  // TOS: 7
  __ movq(RCX, Immediate(3));
  __ addq(Address(RSP, 0), RCX);
  // TOS: 10
  __ movq(RAX, Immediate(10));
  __ addq(RAX, Address(RSP, 0));
  // RAX: 20
  __ popq(RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestAdds, test) {
  typedef int (*TestAdds)();
  int res = reinterpret_cast<TestAdds>(test->entry())();
  EXPECT_EQ(20, res);
  EXPECT_DISASSEMBLY(
      "movl rax,4\n"
      "push rax\n"
      "addq [rsp],5\n"
      "addq [rsp],-2\n"
      "movl rcx,3\n"
      "addq [rsp],rcx\n"
      "movl rax,0xa\n"
      "addq rax,[rsp]\n"
      "pop rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestNot, assembler) {
  __ movq(RAX, Immediate(0xFFFFFFFF00000000));
  __ notq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestNot, test) {
  typedef int (*TestNot)();
  unsigned int res = reinterpret_cast<TestNot>(test->entry())();
  EXPECT_EQ(0xFFFFFFFF, res);
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "notq rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestNotInt32, assembler) {
  __ movq(RAX, Immediate(0x0));
  __ notl(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestNotInt32, test) {
  typedef int (*TestNot)();
  unsigned int res = reinterpret_cast<TestNot>(test->entry())();
  EXPECT_EQ(0xFFFFFFFF, res);
  EXPECT_DISASSEMBLY(
      "movl rax,0\n"
      "notl rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(XorpdZeroing, assembler) {
  __ pushq(RAX);
  __ movsd(Address(RSP, 0), XMM0);
  __ xorpd(XMM0, Address(RSP, 0));
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(XorpdZeroing, test) {
  typedef double (*XorpdZeroingCode)(double d);
  double res = reinterpret_cast<XorpdZeroingCode>(test->entry())(12.56e3);
  EXPECT_FLOAT_EQ(0.0, res, 0.0001);
  EXPECT_DISASSEMBLY(
      "push rax\n"
      "movsd [rsp],xmm0\n"
      "xorpd xmm0,[rsp]\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(XorpdZeroing2, assembler) {
  Label done;
  __ xorpd(XMM15, XMM15);
  __ xorpd(XMM0, XMM0);
  __ xorpd(XMM0, XMM15);
  __ comisd(XMM0, XMM15);
  __ j(ZERO, &done);
  __ int3();
  __ Bind(&done);
  __ ret();
}

ASSEMBLER_TEST_RUN(XorpdZeroing2, test) {
  typedef double (*XorpdZeroing2Code)(double d);
  double res = reinterpret_cast<XorpdZeroing2Code>(test->entry())(12.56e3);
  EXPECT_FLOAT_EQ(0.0, res, 0.0001);
  EXPECT_DISASSEMBLY(
      "xorpd xmm15,xmm15\n"
      "xorpd xmm0,xmm0\n"
      "xorpd xmm0,xmm15\n"
      "comisd xmm0,xmm15\n"
      "jz 0x................\n"
      "int3\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Pxor, assembler) {
  __ pxor(XMM0, XMM0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Pxor, test) {
  typedef double (*PxorCode)(double d);
  double res = reinterpret_cast<PxorCode>(test->entry())(12.3456e3);
  EXPECT_FLOAT_EQ(0.0, res, 0.0);
  EXPECT_DISASSEMBLY(
      "pxor xmm0,xmm0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SquareRootDouble, assembler) {
  __ sqrtsd(XMM0, XMM0);
  __ ret();
}

ASSEMBLER_TEST_RUN(SquareRootDouble, test) {
  typedef double (*SquareRootDoubleCode)(double d);
  const double kDoubleConst = .7;
  double res =
      reinterpret_cast<SquareRootDoubleCode>(test->entry())(kDoubleConst);
  EXPECT_FLOAT_EQ(sqrt(kDoubleConst), res, 0.0001);
  EXPECT_DISASSEMBLY(
      "sqrtsd xmm0,xmm0\n"
      "ret\n");
}

// Called from assembler_test.cc.
ASSEMBLER_TEST_GENERATE(StoreIntoObject, assembler) {
  __ pushq(CODE_REG);
  __ pushq(THR);
  __ movq(THR, CallingConventions::kArg3Reg);
  __ StoreIntoObject(CallingConventions::kArg2Reg,
                     FieldAddress(CallingConventions::kArg2Reg,
                                  GrowableObjectArray::data_offset()),
                     CallingConventions::kArg1Reg);
  __ popq(THR);
  __ popq(CODE_REG);
  __ ret();
}

ASSEMBLER_TEST_GENERATE(DoubleFPUStackMoves, assembler) {
  int64_t l = bit_cast<int64_t, double>(1024.67);
  __ movq(RAX, Immediate(l));
  __ pushq(RAX);
  __ fldl(Address(RSP, 0));
  __ movq(Address(RSP, 0), Immediate(0));
  __ fstpl(Address(RSP, 0));
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleFPUStackMoves, test) {
  typedef int64_t (*DoubleFPUStackMovesCode)();
  int64_t res = reinterpret_cast<DoubleFPUStackMovesCode>(test->entry())();
  EXPECT_FLOAT_EQ(1024.67, (bit_cast<double, int64_t>(res)), 0.001);
  EXPECT_DISASSEMBLY(
      "movq rax,0x................\n"
      "push rax\n"
      "fld_d [rsp]\n"
      "movq [rsp],0\n"
      "fstp_d [rsp]\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Sine, assembler) {
  __ pushq(RAX);
  __ movsd(Address(RSP, 0), XMM0);
  __ fldl(Address(RSP, 0));
  __ fsin();
  __ fstpl(Address(RSP, 0));
  __ movsd(XMM0, Address(RSP, 0));
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Sine, test) {
  typedef double (*SineCode)(double d);
  const double kDoubleConst = 0.7;
  double res = reinterpret_cast<SineCode>(test->entry())(kDoubleConst);
  EXPECT_FLOAT_EQ(sin(kDoubleConst), res, 0.0001);
  EXPECT_DISASSEMBLY(
      "push rax\n"
      "movsd [rsp],xmm0\n"
      "fld_d [rsp]\n"
      "fsin\n"
      "fstp_d [rsp]\n"
      "movsd xmm0,[rsp]\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Cosine, assembler) {
  __ pushq(RAX);
  __ movsd(Address(RSP, 0), XMM0);
  __ fldl(Address(RSP, 0));
  __ fcos();
  __ fstpl(Address(RSP, 0));
  __ movsd(XMM0, Address(RSP, 0));
  __ popq(RAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Cosine, test) {
  typedef double (*CosineCode)(double f);
  const double kDoubleConst = 0.7;
  double res = reinterpret_cast<CosineCode>(test->entry())(kDoubleConst);
  EXPECT_FLOAT_EQ(cos(kDoubleConst), res, 0.0001);
  EXPECT_DISASSEMBLY(
      "push rax\n"
      "movsd [rsp],xmm0\n"
      "fld_d [rsp]\n"
      "fcos\n"
      "fstp_d [rsp]\n"
      "movsd xmm0,[rsp]\n"
      "pop rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(IntToDoubleConversion, assembler) {
  __ movq(RDX, Immediate(6));
  __ cvtsi2sdq(XMM0, RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(IntToDoubleConversion, test) {
  typedef double (*IntToDoubleConversionCode)();
  double res = reinterpret_cast<IntToDoubleConversionCode>(test->entry())();
  EXPECT_FLOAT_EQ(6.0, res, 0.001);
  EXPECT_DISASSEMBLY(
      "movl rdx,6\n"
      "cvtsi2sd xmm0,rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(DoubleToDoubleTrunc, assembler) {
  __ roundsd(XMM0, XMM0, Assembler::kRoundToZero);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleToDoubleTrunc, test) {
  typedef double (*DoubleToDoubleTruncCode)(double d);
  double res = reinterpret_cast<DoubleToDoubleTruncCode>(test->entry())(12.3);
  EXPECT_EQ(12.0, res);
  res = reinterpret_cast<DoubleToDoubleTruncCode>(test->entry())(12.8);
  EXPECT_EQ(12.0, res);
  res = reinterpret_cast<DoubleToDoubleTruncCode>(test->entry())(-12.3);
  EXPECT_EQ(-12.0, res);
  res = reinterpret_cast<DoubleToDoubleTruncCode>(test->entry())(-12.8);
  EXPECT_EQ(-12.0, res);
  EXPECT_DISASSEMBLY(
      "roundsd rax, rax, 3\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(DoubleAbs, assembler) {
  EnterTestFrame(assembler);
#if defined(HOST_OS_WINDOWS)
  // First argument is code object, second argument is thread. MSVC passes
  // third argument in XMM2.
  __ DoubleAbs(XMM0, XMM2);
#else
  // SysV ABI allocates integral and double registers for arguments
  // independently.
  __ DoubleAbs(XMM0, XMM0);
#endif
  LeaveTestFrame(assembler);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleAbs, test) {
  double val = -12.45;
  double res = test->InvokeWithCodeAndThread<double, double>(val);
  EXPECT_FLOAT_EQ(-val, res, 0.001);
  val = 12.45;
  res = test->InvokeWithCodeAndThread<double, double>(val);
  EXPECT_FLOAT_EQ(val, res, 0.001);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rbp\n"
      "movq rbp,rsp\n"
      "push r12\n"
      "push pp\n"
      "push thr\n"
      "movq r12,[rdi+0x8]\n"
      "movq thr,rsi\n"
      "movq pp,[r12+0x27]\n"
      "movq r11,[thr+0x...]\n"
      "andpd xmm0,[r11]\n"
      "pop thr\n"
      "pop pp\n"
      "pop r12\n"
      "movq rsp,rbp\n"
      "pop rbp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(ExtractSignBits, assembler) {
  __ movmskpd(RAX, XMM0);
  __ andq(RAX, Immediate(0x1));
  __ ret();
}

ASSEMBLER_TEST_RUN(ExtractSignBits, test) {
  typedef int (*ExtractSignBits)(double d);
  int res = reinterpret_cast<ExtractSignBits>(test->entry())(1.0);
  EXPECT_EQ(0, res);
  res = reinterpret_cast<ExtractSignBits>(test->entry())(-1.0);
  EXPECT_EQ(1, res);
  res = reinterpret_cast<ExtractSignBits>(test->entry())(-0.0);
  EXPECT_EQ(1, res);
  EXPECT_DISASSEMBLY(
      "movmskpd rax,xmm0\n"
      "andl rax,1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestSetCC, assembler) {
  __ movq(RAX, Immediate(0xFFFFFFFF));
  __ cmpq(RAX, RAX);
  __ setcc(NOT_EQUAL, AL);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestSetCC, test) {
  typedef uword (*TestSetCC)();
  uword res = reinterpret_cast<TestSetCC>(test->entry())();
  EXPECT_EQ(0xFFFFFF00, res);
  EXPECT_DISASSEMBLY(
      "movl rax,0x........\n"
      "cmpq rax,rax\n"
      "setnzl rax\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestSetCC2, assembler) {
  __ pushq(RBX);
  __ movq(RBX, Immediate(0xFFFFFFFF));
  __ cmpq(RBX, RBX);
  __ setcc(EQUAL, BH);
  __ movq(RAX, RBX);
  __ popq(RBX);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestSetCC2, test) {
  typedef uword (*TestSetCC)();
  uword res = reinterpret_cast<TestSetCC>(test->entry())();
  EXPECT_EQ(0xFFFF01FF, res);
  EXPECT_DISASSEMBLY(
      "push rbx\n"
      "movl rbx,0x........\n"
      "cmpq rbx,rbx\n"
      "setzl rdi\n"
      "movq rax,rbx\n"
      "pop rbx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestSetCC3, assembler) {
  __ pushq(R10);
  __ movq(R10, Immediate(0xFFFFFFFF));
  __ cmpq(R10, R10);
  __ setcc(NOT_EQUAL, R10B);
  __ movq(RAX, R10);
  __ popq(R10);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestSetCC3, test) {
  typedef uword (*TestSetCC)();
  uword res = reinterpret_cast<TestSetCC>(test->entry())();
  EXPECT_EQ(0xFFFFFF00, res);
  EXPECT_DISASSEMBLY(
      "push r10\n"
      "movl r10,0x........\n"
      "cmpq r10,r10\n"
      "setnzl r10\n"
      "movq rax,r10\n"
      "pop r10\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestSetCC4, assembler) {
  __ pushq(RSI);
  __ movq(RSI, Immediate(0xFFFFFFFF));
  __ cmpq(RSI, RSI);
  __ setcc(EQUAL, SIL);
  __ movq(RAX, RSI);
  __ popq(RSI);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestSetCC4, test) {
  typedef uword (*TestSetCC)();
  uword res = reinterpret_cast<TestSetCC>(test->entry())();
  EXPECT_EQ(0xFFFFFF01, res);
  EXPECT_DISASSEMBLY(
      "push rsi\n"
      "movl rsi,0x........\n"
      "cmpq rsi,rsi\n"
      "setzl rsi\n"
      "movq rax,rsi\n"
      "pop rsi\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestRepMovsBytes, assembler) {
  __ pushq(RSI);
  __ pushq(RDI);
  __ pushq(CallingConventions::kArg1Reg);     // from.
  __ pushq(CallingConventions::kArg2Reg);     // to.
  __ pushq(CallingConventions::kArg3Reg);     // count.
  __ movq(RSI, Address(RSP, 2 * target::kWordSize));  // from.
  __ movq(RDI, Address(RSP, 1 * target::kWordSize));  // to.
  __ movq(RCX, Address(RSP, 0 * target::kWordSize));  // count.
  __ rep_movsb();
  // Remove saved arguments.
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RDI);
  __ popq(RSI);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestRepMovsBytes, test) {
  const char* from = "0123456789x";
  char* to = new char[11]{0};
  to[10] = 'y';
  typedef void (*TestRepMovsBytes)(const char* from, char* to, int count);
  reinterpret_cast<TestRepMovsBytes>(test->entry())(from, to, 10);
  EXPECT_EQ(to[0], '0');
  for (int i = 0; i < 10; i++) {
    EXPECT_EQ(from[i], to[i]);
  }
  EXPECT_EQ(to[10], 'y');
  delete[] to;
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rsi\n"
      "push rdi\n"
      "push rdi\n"
      "push rsi\n"
      "push rdx\n"
      "movq rsi,[rsp+0x10]\n"
      "movq rdi,[rsp+0x8]\n"
      "movq rcx,[rsp]\n"
      "rep movsb\n"
      "pop rax\n"
      "pop rax\n"
      "pop rax\n"
      "pop rdi\n"
      "pop rsi\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestRepMovsWords, assembler) {
  __ pushq(RSI);
  __ pushq(RDI);
  __ pushq(CallingConventions::kArg1Reg);             // from.
  __ pushq(CallingConventions::kArg2Reg);             // to.
  __ pushq(CallingConventions::kArg3Reg);             // count.
  __ movq(RSI, Address(RSP, 2 * target::kWordSize));  // from.
  __ movq(RDI, Address(RSP, 1 * target::kWordSize));  // to.
  __ movq(RCX, Address(RSP, 0 * target::kWordSize));  // count.
  __ rep_movsw();
  // Remove saved arguments.
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RDI);
  __ popq(RSI);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestRepMovsWords, test) {
  const uint16_t from[11] = {0x0123, 0x1234, 0x2345, 0x3456, 0x4567, 0x5678,
                             0x6789, 0x789A, 0x89AB, 0x9ABC, 0xABCD};
  uint16_t* to = new uint16_t[11]{0};
  to[10] = 0xFEFE;
  typedef void (*TestRepMovsWords)(const uint16_t* from, uint16_t* to,
                                   int count);
  reinterpret_cast<TestRepMovsWords>(test->entry())(from, to, 10);
  EXPECT_EQ(to[0], 0x0123u);
  for (int i = 0; i < 10; i++) {
    EXPECT_EQ(from[i], to[i]);
  }
  EXPECT_EQ(to[10], 0xFEFEu);
  delete[] to;
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rsi\n"
      "push rdi\n"
      "push rdi\n"
      "push rsi\n"
      "push rdx\n"
      "movq rsi,[rsp+0x10]\n"
      "movq rdi,[rsp+0x8]\n"
      "movq rcx,[rsp]\n"
      "rep movsw\n"
      "pop rax\n"
      "pop rax\n"
      "pop rax\n"
      "pop rdi\n"
      "pop rsi\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestRepMovsDwords, assembler) {
  __ pushq(RSI);
  __ pushq(RDI);
  __ pushq(CallingConventions::kArg1Reg);             // from.
  __ pushq(CallingConventions::kArg2Reg);             // to.
  __ pushq(CallingConventions::kArg3Reg);             // count.
  __ movq(RSI, Address(RSP, 2 * target::kWordSize));  // from.
  __ movq(RDI, Address(RSP, 1 * target::kWordSize));  // to.
  __ movq(RCX, Address(RSP, 0 * target::kWordSize));  // count.
  __ rep_movsl();
  // Remove saved arguments.
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RDI);
  __ popq(RSI);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestRepMovsDwords, test) {
  const uint32_t from[11] = {0x01234567, 0x12345678, 0x23456789, 0x3456789A,
                             0x456789AB, 0x56789ABC, 0x6789ABCD, 0x789ABCDE,
                             0x89ABCDEF, 0x9ABCDEF0, 0xABCDEF01};
  uint32_t* to = new uint32_t[11]{0};
  to[10] = 0xFEFEFEFE;
  typedef void (*TestRepMovsDwords)(const uint32_t* from, uint32_t* to,
                                    int count);
  reinterpret_cast<TestRepMovsDwords>(test->entry())(from, to, 10);
  EXPECT_EQ(to[0], 0x01234567u);
  for (int i = 0; i < 10; i++) {
    EXPECT_EQ(from[i], to[i]);
  }
  EXPECT_EQ(to[10], 0xFEFEFEFEu);
  delete[] to;
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rsi\n"
      "push rdi\n"
      "push rdi\n"
      "push rsi\n"
      "push rdx\n"
      "movq rsi,[rsp+0x10]\n"
      "movq rdi,[rsp+0x8]\n"
      "movq rcx,[rsp]\n"
      "rep movsl\n"
      "pop rax\n"
      "pop rax\n"
      "pop rax\n"
      "pop rdi\n"
      "pop rsi\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestRepMovsQwords, assembler) {
  __ pushq(RSI);
  __ pushq(RDI);
  __ pushq(CallingConventions::kArg1Reg);             // from.
  __ pushq(CallingConventions::kArg2Reg);             // to.
  __ pushq(CallingConventions::kArg3Reg);             // count.
  __ movq(RSI, Address(RSP, 2 * target::kWordSize));  // from.
  __ movq(RDI, Address(RSP, 1 * target::kWordSize));  // to.
  __ movq(RCX, Address(RSP, 0 * target::kWordSize));  // count.
  __ rep_movsq();
  // Remove saved arguments.
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RDI);
  __ popq(RSI);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestRepMovsQwords, test) {
  const uint64_t from[11] = {
      0x0123456789ABCDEF, 0x123456789ABCDEF0, 0x23456789ABCDEF01,
      0x3456789ABCDEF012, 0x456789ABCDEF0123, 0x56789ABCDEF01234,
      0x6789ABCDEF012345, 0x789ABCDEF0123456, 0x89ABCDEF01234567,
      0x9ABCDEF012345678, 0xABCDEF0123456789};
  uint64_t* to = new uint64_t[11]{0};
  to[10] = 0xFEFEFEFEFEFEFEFE;
  typedef void (*TestRepMovsQwords)(const uint64_t* from, uint64_t* to,
                                    int count);
  reinterpret_cast<TestRepMovsQwords>(test->entry())(from, to, 10);
  EXPECT_EQ(to[0], 0x0123456789ABCDEFu);
  for (int i = 0; i < 10; i++) {
    EXPECT_EQ(from[i], to[i]);
  }
  EXPECT_EQ(to[10], 0xFEFEFEFEFEFEFEFEu);
  delete[] to;
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "push rsi\n"
      "push rdi\n"
      "push rdi\n"
      "push rsi\n"
      "push rdx\n"
      "movq rsi,[rsp+0x10]\n"
      "movq rdi,[rsp+0x8]\n"
      "movq rcx,[rsp]\n"
      "rep movsq\n"
      "pop rax\n"
      "pop rax\n"
      "pop rax\n"
      "pop rdi\n"
      "pop rsi\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(ConditionalMovesCompare, assembler) {
  __ cmpq(CallingConventions::kArg1Reg, CallingConventions::kArg2Reg);
  __ movq(RDX, Immediate(1));   // Greater equal.
  __ movq(RCX, Immediate(-1));  // Less
  __ cmovlq(RAX, RCX);
  __ cmovgeq(RAX, RDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(ConditionalMovesCompare, test) {
  typedef int (*ConditionalMovesCompareCode)(int i, int j);
  int res = reinterpret_cast<ConditionalMovesCompareCode>(test->entry())(10, 5);
  EXPECT_EQ(1, res);  // Greater equal.
  res = reinterpret_cast<ConditionalMovesCompareCode>(test->entry())(5, 5);
  EXPECT_EQ(1, res);  // Greater equal.
  res = reinterpret_cast<ConditionalMovesCompareCode>(test->entry())(2, 5);
  EXPECT_EQ(-1, res);  // Less.
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "movl rdx,1\n"
      "movq rcx,-1\n"
      "cmovlq rax,rcx\n"
      "cmovgeq rax,rdx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(BitTestTest, assembler) {
  __ movq(RAX, Immediate(4));
  __ movq(R11, Immediate(2));
  __ btq(RAX, R11);
  Label ok;
  __ j(CARRY, &ok);
  __ int3();
  __ Bind(&ok);
  __ movq(RAX, Immediate(1));
  __ ret();
}

ASSEMBLER_TEST_RUN(BitTestTest, test) {
  typedef int (*BitTest)();
  EXPECT_EQ(1, reinterpret_cast<BitTest>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl rax,4\n"
      "movl r11,2\n"
      "btq rax,r11\n"
      "jc 0x................\n"
      "int3\n"
      "movl rax,1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(BitTestImmediate, assembler) {
  __ movq(R11, Immediate(32));
  __ btq(R11, 5);
  Label ok;
  __ j(CARRY, &ok);
  __ int3();
  __ Bind(&ok);
  __ movq(RAX, Immediate(1));
  __ ret();
}

ASSEMBLER_TEST_RUN(BitTestImmediate, test) {
  typedef int (*BitTestImmediate)();
  EXPECT_EQ(1, reinterpret_cast<BitTestImmediate>(test->entry())());
  EXPECT_DISASSEMBLY(
      "movl r11,0x20\n"
      "bt r11,5\n"
      "jc 0x................\n"
      "int3\n"
      "movl rax,1\n"
      "ret\n");
}

// Return 1 if equal, 0 if not equal.
ASSEMBLER_TEST_GENERATE(ConditionalMovesEqual, assembler) {
  __ movq(RDX, CallingConventions::kArg1Reg);
  __ xorq(RAX, RAX);
  __ movq(RCX, Immediate(1));
  __ cmpq(RDX, Immediate(785));
  __ cmoveq(RAX, RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(ConditionalMovesEqual, test) {
  typedef int (*ConditionalMovesEqualCode)(int i);
  int res = reinterpret_cast<ConditionalMovesEqualCode>(test->entry())(785);
  EXPECT_EQ(1, res);
  res = reinterpret_cast<ConditionalMovesEqualCode>(test->entry())(-12);
  EXPECT_EQ(0, res);
  EXPECT_DISASSEMBLY_ENDS_WITH(
      "xorq rax,rax\n"
      "movl rcx,1\n"
      "cmpq rdx,0x...\n"
      "cmovzq rax,rcx\n"
      "ret\n");
}

// Return 1 if overflow, 0 if no overflow.
ASSEMBLER_TEST_GENERATE(ConditionalMovesNoOverflow, assembler) {
  __ movq(RDX, CallingConventions::kArg1Reg);
  __ addq(RDX, CallingConventions::kArg2Reg);
  __ movq(RAX, Immediate(1));
  __ movq(RCX, Immediate(0));
  __ cmovnoq(RAX, RCX);
  __ ret();
}

ASSEMBLER_TEST_RUN(ConditionalMovesNoOverflow, test) {
  typedef int (*ConditionalMovesNoOverflowCode)(int64_t i, int64_t j);
  int res = reinterpret_cast<ConditionalMovesNoOverflowCode>(test->entry())(
      0x7fffffffffffffff, 2);
  EXPECT_EQ(1, res);
  res = reinterpret_cast<ConditionalMovesNoOverflowCode>(test->entry())(1, 1);
  EXPECT_EQ(0, res);
  EXPECT_DISASSEMBLY_NOT_WINDOWS(
      "movq rdx,rdi\n"
      "addq rdx,rsi\n"
      "movl rax,1\n"
      "movl rcx,0\n"
      "cmovnoq rax,rcx\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(ImmediateMacros, assembler) {
  const intptr_t kBillion = 1000 * 1000 * 1000;
  {
    __ LoadImmediate(RAX, Immediate(42));
    __ MulImmediate(RAX, Immediate(kBillion));
    Label ok;
    __ CompareImmediate(RAX, Immediate(42 * kBillion));
    __ j(EQUAL, &ok);
    __ int3();  // MulImmediate 64 bit.
    __ Bind(&ok);
  }
  {
    __ LoadImmediate(RAX, Immediate(42));
    __ MulImmediate(RAX, Immediate(kBillion), kFourBytes);
    Label ok;
    __ CompareImmediate(RAX, Immediate((42 * kBillion) & 0xffffffffll));
    __ j(EQUAL, &ok);
    __ int3();  // MulImmediate 32 bit.
    __ Bind(&ok);
  }
  {
    __ LoadImmediate(RAX, Immediate(kBillion));
    __ AddImmediate(RAX, Immediate(41 * kBillion));
    Label ok;
    __ CompareImmediate(RAX, Immediate(42 * kBillion));
    __ j(EQUAL, &ok);
    __ int3();  // AddImmediate 64 bit.
    __ Bind(&ok);
  }
  {
    __ LoadImmediate(RAX, Immediate(kBillion));
    __ AddImmediate(RAX, Immediate(kBillion), kFourBytes);
    __ AddImmediate(RAX, Immediate(kBillion), kFourBytes);
    __ AddImmediate(RAX, Immediate(kBillion), kFourBytes);
    Label ok;
    __ CompareImmediate(RAX, Immediate((4 * kBillion) & 0xffffffffll));
    __ j(EQUAL, &ok);
    __ int3();  // AddImmediate 32 bit.
    __ Bind(&ok);
  }
  {
    __ LoadImmediate(RAX, Immediate(kBillion));
    __ AddImmediate(RAX, Immediate(static_cast<int32_t>(3 * kBillion)),
                    kFourBytes);
    __ AddImmediate(RAX, Immediate(kBillion), kFourBytes);
    __ AddImmediate(RAX, Immediate(-kBillion), kFourBytes);
    Label ok;
    __ CompareImmediate(RAX, Immediate((4 * kBillion) & 0xffffffffll));
    __ j(EQUAL, &ok);
    __ int3();  // AddImmediate negative 32 bit.
    __ Bind(&ok);
  }
  {
    __ LoadImmediate(RAX, Immediate(kBillion));
    __ SubImmediate(RAX, Immediate(43 * kBillion));
    Label ok;
    __ CompareImmediate(RAX, Immediate(-42 * kBillion));
    __ j(EQUAL, &ok);
    __ int3();  // AddImmediate negative 64 bit.
    __ Bind(&ok);
  }
  {
    __ LoadImmediate(RAX, Immediate(-kBillion));
    __ SubImmediate(RAX, Immediate(kBillion), kFourBytes);
    __ SubImmediate(RAX, Immediate(kBillion), kFourBytes);
    __ SubImmediate(RAX, Immediate(kBillion), kFourBytes);
    Label ok;
    __ CompareImmediate(RAX, Immediate((-4 * kBillion) & 0xffffffffll));
    __ j(EQUAL, &ok);
    __ int3();  // SubImmediate 32 bit.
    __ Bind(&ok);
  }
  {
    __ LoadImmediate(RAX, Immediate(kBillion));
    __ SubImmediate(RAX, Immediate((-3 * kBillion) & 0xffffffffll), kFourBytes);
    __ SubImmediate(RAX, Immediate(kBillion), kFourBytes);
    __ SubImmediate(RAX, Immediate(-kBillion), kFourBytes);
    Label ok;
    __ CompareImmediate(RAX, Immediate((4 * kBillion) & 0xffffffffll));
    __ j(EQUAL, &ok);
    __ int3();  // SubImmediate 32 bit.
    __ Bind(&ok);
  }
  __ LoadImmediate(RAX, Immediate(42));
  __ ret();
}

ASSEMBLER_TEST_RUN(ImmediateMacros, test) {
  typedef int (*ImmediateMacrosCode)();
  int res = reinterpret_cast<ImmediateMacrosCode>(test->entry())();
  EXPECT_EQ(42, res);
  EXPECT_DISASSEMBLY(
      "movl rax,0x2a\n"
      "imulq rax,rax,0x........\n"
      "movq r11,0x................\n"
      "cmpq rax,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,0x2a\n"
      "imull rax,rax,0x........\n"
      "movl r11,0x........\n"
      "cmpq rax,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,0x........\n"
      "movq r11,0x................\n"
      "addq rax,r11\n"
      "movq r11,0x................\n"
      "cmpq rax,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,0x........\n"
      "addl rax,0x........\n"
      "addl rax,0x........\n"
      "addl rax,0x........\n"
      "movl r11,0x........\n"
      "cmpq rax,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,0x........\n"
      "subl rax,0x........\n"
      "addl rax,0x........\n"
      "subl rax,0x........\n"
      "movl r11,0x........\n"
      "cmpq rax,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,0x........\n"
      "movq r11,0x................\n"
      "subq rax,r11\n"
      "movq r11,0x................\n"
      "cmpq rax,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movq rax,-0x........\n"
      "subl rax,0x........\n"
      "subl rax,0x........\n"
      "subl rax,0x........\n"
      "cmpq rax,0x........\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,0x........\n"
      "subl rax,0x........\n"
      "subl rax,0x........\n"
      "addl rax,0x........\n"
      "movl r11,0x........\n"
      "cmpq rax,r11\n"
      "jz 0x................\n"
      "int3\n"
      "movl rax,0x2a\n"
      "ret\n");
}

// clang-format off
#define ALU_TEST(NAME, WIDTH, INTRO, LHS, RHS, OUTRO)                          \
  ASSEMBLER_TEST_GENERATE(NAME, assembler) {                                   \
    int32_t input1_w = static_cast<int32_t>(0x87654321);                       \
    int32_t input1_l = input1_w;                                               \
    int64_t input1_q = 0xfedcba987654321ll;                                    \
    input1_##WIDTH += input1_w * 0 + input1_l * 0 + input1_q * 0;              \
    int32_t input2_w = static_cast<int32_t>(0x12345678);                       \
    int32_t input2_l = input2_w;                                               \
    int64_t input2_q = 0xabcdef912345678ll;                                    \
    input2_##WIDTH += input2_w * 0 + input2_l * 0 + input2_q * 0;              \
                                                                               \
    __ movq(RAX, Immediate(input1_##WIDTH));                                   \
    __ movq(RCX, Immediate(input2_##WIDTH));                                   \
                                                                               \
    INTRO;                                                                     \
                                                                               \
    __ and##WIDTH(LHS, RHS);                                                   \
    __ or##WIDTH(RHS, LHS);                                                    \
    __ xor##WIDTH(LHS, RHS);                                                   \
    __ add##WIDTH(RHS, LHS);                                                   \
    __ cmp##WIDTH(LHS, RHS);                                                   \
    __ adc##WIDTH(LHS, RHS);                                                   \
    __ sub##WIDTH(RHS, LHS);                                                   \
    __ sbb##WIDTH(LHS, RHS);                                                   \
                                                                               \
    OUTRO;                                                                     \
    /* A sort of movx(RAX, RAX) */                                             \
    __ xorq(RCX, RCX);                                                         \
    __ add##WIDTH(RCX, RAX);                                                   \
    __ andq(RAX, RCX);                                                         \
    __ ret();                                                                  \
  }                                                                            \
                                                                               \
  ASSEMBLER_TEST_RUN(NAME, test) {                                             \
    typedef uint64_t (*NAME)();                                                \
    uint64_t expectation_q = 0xaed1be942649381ll;                              \
    uint32_t expectation_l = expectation_q;                                    \
    uint16_t expectation_w = expectation_l;                                    \
    uint64_t expectation = expectation_##WIDTH | expectation_w;                \
    EXPECT_EQ(expectation, reinterpret_cast<NAME>(test->entry())());           \
  }
// clang-format on

ALU_TEST(RegRegW, w, , RAX, RCX, )
ALU_TEST(RegAddrW1, w, __ pushq(RAX), Address(RSP, 0), RCX, __ popq(RAX))
ALU_TEST(RegAddrW2, w, __ pushq(RCX), RAX, Address(RSP, 0), __ popq(RCX))
ALU_TEST(RegRegL, l, , RAX, RCX, )
ALU_TEST(RegAddrL1, l, __ pushq(RAX), Address(RSP, 0), RCX, __ popq(RAX))
ALU_TEST(RegAddrL2, l, __ pushq(RCX), RAX, Address(RSP, 0), __ popq(RCX))
ALU_TEST(RegRegQ, q, , RAX, RCX, )
ALU_TEST(RegAddrQ1, q, __ pushq(RAX), Address(RSP, 0), RCX, __ popq(RAX))
ALU_TEST(RegAddrQ2, q, __ pushq(RCX), RAX, Address(RSP, 0), __ popq(RCX))

#define IMMEDIATE_TEST(NAME, REG, MASK, INTRO, VALUE, OUTRO)                   \
  ASSEMBLER_TEST_GENERATE(NAME, assembler) {                                   \
    __ movl(REG, Immediate(static_cast<int32_t>(0x87654321)));                 \
                                                                               \
    INTRO;                                                                     \
                                                                               \
    __ andl(VALUE, Immediate(static_cast<int32_t>(0xa8df51d3 & MASK)));        \
    __ orl(VALUE, Immediate(0x1582a681 & MASK));                               \
    __ xorl(VALUE, Immediate(static_cast<int32_t>(0xa5a5a5a5 & MASK)));        \
    __ addl(VALUE, Immediate(0x7fffffff & MASK));                              \
    __ cmpl(VALUE, Immediate(0x40404040 & MASK));                              \
    __ adcl(VALUE, Immediate(0x6eeeeeee & MASK));                              \
    __ subl(VALUE, Immediate(0x7eeeeeee & MASK));                              \
    __ sbbl(VALUE, Immediate(0x6fffffff & MASK));                              \
                                                                               \
    OUTRO;                                                                     \
                                                                               \
    __ movl(RAX, REG);                                                         \
    __ ret();                                                                  \
  }                                                                            \
                                                                               \
  ASSEMBLER_TEST_RUN(NAME, test) {                                             \
    typedef uint64_t (*NAME)();                                                \
    unsigned expectation = MASK < 0x100 ? 0x24 : 0x30624223;                   \
    EXPECT_EQ(expectation, reinterpret_cast<NAME>(test->entry())());           \
  }

// RAX-based instructions have different encodings so we test both RAX and RCX.
// If the immediate can be encoded as one byte there is also a different
// encoding, so test that too.
IMMEDIATE_TEST(RegImmRAX, RAX, 0xffffffff, , RAX, )
IMMEDIATE_TEST(RegImmRCX, RCX, 0xffffffff, , RCX, )
IMMEDIATE_TEST(RegImmRAXByte, RAX, 0x7f, , RAX, )
IMMEDIATE_TEST(RegImmRCXByte, RCX, 0x7f, , RCX, )
IMMEDIATE_TEST(AddrImmRAX,
               RAX,
               0xffffffff,
               __ pushq(RAX),
               Address(RSP, 0),
               __ popq(RAX))
IMMEDIATE_TEST(AddrImmRAXByte,
               RAX,
               0x7f,
               __ pushq(RAX),
               Address(RSP, 0),
               __ popq(RAX))

}  // namespace compiler
}  // namespace dart

#endif  // defined TARGET_ARCH_X64
