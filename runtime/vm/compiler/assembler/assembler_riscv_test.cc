// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

#include "vm/compiler/assembler/assembler.h"
#include "vm/cpu.h"
#include "vm/os.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {
namespace compiler {
#define __ assembler->

#if defined(PRODUCT)
#define EXPECT_DISASSEMBLY(expected)
#else
#define EXPECT_DISASSEMBLY(expected)                                           \
  EXPECT_STREQ(expected, test->RelativeDisassembly())
#endif

// Called from assembler_test.cc.
// RA: return address.
// A0: value.
// A1: growable array.
// A2: current thread.
ASSEMBLER_TEST_GENERATE(StoreIntoObject, assembler) {
  __ PushRegister(RA);
  __ PushNativeCalleeSavedRegisters();

  __ mv(THR, A2);
  __ RestorePinnedRegisters();  // Setup WRITE_BARRIER_STATE.

  __ StoreIntoObject(A1, FieldAddress(A1, GrowableObjectArray::data_offset()),
                     A0);

  __ PopNativeCalleeSavedRegisters();
  __ PopRegister(RA);
  __ ret();
}

static intx_t Call(intx_t entry,
                   intx_t arg0 = 0,
                   intx_t arg1 = 0,
                   intx_t arg2 = 0,
                   intx_t arg3 = 0) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->Call(entry, arg0, arg1, arg2, arg3);
#else
  typedef intx_t (*F)(intx_t, intx_t, intx_t, intx_t);
  return reinterpret_cast<F>(entry)(arg0, arg1, arg2, arg3);
#endif
}
static float CallF(intx_t entry, intx_t arg0) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallF(entry, arg0);
#else
  typedef float (*F)(intx_t);
  return reinterpret_cast<F>(entry)(arg0);
#endif
}
static float CallF(intx_t entry, intx_t arg0, float arg1) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallF(entry, arg0, arg1);
#else
  typedef float (*F)(intx_t, float);
  return reinterpret_cast<F>(entry)(arg0, arg1);
#endif
}
static float CallF(intx_t entry, double arg0) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallF(entry, arg0);
#else
  typedef float (*F)(double);
  return reinterpret_cast<F>(entry)(arg0);
#endif
}
static float CallF(intx_t entry, float arg0) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallF(entry, arg0);
#else
  typedef float (*F)(float);
  return reinterpret_cast<F>(entry)(arg0);
#endif
}
static float CallF(intx_t entry, float arg0, float arg1) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallF(entry, arg0, arg1);
#else
  typedef float (*F)(float, float);
  return reinterpret_cast<F>(entry)(arg0, arg1);
#endif
}
static float CallF(intx_t entry, float arg0, float arg1, float arg2) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallF(entry, arg0, arg1, arg2);
#else
  typedef float (*F)(float, float, float);
  return reinterpret_cast<F>(entry)(arg0, arg1, arg2);
#endif
}
static intx_t CallI(intx_t entry, float arg0) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallI(entry, arg0);
#else
  typedef intx_t (*F)(float);
  return reinterpret_cast<F>(entry)(arg0);
#endif
}
static intx_t CallI(intx_t entry, float arg0, float arg1) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallI(entry, arg0, arg1);
#else
  typedef intx_t (*F)(float, float);
  return reinterpret_cast<F>(entry)(arg0, arg1);
#endif
}
static double CallD(intx_t entry, intx_t arg0) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallD(entry, arg0);
#else
  typedef double (*F)(intx_t);
  return reinterpret_cast<F>(entry)(arg0);
#endif
}
static double CallD(intx_t entry, intx_t arg0, double arg1) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallD(entry, arg0, arg1);
#else
  typedef double (*F)(intx_t, double);
  return reinterpret_cast<F>(entry)(arg0, arg1);
#endif
}
static double CallD(intx_t entry, float arg0) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallD(entry, arg0);
#else
  typedef double (*F)(float);
  return reinterpret_cast<F>(entry)(arg0);
#endif
}
static double CallD(intx_t entry, double arg0) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallD(entry, arg0);
#else
  typedef double (*F)(double);
  return reinterpret_cast<F>(entry)(arg0);
#endif
}
static double CallD(intx_t entry, double arg0, double arg1) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallD(entry, arg0, arg1);
#else
  typedef double (*F)(double, double);
  return reinterpret_cast<F>(entry)(arg0, arg1);
#endif
}
static double CallD(intx_t entry, double arg0, double arg1, double arg2) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallD(entry, arg0, arg1, arg2);
#else
  typedef double (*F)(double, double, double);
  return reinterpret_cast<F>(entry)(arg0, arg1, arg2);
#endif
}
static intx_t CallI(intx_t entry, double arg0) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallI(entry, arg0);
#else
  typedef intx_t (*F)(double);
  return reinterpret_cast<F>(entry)(arg0);
#endif
}
static intx_t CallI(intx_t entry, double arg0, double arg1) {
#if defined(USING_SIMULATOR)
  return Simulator::Current()->CallI(entry, arg0, arg1);
#else
  typedef intx_t (*F)(double, double);
  return reinterpret_cast<F>(entry)(arg0, arg1);
#endif
}

ASSEMBLER_TEST_GENERATE(LoadUpperImmediate, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  __ lui(A0, 42 << 16);
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadUpperImmediate, test) {
  EXPECT_DISASSEMBLY(
      "002a0537 lui a0, 2752512\n"
      "00008067 ret\n");
  EXPECT_EQ(42 << 16, Call(test->entry()));
}

ASSEMBLER_TEST_GENERATE(AddUpperImmediatePC, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  __ auipc(A0, 0);
  __ ret();
}
ASSEMBLER_TEST_RUN(AddUpperImmediatePC, test) {
  EXPECT_DISASSEMBLY(
      "00000517 auipc a0, 0\n"
      "00008067 ret\n");
  EXPECT_EQ(test->entry(), static_cast<uintx_t>(Call(test->entry())));
}

ASSEMBLER_TEST_GENERATE(JumpAndLink, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label1, label2;
  __ jal(T4, &label1);  // Forward.
  __ sub(A0, T0, T1);
  __ ret();
  __ trap();

  __ Bind(&label2);
  __ li(T1, 7);
  __ jalr(ZR, T5);
  __ trap();

  __ Bind(&label1);
  __ li(T0, 4);
  __ jal(T5, &label2);  // Backward.
  __ jalr(ZR, T4);
  __ trap();
}
ASSEMBLER_TEST_RUN(JumpAndLink, test) {
  EXPECT_DISASSEMBLY(
      "01c00eef jal t4, +28\n"
      "40628533 sub a0, t0, t1\n"
      "00008067 ret\n"
      "00000000 trap\n"
      "00700313 li t1, 7\n"
      "000f0067 jr t5\n"
      "00000000 trap\n"
      "00400293 li t0, 4\n"
      "ff1fff6f jal t5, -16\n"
      "000e8067 jr t4\n"
      "00000000 trap\n");
  EXPECT_EQ(-3, Call(test->entry()));
}

ASSEMBLER_TEST_GENERATE(Jump, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label1, label2;
  __ j(&label1);  // Forward.
  __ trap();
  __ Bind(&label2);
  __ li(T1, 7);
  __ sub(A0, T0, T1);
  __ ret();
  __ Bind(&label1);
  __ li(T0, 4);
  __ j(&label2);  // Backward.
  __ trap();
}
ASSEMBLER_TEST_RUN(Jump, test) {
  EXPECT_DISASSEMBLY(
      "0140006f j +20\n"
      "00000000 trap\n"
      "00700313 li t1, 7\n"
      "40628533 sub a0, t0, t1\n"
      "00008067 ret\n"
      "00400293 li t0, 4\n"
      "ff1ff06f j -16\n"
      "00000000 trap\n");
  EXPECT_EQ(-3, Call(test->entry()));
}

ASSEMBLER_TEST_GENERATE(JumpAndLinkRegister, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  /* 00 */ __ jalr(T4, A1, 28);  // Forward.
  /* 04 */ __ sub(A0, T0, T1);
  /* 08 */ __ ret();
  /* 12 */ __ trap();

  /* 16 */ __ li(T1, 7);
  /* 20 */ __ jalr(ZR, T5);
  /* 24 */ __ trap();

  /* 28 */ __ li(T0, 4);
  /* 32 */ __ jalr(T5, A1, 16);  // Backward.
  /* 36 */ __ jalr(ZR, T4);
  /* 40 */ __ trap();
}
ASSEMBLER_TEST_RUN(JumpAndLinkRegister, test) {
  EXPECT_DISASSEMBLY(
      "01c58ee7 jalr t4, 28(a1)\n"
      "40628533 sub a0, t0, t1\n"
      "00008067 ret\n"
      "00000000 trap\n"
      "00700313 li t1, 7\n"
      "000f0067 jr t5\n"
      "00000000 trap\n"
      "00400293 li t0, 4\n"
      "01058f67 jalr t5, 16(a1)\n"
      "000e8067 jr t4\n"
      "00000000 trap\n");
  EXPECT_EQ(-3, Call(test->entry(), 0, test->entry()));
}

ASSEMBLER_TEST_GENERATE(JumpRegister, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  /* 00 */ __ jr(A1, 20);  // Forward.
  /* 04 */ __ trap();
  /* 08 */ __ li(T1, 7);
  /* 12 */ __ sub(A0, T0, T1);
  /* 16 */ __ ret();
  /* 20 */ __ li(T0, 4);
  /* 24 */ __ jr(A1, 8);  // Backward.
  /* 28 */ __ trap();
}
ASSEMBLER_TEST_RUN(JumpRegister, test) {
  EXPECT_DISASSEMBLY(
      "01458067 jr 20(a1)\n"
      "00000000 trap\n"
      "00700313 li t1, 7\n"
      "40628533 sub a0, t0, t1\n"
      "00008067 ret\n"
      "00400293 li t0, 4\n"
      "00858067 jr 8(a1)\n"
      "00000000 trap\n");
  EXPECT_EQ(-3, Call(test->entry(), 0, test->entry()));
}

ASSEMBLER_TEST_GENERATE(BranchEqualForward, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ beq(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchEqualForward, test) {
  EXPECT_DISASSEMBLY(
      "00b50663 beq a0, a1, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(4, Call(test->entry(), 1, 1));
  EXPECT_EQ(3, Call(test->entry(), 1, 0));
  EXPECT_EQ(3, Call(test->entry(), 1, -1));
  EXPECT_EQ(3, Call(test->entry(), 0, 1));
  EXPECT_EQ(4, Call(test->entry(), 0, 0));
  EXPECT_EQ(3, Call(test->entry(), 0, -1));
  EXPECT_EQ(3, Call(test->entry(), -1, 1));
  EXPECT_EQ(3, Call(test->entry(), -1, 0));
  EXPECT_EQ(4, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(BranchEqualForwardFar, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ beq(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  for (intptr_t i = 0; i < (1 << 13); i++) {
    __ ebreak();
  }
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchEqualForwardFar, test) {
  //  EXPECT_DISASSEMBLY(constant too big);
  EXPECT_EQ(4, Call(test->entry(), 1, 1));
  EXPECT_EQ(3, Call(test->entry(), 1, 0));
  EXPECT_EQ(3, Call(test->entry(), 1, -1));
  EXPECT_EQ(3, Call(test->entry(), 0, 1));
  EXPECT_EQ(4, Call(test->entry(), 0, 0));
  EXPECT_EQ(3, Call(test->entry(), 0, -1));
  EXPECT_EQ(3, Call(test->entry(), -1, 1));
  EXPECT_EQ(3, Call(test->entry(), -1, 0));
  EXPECT_EQ(4, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(BranchNotEqualForward, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ bne(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchNotEqualForward, test) {
  EXPECT_DISASSEMBLY(
      "00b51663 bne a0, a1, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(3, Call(test->entry(), 1, 1));
  EXPECT_EQ(4, Call(test->entry(), 1, 0));
  EXPECT_EQ(4, Call(test->entry(), 1, -1));
  EXPECT_EQ(4, Call(test->entry(), 0, 1));
  EXPECT_EQ(3, Call(test->entry(), 0, 0));
  EXPECT_EQ(4, Call(test->entry(), 0, -1));
  EXPECT_EQ(4, Call(test->entry(), -1, 1));
  EXPECT_EQ(4, Call(test->entry(), -1, 0));
  EXPECT_EQ(3, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(BranchNotEqualForwardFar, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ bne(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  for (intptr_t i = 0; i < (1 << 13); i++) {
    __ ebreak();
  }
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchNotEqualForwardFar, test) {
  //  EXPECT_DISASSEMBLY(constant too big);
  EXPECT_EQ(3, Call(test->entry(), 1, 1));
  EXPECT_EQ(4, Call(test->entry(), 1, 0));
  EXPECT_EQ(4, Call(test->entry(), 1, -1));
  EXPECT_EQ(4, Call(test->entry(), 0, 1));
  EXPECT_EQ(3, Call(test->entry(), 0, 0));
  EXPECT_EQ(4, Call(test->entry(), 0, -1));
  EXPECT_EQ(4, Call(test->entry(), -1, 1));
  EXPECT_EQ(4, Call(test->entry(), -1, 0));
  EXPECT_EQ(3, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(BranchLessThanForward, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ blt(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchLessThanForward, test) {
  EXPECT_DISASSEMBLY(
      "00b54663 blt a0, a1, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(3, Call(test->entry(), 1, 1));
  EXPECT_EQ(3, Call(test->entry(), 1, 0));
  EXPECT_EQ(3, Call(test->entry(), 1, -1));
  EXPECT_EQ(4, Call(test->entry(), 0, 1));
  EXPECT_EQ(3, Call(test->entry(), 0, 0));
  EXPECT_EQ(3, Call(test->entry(), 0, -1));
  EXPECT_EQ(4, Call(test->entry(), -1, 1));
  EXPECT_EQ(4, Call(test->entry(), -1, 0));
  EXPECT_EQ(3, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(BranchLessThanForwardFar, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ blt(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  for (intptr_t i = 0; i < (1 << 13); i++) {
    __ ebreak();
  }
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchLessThanForwardFar, test) {
  //  EXPECT_DISASSEMBLY(constant too big);
  EXPECT_EQ(3, Call(test->entry(), 1, 1));
  EXPECT_EQ(3, Call(test->entry(), 1, 0));
  EXPECT_EQ(3, Call(test->entry(), 1, -1));
  EXPECT_EQ(4, Call(test->entry(), 0, 1));
  EXPECT_EQ(3, Call(test->entry(), 0, 0));
  EXPECT_EQ(3, Call(test->entry(), 0, -1));
  EXPECT_EQ(4, Call(test->entry(), -1, 1));
  EXPECT_EQ(4, Call(test->entry(), -1, 0));
  EXPECT_EQ(3, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(BranchLessOrEqualForward, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ ble(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchLessOrEqualForward, test) {
  EXPECT_DISASSEMBLY(
      "00a5d663 ble a0, a1, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(4, Call(test->entry(), 1, 1));
  EXPECT_EQ(3, Call(test->entry(), 1, 0));
  EXPECT_EQ(3, Call(test->entry(), 1, -1));
  EXPECT_EQ(4, Call(test->entry(), 0, 1));
  EXPECT_EQ(4, Call(test->entry(), 0, 0));
  EXPECT_EQ(3, Call(test->entry(), 0, -1));
  EXPECT_EQ(4, Call(test->entry(), -1, 1));
  EXPECT_EQ(4, Call(test->entry(), -1, 0));
  EXPECT_EQ(4, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(BranchLessOrEqualForwardFar, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ ble(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  for (intptr_t i = 0; i < (1 << 13); i++) {
    __ ebreak();
  }
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchLessOrEqualForwardFar, test) {
  //  EXPECT_DISASSEMBLY(constant too big);
  EXPECT_EQ(4, Call(test->entry(), 1, 1));
  EXPECT_EQ(3, Call(test->entry(), 1, 0));
  EXPECT_EQ(3, Call(test->entry(), 1, -1));
  EXPECT_EQ(4, Call(test->entry(), 0, 1));
  EXPECT_EQ(4, Call(test->entry(), 0, 0));
  EXPECT_EQ(3, Call(test->entry(), 0, -1));
  EXPECT_EQ(4, Call(test->entry(), -1, 1));
  EXPECT_EQ(4, Call(test->entry(), -1, 0));
  EXPECT_EQ(4, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(BranchGreaterThanForward, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ bgt(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchGreaterThanForward, test) {
  EXPECT_DISASSEMBLY(
      "00a5c663 blt a1, a0, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(3, Call(test->entry(), 1, 1));
  EXPECT_EQ(4, Call(test->entry(), 1, 0));
  EXPECT_EQ(4, Call(test->entry(), 1, -1));
  EXPECT_EQ(3, Call(test->entry(), 0, 1));
  EXPECT_EQ(3, Call(test->entry(), 0, 0));
  EXPECT_EQ(4, Call(test->entry(), 0, -1));
  EXPECT_EQ(3, Call(test->entry(), -1, 1));
  EXPECT_EQ(3, Call(test->entry(), -1, 0));
  EXPECT_EQ(3, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(BranchGreaterOrEqualForward, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ bge(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchGreaterOrEqualForward, test) {
  EXPECT_DISASSEMBLY(
      "00b55663 ble a1, a0, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(4, Call(test->entry(), 1, 1));
  EXPECT_EQ(4, Call(test->entry(), 1, 0));
  EXPECT_EQ(4, Call(test->entry(), 1, -1));
  EXPECT_EQ(3, Call(test->entry(), 0, 1));
  EXPECT_EQ(4, Call(test->entry(), 0, 0));
  EXPECT_EQ(4, Call(test->entry(), 0, -1));
  EXPECT_EQ(3, Call(test->entry(), -1, 1));
  EXPECT_EQ(3, Call(test->entry(), -1, 0));
  EXPECT_EQ(4, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(BranchLessThanUnsignedForward, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ bltu(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchLessThanUnsignedForward, test) {
  EXPECT_DISASSEMBLY(
      "00b56663 bltu a0, a1, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(3, Call(test->entry(), 1, 1));
  EXPECT_EQ(3, Call(test->entry(), 1, 0));
  EXPECT_EQ(4, Call(test->entry(), 1, -1));
  EXPECT_EQ(4, Call(test->entry(), 0, 1));
  EXPECT_EQ(3, Call(test->entry(), 0, 0));
  EXPECT_EQ(4, Call(test->entry(), 0, -1));
  EXPECT_EQ(3, Call(test->entry(), -1, 1));
  EXPECT_EQ(3, Call(test->entry(), -1, 0));
  EXPECT_EQ(3, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(BranchLessOrEqualUnsignedForward, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ bleu(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchLessOrEqualUnsignedForward, test) {
  EXPECT_DISASSEMBLY(
      "00a5f663 bleu a0, a1, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(4, Call(test->entry(), 1, 1));
  EXPECT_EQ(3, Call(test->entry(), 1, 0));
  EXPECT_EQ(4, Call(test->entry(), 1, -1));
  EXPECT_EQ(4, Call(test->entry(), 0, 1));
  EXPECT_EQ(4, Call(test->entry(), 0, 0));
  EXPECT_EQ(4, Call(test->entry(), 0, -1));
  EXPECT_EQ(3, Call(test->entry(), -1, 1));
  EXPECT_EQ(3, Call(test->entry(), -1, 0));
  EXPECT_EQ(4, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(BranchGreaterThanUnsignedForward, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ bgtu(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchGreaterThanUnsignedForward, test) {
  EXPECT_DISASSEMBLY(
      "00a5e663 bltu a1, a0, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(3, Call(test->entry(), 1, 1));
  EXPECT_EQ(4, Call(test->entry(), 1, 0));
  EXPECT_EQ(3, Call(test->entry(), 1, -1));
  EXPECT_EQ(3, Call(test->entry(), 0, 1));
  EXPECT_EQ(3, Call(test->entry(), 0, 0));
  EXPECT_EQ(3, Call(test->entry(), 0, -1));
  EXPECT_EQ(4, Call(test->entry(), -1, 1));
  EXPECT_EQ(4, Call(test->entry(), -1, 0));
  EXPECT_EQ(3, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(BranchGreaterOrEqualUnsignedForward, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);

  Label label;
  __ bgeu(A0, A1, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchGreaterOrEqualUnsignedForward, test) {
  EXPECT_DISASSEMBLY(
      "00b57663 bleu a1, a0, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(4, Call(test->entry(), 1, 1));
  EXPECT_EQ(4, Call(test->entry(), 1, 0));
  EXPECT_EQ(3, Call(test->entry(), 1, -1));
  EXPECT_EQ(3, Call(test->entry(), 0, 1));
  EXPECT_EQ(4, Call(test->entry(), 0, 0));
  EXPECT_EQ(3, Call(test->entry(), 0, -1));
  EXPECT_EQ(4, Call(test->entry(), -1, 1));
  EXPECT_EQ(4, Call(test->entry(), -1, 0));
  EXPECT_EQ(4, Call(test->entry(), -1, -1));
}

ASSEMBLER_TEST_GENERATE(LoadByte_0, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lb(A0, Address(A0, 0));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadByte_0, test) {
  EXPECT_DISASSEMBLY(
      "00050503 lb a0, 0(a0)\n"
      "00008067 ret\n");

  uint8_t* values = reinterpret_cast<uint8_t*>(malloc(3 * sizeof(uint8_t)));
  values[0] = 0xAB;
  values[1] = 0xCD;
  values[2] = 0xEF;
  EXPECT_EQ(-51, Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
  free(values);
}

ASSEMBLER_TEST_GENERATE(LoadByte_Pos, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lb(A0, Address(A0, 1));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadByte_Pos, test) {
  EXPECT_DISASSEMBLY(
      "00150503 lb a0, 1(a0)\n"
      "00008067 ret\n");

  uint8_t* values = reinterpret_cast<uint8_t*>(malloc(3 * sizeof(uint8_t)));
  values[0] = 0xAB;
  values[1] = 0xCD;
  values[2] = 0xEF;

  EXPECT_EQ(-17, Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
  free(values);
}

ASSEMBLER_TEST_GENERATE(LoadByte_Neg, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lb(A0, Address(A0, -1));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadByte_Neg, test) {
  EXPECT_DISASSEMBLY(
      "fff50503 lb a0, -1(a0)\n"
      "00008067 ret\n");

  uint8_t* values = reinterpret_cast<uint8_t*>(malloc(3 * sizeof(uint8_t)));
  values[0] = 0xAB;
  values[1] = 0xCD;
  values[2] = 0xEF;

  EXPECT_EQ(-85, Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
  free(values);
}

ASSEMBLER_TEST_GENERATE(LoadByteUnsigned_0, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lbu(A0, Address(A0, 0));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadByteUnsigned_0, test) {
  EXPECT_DISASSEMBLY(
      "00054503 lbu a0, 0(a0)\n"
      "00008067 ret\n");

  uint8_t* values = reinterpret_cast<uint8_t*>(malloc(3 * sizeof(uint8_t)));
  values[0] = 0xAB;
  values[1] = 0xCD;
  values[2] = 0xEF;

  EXPECT_EQ(0xCD, Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
  free(values);
}

ASSEMBLER_TEST_GENERATE(LoadByteUnsigned_Pos, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lbu(A0, Address(A0, 1));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadByteUnsigned_Pos, test) {
  EXPECT_DISASSEMBLY(
      "00154503 lbu a0, 1(a0)\n"
      "00008067 ret\n");

  uint8_t* values = reinterpret_cast<uint8_t*>(malloc(3 * sizeof(uint8_t)));
  values[0] = 0xAB;
  values[1] = 0xCD;
  values[2] = 0xEF;

  EXPECT_EQ(0xEF, Call(test->entry(), reinterpret_cast<intx_t>((&values[1]))));
  free(values);
}

ASSEMBLER_TEST_GENERATE(LoadByteUnsigned_Neg, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lbu(A0, Address(A0, -1));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadByteUnsigned_Neg, test) {
  EXPECT_DISASSEMBLY(
      "fff54503 lbu a0, -1(a0)\n"
      "00008067 ret\n");

  uint8_t* values = reinterpret_cast<uint8_t*>(malloc(3 * sizeof(uint8_t)));
  values[0] = 0xAB;
  values[1] = 0xCD;
  values[2] = 0xEF;

  EXPECT_EQ(0xAB, Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}

ASSEMBLER_TEST_GENERATE(LoadHalfword_0, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lh(A0, Address(A0, 0));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadHalfword_0, test) {
  EXPECT_DISASSEMBLY(
      "00051503 lh a0, 0(a0)\n"
      "00008067 ret\n");

  uint16_t* values = reinterpret_cast<uint16_t*>(malloc(3 * sizeof(uint16_t)));
  values[0] = 0xAB01;
  values[1] = 0xCD02;
  values[2] = 0xEF03;

  EXPECT_EQ(-13054, Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}
ASSEMBLER_TEST_GENERATE(LoadHalfword_Pos, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lh(A0, Address(A0, 2));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadHalfword_Pos, test) {
  EXPECT_DISASSEMBLY(
      "00251503 lh a0, 2(a0)\n"
      "00008067 ret\n");

  uint16_t* values = reinterpret_cast<uint16_t*>(malloc(3 * sizeof(uint16_t)));
  values[0] = 0xAB01;
  values[1] = 0xCD02;
  values[2] = 0xEF03;

  EXPECT_EQ(-4349, Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}
ASSEMBLER_TEST_GENERATE(LoadHalfword_Neg, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lh(A0, Address(A0, -2));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadHalfword_Neg, test) {
  EXPECT_DISASSEMBLY(
      "ffe51503 lh a0, -2(a0)\n"
      "00008067 ret\n");

  uint16_t* values = reinterpret_cast<uint16_t*>(malloc(3 * sizeof(uint16_t)));
  values[0] = 0xAB01;
  values[1] = 0xCD02;
  values[2] = 0xEF03;

  EXPECT_EQ(-21759, Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}

ASSEMBLER_TEST_GENERATE(LoadHalfwordUnsigned_0, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lhu(A0, Address(A0, 0));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadHalfwordUnsigned_0, test) {
  EXPECT_DISASSEMBLY(
      "00055503 lhu a0, 0(a0)\n"
      "00008067 ret\n");

  uint16_t* values = reinterpret_cast<uint16_t*>(malloc(3 * sizeof(uint16_t)));
  values[0] = 0xAB01;
  values[1] = 0xCD02;
  values[2] = 0xEF03;

  EXPECT_EQ(0xCD02, Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}

ASSEMBLER_TEST_GENERATE(LoadHalfwordUnsigned_Pos, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lhu(A0, Address(A0, 2));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadHalfwordUnsigned_Pos, test) {
  EXPECT_DISASSEMBLY(
      "00255503 lhu a0, 2(a0)\n"
      "00008067 ret\n");

  uint16_t* values = reinterpret_cast<uint16_t*>(malloc(3 * sizeof(uint16_t)));
  values[0] = 0xAB01;
  values[1] = 0xCD02;
  values[2] = 0xEF03;

  EXPECT_EQ(0xEF03, Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}
ASSEMBLER_TEST_GENERATE(LoadHalfwordUnsigned_Neg, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lhu(A0, Address(A0, -2));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadHalfwordUnsigned_Neg, test) {
  EXPECT_DISASSEMBLY(
      "ffe55503 lhu a0, -2(a0)\n"
      "00008067 ret\n");

  uint16_t* values = reinterpret_cast<uint16_t*>(malloc(3 * sizeof(uint16_t)));
  values[0] = 0xAB01;
  values[1] = 0xCD02;
  values[2] = 0xEF03;

  EXPECT_EQ(0xAB01, Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}

ASSEMBLER_TEST_GENERATE(LoadWord_0, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lw(A0, Address(A0, 0));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadWord_0, test) {
  EXPECT_DISASSEMBLY(
      "00052503 lw a0, 0(a0)\n"
      "00008067 ret\n");

  uint32_t* values = reinterpret_cast<uint32_t*>(malloc(3 * sizeof(uint32_t)));
  values[0] = 0xAB010203;
  values[1] = 0xCD020405;
  values[2] = 0xEF030607;

  EXPECT_EQ(-855505915,
            Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}
ASSEMBLER_TEST_GENERATE(LoadWord_Pos, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lw(A0, Address(A0, 4));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadWord_Pos, test) {
  EXPECT_DISASSEMBLY(
      "00452503 lw a0, 4(a0)\n"
      "00008067 ret\n");

  uint32_t* values = reinterpret_cast<uint32_t*>(malloc(3 * sizeof(uint32_t)));
  values[0] = 0xAB010203;
  values[1] = 0xCD020405;
  values[2] = 0xEF030607;

  EXPECT_EQ(-285014521,
            Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}
ASSEMBLER_TEST_GENERATE(LoadWord_Neg, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lw(A0, Address(A0, -4));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadWord_Neg, test) {
  EXPECT_DISASSEMBLY(
      "ffc52503 lw a0, -4(a0)\n"
      "00008067 ret\n");

  uint32_t* values = reinterpret_cast<uint32_t*>(malloc(3 * sizeof(uint32_t)));
  values[0] = 0xAB010203;
  values[1] = 0xCD020405;
  values[2] = 0xEF030607;

  EXPECT_EQ(-1425997309,
            Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}

ASSEMBLER_TEST_GENERATE(StoreWord_0, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sw(A1, Address(A0, 0));
  __ ret();
}
ASSEMBLER_TEST_RUN(StoreWord_0, test) {
  EXPECT_DISASSEMBLY(
      "00b52023 sw a1, 0(a0)\n"
      "00008067 ret\n");

  uint32_t* values = reinterpret_cast<uint32_t*>(malloc(3 * sizeof(uint32_t)));
  values[0] = 0;
  values[1] = 0;
  values[2] = 0;

  Call(test->entry(), reinterpret_cast<intx_t>(&values[1]), 0xCD020405);
  EXPECT_EQ(0u, values[0]);
  EXPECT_EQ(0xCD020405, values[1]);
  EXPECT_EQ(0u, values[2]);
}
ASSEMBLER_TEST_GENERATE(StoreWord_Pos, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sw(A1, Address(A0, 4));
  __ ret();
}
ASSEMBLER_TEST_RUN(StoreWord_Pos, test) {
  EXPECT_DISASSEMBLY(
      "00b52223 sw a1, 4(a0)\n"
      "00008067 ret\n");

  uint32_t* values = reinterpret_cast<uint32_t*>(malloc(3 * sizeof(uint32_t)));
  values[0] = 0;
  values[1] = 0;
  values[2] = 0;

  Call(test->entry(), reinterpret_cast<intx_t>(&values[1]), 0xEF030607);
  EXPECT_EQ(0u, values[0]);
  EXPECT_EQ(0u, values[1]);
  EXPECT_EQ(0xEF030607, values[2]);
}
ASSEMBLER_TEST_GENERATE(StoreWord_Neg, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sw(A1, Address(A0, -4));
  __ ret();
}
ASSEMBLER_TEST_RUN(StoreWord_Neg, test) {
  EXPECT_DISASSEMBLY(
      "feb52e23 sw a1, -4(a0)\n"
      "00008067 ret\n");

  uint32_t* values = reinterpret_cast<uint32_t*>(malloc(3 * sizeof(uint32_t)));
  values[0] = 0;
  values[1] = 0;
  values[2] = 0;

  Call(test->entry(), reinterpret_cast<intx_t>(&values[1]), 0xAB010203);
  EXPECT_EQ(0xAB010203, values[0]);
  EXPECT_EQ(0u, values[1]);
  EXPECT_EQ(0u, values[2]);
}

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(LoadWordUnsigned_0, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lwu(A0, Address(A0, 0));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadWordUnsigned_0, test) {
  EXPECT_DISASSEMBLY(
      "00056503 lwu a0, 0(a0)\n"
      "00008067 ret\n");

  uint32_t* values = reinterpret_cast<uint32_t*>(malloc(3 * sizeof(uint32_t)));
  values[0] = 0xAB010203;
  values[1] = 0xCD020405;
  values[2] = 0xEF030607;

  EXPECT_EQ(0xCD020405,
            Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}
ASSEMBLER_TEST_GENERATE(LoadWordUnsigned_Pos, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lwu(A0, Address(A0, 4));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadWordUnsigned_Pos, test) {
  EXPECT_DISASSEMBLY(
      "00456503 lwu a0, 4(a0)\n"
      "00008067 ret\n");

  uint32_t* values = reinterpret_cast<uint32_t*>(malloc(3 * sizeof(uint32_t)));
  values[0] = 0xAB010203;
  values[1] = 0xCD020405;
  values[2] = 0xEF030607;

  EXPECT_EQ(0xEF030607,
            Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}
ASSEMBLER_TEST_GENERATE(LoadWordUnsigned_Neg, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lwu(A0, Address(A0, -4));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadWordUnsigned_Neg, test) {
  EXPECT_DISASSEMBLY(
      "ffc56503 lwu a0, -4(a0)\n"
      "00008067 ret\n");

  uint32_t* values = reinterpret_cast<uint32_t*>(malloc(3 * sizeof(uint32_t)));
  values[0] = 0xAB010203;
  values[1] = 0xCD020405;
  values[2] = 0xEF030607;

  EXPECT_EQ(0xAB010203,
            Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}

ASSEMBLER_TEST_GENERATE(LoadDoubleWord_0, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ ld(A0, Address(A0, 0));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadDoubleWord_0, test) {
  EXPECT_DISASSEMBLY(
      "00053503 ld a0, 0(a0)\n"
      "00008067 ret\n");

  uint64_t* values = reinterpret_cast<uint64_t*>(malloc(3 * sizeof(uint64_t)));
  values[0] = 0xAB01020304050607;
  values[1] = 0xCD02040505060708;
  values[2] = 0xEF03060708090A0B;

  EXPECT_EQ(-3674369926375274744,
            Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}
ASSEMBLER_TEST_GENERATE(LoadDoubleWord_Pos, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ ld(A0, Address(A0, 8));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadDoubleWord_Pos, test) {
  EXPECT_DISASSEMBLY(
      "00853503 ld a0, 8(a0)\n"
      "00008067 ret\n");

  uint64_t* values = reinterpret_cast<uint64_t*>(malloc(3 * sizeof(uint64_t)));
  values[0] = 0xAB01020304050607;
  values[1] = 0xCD02040505060708;
  values[2] = 0xEF03060708090A0B;

  EXPECT_EQ(-1224128046445295093,
            Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}
ASSEMBLER_TEST_GENERATE(LoadDoubleWord_Neg, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ ld(A0, Address(A0, -8));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadDoubleWord_Neg, test) {
  EXPECT_DISASSEMBLY(
      "ff853503 ld a0, -8(a0)\n"
      "00008067 ret\n");

  uint64_t* values = reinterpret_cast<uint64_t*>(malloc(3 * sizeof(uint64_t)));
  values[0] = 0xAB01020304050607;
  values[1] = 0xCD02040505060708;
  values[2] = 0xEF03060708090A0B;

  EXPECT_EQ(-6124611806271568377,
            Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}

ASSEMBLER_TEST_GENERATE(StoreDoubleWord_0, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sd(A1, Address(A0, 0));
  __ ret();
}
ASSEMBLER_TEST_RUN(StoreDoubleWord_0, test) {
  EXPECT_DISASSEMBLY(
      "00b53023 sd a1, 0(a0)\n"
      "00008067 ret\n");

  uint64_t* values = reinterpret_cast<uint64_t*>(malloc(3 * sizeof(uint64_t)));
  values[0] = 0;
  values[1] = 0;
  values[2] = 0;

  Call(test->entry(), reinterpret_cast<intx_t>(&values[1]), 0xCD02040505060708);
  EXPECT_EQ(0u, values[0]);
  EXPECT_EQ(0xCD02040505060708, values[1]);
  EXPECT_EQ(0u, values[2]);
}
ASSEMBLER_TEST_GENERATE(StoreDoubleWord_Pos, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sd(A1, Address(A0, 8));
  __ ret();
}
ASSEMBLER_TEST_RUN(StoreDoubleWord_Pos, test) {
  EXPECT_DISASSEMBLY(
      "00b53423 sd a1, 8(a0)\n"
      "00008067 ret\n");

  uint64_t* values = reinterpret_cast<uint64_t*>(malloc(3 * sizeof(uint64_t)));
  values[0] = 0;
  values[1] = 0;
  values[2] = 0;

  Call(test->entry(), reinterpret_cast<intx_t>(&values[1]), 0xEF03060708090A0B);
  EXPECT_EQ(0u, values[0]);
  EXPECT_EQ(0u, values[1]);
  EXPECT_EQ(0xEF03060708090A0B, values[2]);
}
ASSEMBLER_TEST_GENERATE(StoreDoubleWord_Neg, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sd(A1, Address(A0, -8));
  __ ret();
}
ASSEMBLER_TEST_RUN(StoreDoubleWord_Neg, test) {
  EXPECT_DISASSEMBLY(
      "feb53c23 sd a1, -8(a0)\n"
      "00008067 ret\n");

  uint64_t* values = reinterpret_cast<uint64_t*>(malloc(3 * sizeof(uint64_t)));
  values[0] = 0;
  values[1] = 0;
  values[2] = 0;

  Call(test->entry(), reinterpret_cast<intx_t>(&values[1]), 0xAB01020304050607);
  EXPECT_EQ(0xAB01020304050607, values[0]);
  EXPECT_EQ(0u, values[1]);
  EXPECT_EQ(0u, values[2]);
}
#endif

ASSEMBLER_TEST_GENERATE(AddImmediate1, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ addi(A0, A0, 42);
  __ ret();
}
ASSEMBLER_TEST_RUN(AddImmediate1, test) {
  EXPECT_DISASSEMBLY(
      "02a50513 addi a0, a0, 42\n"
      "00008067 ret\n");
  EXPECT_EQ(42, Call(test->entry(), 0));
  EXPECT_EQ(40, Call(test->entry(), -2));
  EXPECT_EQ(0, Call(test->entry(), -42));
}

ASSEMBLER_TEST_GENERATE(AddImmediate2, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ addi(A0, A0, -42);
  __ ret();
}
ASSEMBLER_TEST_RUN(AddImmediate2, test) {
  EXPECT_DISASSEMBLY(
      "fd650513 addi a0, a0, -42\n"
      "00008067 ret\n");
  EXPECT_EQ(-42, Call(test->entry(), 0));
  EXPECT_EQ(-44, Call(test->entry(), -2));
  EXPECT_EQ(38, Call(test->entry(), 80));
}

ASSEMBLER_TEST_GENERATE(SetLessThanImmediate1, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ slti(A0, A0, 7);
  __ ret();
}
ASSEMBLER_TEST_RUN(SetLessThanImmediate1, test) {
  EXPECT_DISASSEMBLY(
      "00752513 slti a0, a0, 7\n"
      "00008067 ret\n");
  EXPECT_EQ(1, Call(test->entry(), 6));
  EXPECT_EQ(0, Call(test->entry(), 7));
  EXPECT_EQ(0, Call(test->entry(), 8));
  EXPECT_EQ(1, Call(test->entry(), -6));
  EXPECT_EQ(1, Call(test->entry(), -7));
  EXPECT_EQ(1, Call(test->entry(), -8));
}

ASSEMBLER_TEST_GENERATE(SetLessThanImmediate2, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ slti(A0, A0, -7);
  __ ret();
}
ASSEMBLER_TEST_RUN(SetLessThanImmediate2, test) {
  EXPECT_DISASSEMBLY(
      "ff952513 slti a0, a0, -7\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 6));
  EXPECT_EQ(0, Call(test->entry(), 7));
  EXPECT_EQ(0, Call(test->entry(), 8));
  EXPECT_EQ(0, Call(test->entry(), -6));
  EXPECT_EQ(0, Call(test->entry(), -7));
  EXPECT_EQ(1, Call(test->entry(), -8));
}

ASSEMBLER_TEST_GENERATE(SetLessThanImmediateUnsigned1, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sltiu(A0, A0, 7);
  __ ret();
}
ASSEMBLER_TEST_RUN(SetLessThanImmediateUnsigned1, test) {
  EXPECT_DISASSEMBLY(
      "00753513 sltiu a0, a0, 7\n"
      "00008067 ret\n");
  EXPECT_EQ(1, Call(test->entry(), 6));
  EXPECT_EQ(0, Call(test->entry(), 7));
  EXPECT_EQ(0, Call(test->entry(), 8));
  EXPECT_EQ(0, Call(test->entry(), -6));
  EXPECT_EQ(0, Call(test->entry(), -7));
  EXPECT_EQ(0, Call(test->entry(), -8));
}

ASSEMBLER_TEST_GENERATE(SetLessThanImmediateUnsigned2, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sltiu(A0, A0, -7);
  __ ret();
}
ASSEMBLER_TEST_RUN(SetLessThanImmediateUnsigned2, test) {
  EXPECT_DISASSEMBLY(
      "ff953513 sltiu a0, a0, -7\n"
      "00008067 ret\n");
  EXPECT_EQ(1, Call(test->entry(), 6));
  EXPECT_EQ(1, Call(test->entry(), 7));
  EXPECT_EQ(1, Call(test->entry(), 8));
  EXPECT_EQ(0, Call(test->entry(), -6));
  EXPECT_EQ(0, Call(test->entry(), -7));
  EXPECT_EQ(1, Call(test->entry(), -8));
}

ASSEMBLER_TEST_GENERATE(XorImmediate1, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ xori(A0, A0, 42);
  __ ret();
}
ASSEMBLER_TEST_RUN(XorImmediate1, test) {
  EXPECT_DISASSEMBLY(
      "02a54513 xori a0, a0, 42\n"
      "00008067 ret\n");
  EXPECT_EQ(42, Call(test->entry(), 0));
  EXPECT_EQ(43, Call(test->entry(), 1));
  EXPECT_EQ(32, Call(test->entry(), 10));
  EXPECT_EQ(-43, Call(test->entry(), -1));
  EXPECT_EQ(-36, Call(test->entry(), -10));
}

ASSEMBLER_TEST_GENERATE(XorImmediate2, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ xori(A0, A0, -42);
  __ ret();
}
ASSEMBLER_TEST_RUN(XorImmediate2, test) {
  EXPECT_DISASSEMBLY(
      "fd654513 xori a0, a0, -42\n"
      "00008067 ret\n");
  EXPECT_EQ(-42, Call(test->entry(), 0));
  EXPECT_EQ(-41, Call(test->entry(), 1));
  EXPECT_EQ(-36, Call(test->entry(), 10));
  EXPECT_EQ(41, Call(test->entry(), -1));
  EXPECT_EQ(32, Call(test->entry(), -10));
}

ASSEMBLER_TEST_GENERATE(OrImmediate1, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ ori(A0, A0, -6);
  __ ret();
}
ASSEMBLER_TEST_RUN(OrImmediate1, test) {
  EXPECT_DISASSEMBLY(
      "ffa56513 ori a0, a0, -6\n"
      "00008067 ret\n");
  EXPECT_EQ(-6, Call(test->entry(), 0));
  EXPECT_EQ(-5, Call(test->entry(), 1));
  EXPECT_EQ(-5, Call(test->entry(), 11));
  EXPECT_EQ(-1, Call(test->entry(), -1));
  EXPECT_EQ(-1, Call(test->entry(), -11));
}

ASSEMBLER_TEST_GENERATE(OrImmediate2, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ ori(A0, A0, 6);
  __ ret();
}
ASSEMBLER_TEST_RUN(OrImmediate2, test) {
  EXPECT_DISASSEMBLY(
      "00656513 ori a0, a0, 6\n"
      "00008067 ret\n");
  EXPECT_EQ(6, Call(test->entry(), 0));
  EXPECT_EQ(7, Call(test->entry(), 1));
  EXPECT_EQ(15, Call(test->entry(), 11));
  EXPECT_EQ(-1, Call(test->entry(), -1));
  EXPECT_EQ(-9, Call(test->entry(), -11));
}

ASSEMBLER_TEST_GENERATE(AndImmediate1, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ andi(A0, A0, -6);
  __ ret();
}
ASSEMBLER_TEST_RUN(AndImmediate1, test) {
  EXPECT_DISASSEMBLY(
      "ffa57513 andi a0, a0, -6\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(0, Call(test->entry(), 1));
  EXPECT_EQ(10, Call(test->entry(), 11));
  EXPECT_EQ(-6, Call(test->entry(), -1));
  EXPECT_EQ(-16, Call(test->entry(), -11));
}

ASSEMBLER_TEST_GENERATE(AndImmediate2, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ andi(A0, A0, 6);
  __ ret();
}
ASSEMBLER_TEST_RUN(AndImmediate2, test) {
  EXPECT_DISASSEMBLY(
      "00657513 andi a0, a0, 6\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(0, Call(test->entry(), 1));
  EXPECT_EQ(2, Call(test->entry(), 11));
  EXPECT_EQ(6, Call(test->entry(), -1));
  EXPECT_EQ(4, Call(test->entry(), -11));
}

ASSEMBLER_TEST_GENERATE(ShiftLeftLogicalImmediate, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ slli(A0, A0, 2);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftLeftLogicalImmediate, test) {
  EXPECT_DISASSEMBLY(
      "00251513 slli a0, a0, 0x2\n"
      "00008067 ret\n");
  EXPECT_EQ(84, Call(test->entry(), 21));
  EXPECT_EQ(4, Call(test->entry(), 1));
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(-4, Call(test->entry(), -1));
  EXPECT_EQ(-84, Call(test->entry(), -21));
}

ASSEMBLER_TEST_GENERATE(ShiftLeftLogicalImmediate2, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ slli(A0, A0, XLEN - 1);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftLeftLogicalImmediate2, test) {
#if XLEN == 32
  EXPECT_DISASSEMBLY(
      "01f51513 slli a0, a0, 0x1f\n"
      "00008067 ret\n");
#elif XLEN == 64
  EXPECT_DISASSEMBLY(
      "03f51513 slli a0, a0, 0x3f\n"
      "00008067 ret\n");
#endif
  EXPECT_EQ(0, Call(test->entry(), 2));
  EXPECT_EQ(kMinIntX, Call(test->entry(), 1));
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(kMinIntX, Call(test->entry(), -1));
  EXPECT_EQ(0, Call(test->entry(), -2));
}

ASSEMBLER_TEST_GENERATE(ShiftRightLogicalImmediate, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ srli(A0, A0, 2);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftRightLogicalImmediate, test) {
  EXPECT_DISASSEMBLY(
      "00255513 srli a0, a0, 0x2\n"
      "00008067 ret\n");
  EXPECT_EQ(5, Call(test->entry(), 21));
  EXPECT_EQ(0, Call(test->entry(), 1));
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(static_cast<intx_t>(static_cast<uintx_t>(-1) >> 2),
            Call(test->entry(), -1));
  EXPECT_EQ(static_cast<intx_t>(static_cast<uintx_t>(-21) >> 2),
            Call(test->entry(), -21));
}

ASSEMBLER_TEST_GENERATE(ShiftRightLogicalImmediate2, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ srli(A0, A0, XLEN - 1);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftRightLogicalImmediate2, test) {
#if XLEN == 32
  EXPECT_DISASSEMBLY(
      "01f55513 srli a0, a0, 0x1f\n"
      "00008067 ret\n");
#elif XLEN == 64
  EXPECT_DISASSEMBLY(
      "03f55513 srli a0, a0, 0x3f\n"
      "00008067 ret\n");
#endif
  EXPECT_EQ(0, Call(test->entry(), 21));
  EXPECT_EQ(0, Call(test->entry(), 1));
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(1, Call(test->entry(), -1));
  EXPECT_EQ(1, Call(test->entry(), -21));
}

ASSEMBLER_TEST_GENERATE(ShiftRightArithmeticImmediate, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ srai(A0, A0, 2);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftRightArithmeticImmediate, test) {
  EXPECT_DISASSEMBLY(
      "40255513 srai a0, a0, 0x2\n"
      "00008067 ret\n");
  EXPECT_EQ(5, Call(test->entry(), 21));
  EXPECT_EQ(0, Call(test->entry(), 1));
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(-1, Call(test->entry(), -1));
  EXPECT_EQ(-6, Call(test->entry(), -21));
}

ASSEMBLER_TEST_GENERATE(ShiftRightArithmeticImmediate2, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ srai(A0, A0, XLEN - 1);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftRightArithmeticImmediate2, test) {
#if XLEN == 32
  EXPECT_DISASSEMBLY(
      "41f55513 srai a0, a0, 0x1f\n"  // CHECK
      "00008067 ret\n");
#elif XLEN == 64
  EXPECT_DISASSEMBLY(
      "43f55513 srai a0, a0, 0x3f\n"  // CHECK
      "00008067 ret\n");
#endif
  EXPECT_EQ(0, Call(test->entry(), 21));
  EXPECT_EQ(0, Call(test->entry(), 1));
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(-1, Call(test->entry(), -1));
  EXPECT_EQ(-1, Call(test->entry(), -21));
}

ASSEMBLER_TEST_GENERATE(Add, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ add(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Add, test) {
  EXPECT_DISASSEMBLY(
      "00b50533 add a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(24, Call(test->entry(), 7, 17));
  EXPECT_EQ(-10, Call(test->entry(), 7, -17));
  EXPECT_EQ(10, Call(test->entry(), -7, 17));
  EXPECT_EQ(-24, Call(test->entry(), -7, -17));
  EXPECT_EQ(24, Call(test->entry(), 17, 7));
  EXPECT_EQ(10, Call(test->entry(), 17, -7));
  EXPECT_EQ(-10, Call(test->entry(), -17, 7));
  EXPECT_EQ(-24, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(Subtract, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sub(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Subtract, test) {
  EXPECT_DISASSEMBLY(
      "40b50533 sub a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(-10, Call(test->entry(), 7, 17));
  EXPECT_EQ(24, Call(test->entry(), 7, -17));
  EXPECT_EQ(-24, Call(test->entry(), -7, 17));
  EXPECT_EQ(10, Call(test->entry(), -7, -17));
  EXPECT_EQ(10, Call(test->entry(), 17, 7));
  EXPECT_EQ(24, Call(test->entry(), 17, -7));
  EXPECT_EQ(-24, Call(test->entry(), -17, 7));
  EXPECT_EQ(-10, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(ShiftLeftLogical, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sll(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftLeftLogical, test) {
  EXPECT_DISASSEMBLY(
      "00b51533 sll a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(2176, Call(test->entry(), 17, 7));
  EXPECT_EQ(-2176, Call(test->entry(), -17, 7));
  EXPECT_EQ(34, Call(test->entry(), 17, 1));
  EXPECT_EQ(-34, Call(test->entry(), -17, 1));
  EXPECT_EQ(17, Call(test->entry(), 17, 0));
  EXPECT_EQ(-17, Call(test->entry(), -17, 0));
}

ASSEMBLER_TEST_GENERATE(SetLessThan, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ slt(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SetLessThan, test) {
  EXPECT_DISASSEMBLY(
      "00b52533 slt a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 7, 7));
  EXPECT_EQ(0, Call(test->entry(), -7, -7));
  EXPECT_EQ(1, Call(test->entry(), 7, 17));
  EXPECT_EQ(0, Call(test->entry(), 7, -17));
  EXPECT_EQ(1, Call(test->entry(), -7, 17));
  EXPECT_EQ(0, Call(test->entry(), -7, -17));
  EXPECT_EQ(0, Call(test->entry(), 17, 7));
  EXPECT_EQ(0, Call(test->entry(), 17, -7));
  EXPECT_EQ(1, Call(test->entry(), -17, 7));
  EXPECT_EQ(1, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(SetLessThanUnsigned, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sltu(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SetLessThanUnsigned, test) {
  EXPECT_DISASSEMBLY(
      "00b53533 sltu a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 7, 7));
  EXPECT_EQ(0, Call(test->entry(), -7, -7));
  EXPECT_EQ(1, Call(test->entry(), 7, 17));
  EXPECT_EQ(1, Call(test->entry(), 7, -17));
  EXPECT_EQ(0, Call(test->entry(), -7, 17));
  EXPECT_EQ(0, Call(test->entry(), -7, -17));
  EXPECT_EQ(0, Call(test->entry(), 17, 7));
  EXPECT_EQ(1, Call(test->entry(), 17, -7));
  EXPECT_EQ(0, Call(test->entry(), -17, 7));
  EXPECT_EQ(1, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(Xor, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ xor_(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Xor, test) {
  EXPECT_DISASSEMBLY(
      "00b54533 xor a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(22, Call(test->entry(), 7, 17));
  EXPECT_EQ(-24, Call(test->entry(), 7, -17));
  EXPECT_EQ(-24, Call(test->entry(), -7, 17));
  EXPECT_EQ(22, Call(test->entry(), -7, -17));
  EXPECT_EQ(22, Call(test->entry(), 17, 7));
  EXPECT_EQ(-24, Call(test->entry(), 17, -7));
  EXPECT_EQ(-24, Call(test->entry(), -17, 7));
  EXPECT_EQ(22, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(ShiftRightLogical, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ srl(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftRightLogical, test) {
  EXPECT_DISASSEMBLY(
      "00b55533 srl a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 17, 7));
  EXPECT_EQ(static_cast<intx_t>(static_cast<uintx_t>(-17) >> 7),
            Call(test->entry(), -17, 7));
  EXPECT_EQ(8, Call(test->entry(), 17, 1));
  EXPECT_EQ(static_cast<intx_t>(static_cast<uintx_t>(-17) >> 1),
            Call(test->entry(), -17, 1));
  EXPECT_EQ(17, Call(test->entry(), 17, 0));
  EXPECT_EQ(-17, Call(test->entry(), -17, 0));
}

ASSEMBLER_TEST_GENERATE(ShiftRightArithmetic, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sra(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftRightArithmetic, test) {
  EXPECT_DISASSEMBLY(
      "40b55533 sra a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 17, 7));
  EXPECT_EQ(-1, Call(test->entry(), -17, 7));
  EXPECT_EQ(8, Call(test->entry(), 17, 1));
  EXPECT_EQ(-9, Call(test->entry(), -17, 1));
  EXPECT_EQ(17, Call(test->entry(), 17, 0));
  EXPECT_EQ(-17, Call(test->entry(), -17, 0));
}

ASSEMBLER_TEST_GENERATE(Or, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ or_(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Or, test) {
  EXPECT_DISASSEMBLY(
      "00b56533 or a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(23, Call(test->entry(), 7, 17));
  EXPECT_EQ(-17, Call(test->entry(), 7, -17));
  EXPECT_EQ(-7, Call(test->entry(), -7, 17));
  EXPECT_EQ(-1, Call(test->entry(), -7, -17));
  EXPECT_EQ(23, Call(test->entry(), 17, 7));
  EXPECT_EQ(-7, Call(test->entry(), 17, -7));
  EXPECT_EQ(-17, Call(test->entry(), -17, 7));
  EXPECT_EQ(-1, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(And, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ and_(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(And, test) {
  EXPECT_DISASSEMBLY(
      "00b57533 and a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(1, Call(test->entry(), 7, 17));
  EXPECT_EQ(7, Call(test->entry(), 7, -17));
  EXPECT_EQ(17, Call(test->entry(), -7, 17));
  EXPECT_EQ(-23, Call(test->entry(), -7, -17));
  EXPECT_EQ(1, Call(test->entry(), 17, 7));
  EXPECT_EQ(17, Call(test->entry(), 17, -7));
  EXPECT_EQ(7, Call(test->entry(), -17, 7));
  EXPECT_EQ(-23, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(Fence, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fence();
  __ fence(kRead, kWrite);
  __ fence(kInput, kOutput);
  __ fence(kMemory, kMemory);
  __ fence(kAll, kAll);
  __ ret();
}
ASSEMBLER_TEST_RUN(Fence, test) {
  EXPECT_DISASSEMBLY(
      "0ff0000f fence\n"
      "0210000f fence r,w\n"
      "0840000f fence i,o\n"
      "0330000f fence rw,rw\n"
      "0ff0000f fence\n"
      "00008067 ret\n");
  Call(test->entry());
}

ASSEMBLER_TEST_GENERATE(InstructionFence, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fencei();
  __ ret();
}
ASSEMBLER_TEST_RUN(InstructionFence, test) {
  EXPECT_DISASSEMBLY(
      "0000100f fence.i\n"
      "00008067 ret\n");
  Call(test->entry());
}

ASSEMBLER_TEST_GENERATE(EnvironmentCall, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ ecall();
  __ ret();
}
ASSEMBLER_TEST_RUN(EnvironmentCall, test) {
  EXPECT_DISASSEMBLY(
      "00000073 ecall\n"
      "00008067 ret\n");

  // Not running: would trap.
}

ASSEMBLER_TEST_GENERATE(EnvironmentBreak, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ ebreak();
  __ ret();
}
ASSEMBLER_TEST_RUN(EnvironmentBreak, test) {
  EXPECT_DISASSEMBLY(
      "00100073 ebreak\n"
      "00008067 ret\n");

  // Not running: would trap.
}

ASSEMBLER_TEST_GENERATE(ControlStatusRegisters, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ csrrw(T0, 0x123, S1);
  __ csrrs(T1, 0x123, S2);
  __ csrrc(T2, 0x123, S3);
  __ csrr(T3, 0x123);
  __ csrw(0x123, S4);
  __ csrs(0x123, S5);
  __ csrc(0x123, S6);
  __ csrrwi(T1, 0x123, 1);
  __ csrrsi(T2, 0x123, 2);
  __ csrrci(T3, 0x123, 3);
  __ csrwi(0x123, 4);
  __ csrsi(0x123, 5);
  __ csrci(0x123, 6);
  __ ret();
}
ASSEMBLER_TEST_RUN(ControlStatusRegisters, test) {
  EXPECT_DISASSEMBLY(
      "123492f3 csrrw t0, 0x123, thr\n"
      "12392373 csrrs t1, 0x123, s2\n"
      "1239b3f3 csrrc t2, 0x123, s3\n"
      "12302e73 csrr t3, 0x123\n"
      "123a1073 csrw 0x123, s4\n"
      "123aa073 csrs 0x123, s5\n"
      "123b3073 csrc 0x123, s6\n"
      "1230d373 csrrwi t1, 0x123, 1\n"
      "123163f3 csrrsi t2, 0x123, 2\n"
      "1231fe73 csrrci t3, 0x123, 3\n"
      "12325073 csrwi 0x123, 4\n"
      "1232e073 csrsi 0x123, 5\n"
      "12337073 csrci 0x123, 6\n"
      "00008067 ret\n");

  // Not running: would trap.
}

ASSEMBLER_TEST_GENERATE(Nop, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ nop();
  __ ret();
}
ASSEMBLER_TEST_RUN(Nop, test) {
  EXPECT_DISASSEMBLY(
      "00000013 nop\n"
      "00008067 ret\n");
  EXPECT_EQ(123, Call(test->entry(), 123));
}

ASSEMBLER_TEST_GENERATE(Move, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ mv(A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Move, test) {
  EXPECT_DISASSEMBLY(
      "00058513 mv a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(36, Call(test->entry(), 42, 36));
}

ASSEMBLER_TEST_GENERATE(Not, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ not_(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(Not, test) {
  EXPECT_DISASSEMBLY(
      "fff54513 not a0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(~42, Call(test->entry(), 42));
  EXPECT_EQ(~-42, Call(test->entry(), -42));
}

ASSEMBLER_TEST_GENERATE(Negate, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ neg(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(Negate, test) {
  EXPECT_DISASSEMBLY(
      "40a00533 neg a0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(-42, Call(test->entry(), 42));
  EXPECT_EQ(42, Call(test->entry(), -42));
}

ASSEMBLER_TEST_GENERATE(SetNotEqualToZero, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ snez(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SetNotEqualToZero, test) {
  EXPECT_DISASSEMBLY(
      "00a03533 snez a0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(1, Call(test->entry(), -42));
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(1, Call(test->entry(), 42));
}

ASSEMBLER_TEST_GENERATE(SetEqualToZero, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ seqz(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SetEqualToZero, test) {
  EXPECT_DISASSEMBLY(
      "00153513 seqz a0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), -42));
  EXPECT_EQ(1, Call(test->entry(), 0));
  EXPECT_EQ(0, Call(test->entry(), 42));
}

ASSEMBLER_TEST_GENERATE(SetLessThanZero, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sltz(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SetLessThanZero, test) {
  EXPECT_DISASSEMBLY(
      "00052533 sltz a0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(1, Call(test->entry(), -42));
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(0, Call(test->entry(), 42));
}

ASSEMBLER_TEST_GENERATE(SetGreaterThanZero, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sgtz(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SetGreaterThanZero, test) {
  EXPECT_DISASSEMBLY(
      "00a02533 sgtz a0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), -42));
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(1, Call(test->entry(), 42));
}

ASSEMBLER_TEST_GENERATE(BranchEqualZero, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  Label label;
  __ beqz(A0, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchEqualZero, test) {
  EXPECT_DISASSEMBLY(
      "00050663 beqz a0, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(3, Call(test->entry(), -42));
  EXPECT_EQ(4, Call(test->entry(), 0));
  EXPECT_EQ(3, Call(test->entry(), 42));
}

ASSEMBLER_TEST_GENERATE(BranchNotEqualZero, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  Label label;
  __ bnez(A0, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchNotEqualZero, test) {
  EXPECT_DISASSEMBLY(
      "00051663 bnez a0, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(4, Call(test->entry(), -42));
  EXPECT_EQ(3, Call(test->entry(), 0));
  EXPECT_EQ(4, Call(test->entry(), 42));
}

ASSEMBLER_TEST_GENERATE(BranchLessOrEqualZero, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  Label label;
  __ blez(A0, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchLessOrEqualZero, test) {
  EXPECT_DISASSEMBLY(
      "00a05663 blez a0, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(4, Call(test->entry(), -42));
  EXPECT_EQ(4, Call(test->entry(), 0));
  EXPECT_EQ(3, Call(test->entry(), 42));
}

ASSEMBLER_TEST_GENERATE(BranchGreaterOrEqualZero, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  Label label;
  __ bgez(A0, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchGreaterOrEqualZero, test) {
  EXPECT_DISASSEMBLY(
      "00055663 bgez a0, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(3, Call(test->entry(), -42));
  EXPECT_EQ(4, Call(test->entry(), 0));
  EXPECT_EQ(4, Call(test->entry(), 42));
}

ASSEMBLER_TEST_GENERATE(BranchLessThanZero, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  Label label;
  __ bltz(A0, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchLessThanZero, test) {
  EXPECT_DISASSEMBLY(
      "00054663 bltz a0, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(4, Call(test->entry(), -42));
  EXPECT_EQ(3, Call(test->entry(), 0));
  EXPECT_EQ(3, Call(test->entry(), 42));
}

ASSEMBLER_TEST_GENERATE(BranchGreaterThanZero, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  Label label;
  __ bgtz(A0, &label);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(BranchGreaterThanZero, test) {
  EXPECT_DISASSEMBLY(
      "00a04663 bgtz a0, +12\n"
      "00300513 li a0, 3\n"
      "00008067 ret\n"
      "00400513 li a0, 4\n"
      "00008067 ret\n");
  EXPECT_EQ(3, Call(test->entry(), -42));
  EXPECT_EQ(3, Call(test->entry(), 0));
  EXPECT_EQ(4, Call(test->entry(), 42));
}

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(AddImmediateWord1, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ addiw(A0, A0, 42);
  __ ret();
}
ASSEMBLER_TEST_RUN(AddImmediateWord1, test) {
  EXPECT_DISASSEMBLY(
      "02a5051b addiw a0, a0, 42\n"
      "00008067 ret\n");
  EXPECT_EQ(42, Call(test->entry(), 0));
  EXPECT_EQ(40, Call(test->entry(), -2));
  EXPECT_EQ(0, Call(test->entry(), -42));
}

ASSEMBLER_TEST_GENERATE(AddImmediateWord2, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ addiw(A0, A0, -42);
  __ ret();
}
ASSEMBLER_TEST_RUN(AddImmediateWord2, test) {
  EXPECT_DISASSEMBLY(
      "fd65051b addiw a0, a0, -42\n"
      "00008067 ret\n");
  EXPECT_EQ(-42, Call(test->entry(), 0));
  EXPECT_EQ(-44, Call(test->entry(), -2));
  EXPECT_EQ(38, Call(test->entry(), 80));
}

ASSEMBLER_TEST_GENERATE(ShiftLeftLogicalImmediateWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ slliw(A0, A0, 2);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftLeftLogicalImmediateWord, test) {
  EXPECT_DISASSEMBLY(
      "0025151b slliw a0, a0, 0x2\n"
      "00008067 ret\n");
  EXPECT_EQ(84, Call(test->entry(), 21));
  EXPECT_EQ(4, Call(test->entry(), 1));
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(-4, Call(test->entry(), -1));
  EXPECT_EQ(-84, Call(test->entry(), -21));
}

ASSEMBLER_TEST_GENERATE(ShiftRightLogicalImmediateWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ srliw(A0, A0, 2);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftRightLogicalImmediateWord, test) {
  EXPECT_DISASSEMBLY(
      "0025551b srliw a0, a0, 0x2\n"
      "00008067 ret\n");
  EXPECT_EQ(5, Call(test->entry(), 21));
  EXPECT_EQ(0, Call(test->entry(), 1));
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(sign_extend(static_cast<uint32_t>(-1) >> 2),
            Call(test->entry(), -1));
  EXPECT_EQ(sign_extend(static_cast<uint32_t>(-21) >> 2),
            Call(test->entry(), -21));
}

ASSEMBLER_TEST_GENERATE(ShiftRightArithmeticImmediateWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sraiw(A0, A0, 2);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftRightArithmeticImmediateWord, test) {
  EXPECT_DISASSEMBLY(
      "4025551b sraiw a0, a0, 0x2\n"
      "00008067 ret\n");
  EXPECT_EQ(5, Call(test->entry(), 21));
  EXPECT_EQ(0, Call(test->entry(), 1));
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(-1, Call(test->entry(), -1));
  EXPECT_EQ(-6, Call(test->entry(), -21));
}

ASSEMBLER_TEST_GENERATE(AddWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ addw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(AddWord, test) {
  EXPECT_DISASSEMBLY(
      "00b5053b addw a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(24, Call(test->entry(), 7, 17));
  EXPECT_EQ(-10, Call(test->entry(), 7, -17));
  EXPECT_EQ(10, Call(test->entry(), -7, 17));
  EXPECT_EQ(-24, Call(test->entry(), -7, -17));
  EXPECT_EQ(24, Call(test->entry(), 17, 7));
  EXPECT_EQ(10, Call(test->entry(), 17, -7));
  EXPECT_EQ(-10, Call(test->entry(), -17, 7));
  EXPECT_EQ(-24, Call(test->entry(), -17, -7));
  EXPECT_EQ(3, Call(test->entry(), 0x200000002, 0x100000001));
}

ASSEMBLER_TEST_GENERATE(SubtractWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ subw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SubtractWord, test) {
  EXPECT_DISASSEMBLY(
      "40b5053b subw a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(-10, Call(test->entry(), 7, 17));
  EXPECT_EQ(24, Call(test->entry(), 7, -17));
  EXPECT_EQ(-24, Call(test->entry(), -7, 17));
  EXPECT_EQ(10, Call(test->entry(), -7, -17));
  EXPECT_EQ(10, Call(test->entry(), 17, 7));
  EXPECT_EQ(24, Call(test->entry(), 17, -7));
  EXPECT_EQ(-24, Call(test->entry(), -17, 7));
  EXPECT_EQ(-10, Call(test->entry(), -17, -7));
  EXPECT_EQ(1, Call(test->entry(), 0x200000002, 0x100000001));
}

ASSEMBLER_TEST_GENERATE(ShiftLeftLogicalWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sllw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftLeftLogicalWord, test) {
  EXPECT_DISASSEMBLY(
      "00b5153b sllw a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(2176, Call(test->entry(), 17, 7));
  EXPECT_EQ(-2176, Call(test->entry(), -17, 7));
  EXPECT_EQ(34, Call(test->entry(), 17, 1));
  EXPECT_EQ(-34, Call(test->entry(), -17, 1));
  EXPECT_EQ(17, Call(test->entry(), 17, 0));
  EXPECT_EQ(-17, Call(test->entry(), -17, 0));
  EXPECT_EQ(0x10, Call(test->entry(), 0x10000001, 4));
}

ASSEMBLER_TEST_GENERATE(ShiftRightLogicalWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ srlw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftRightLogicalWord, test) {
  EXPECT_DISASSEMBLY(
      "00b5553b srlw a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 17, 7));
  EXPECT_EQ(sign_extend(static_cast<uint32_t>(-17) >> 7),
            Call(test->entry(), -17, 7));
  EXPECT_EQ(8, Call(test->entry(), 17, 1));
  EXPECT_EQ(sign_extend(static_cast<uint32_t>(-17) >> 1),
            Call(test->entry(), -17, 1));
  EXPECT_EQ(17, Call(test->entry(), 17, 0));
  EXPECT_EQ(-17, Call(test->entry(), -17, 0));
}

ASSEMBLER_TEST_GENERATE(ShiftRightArithmeticWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sraw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftRightArithmeticWord, test) {
  EXPECT_DISASSEMBLY(
      "40b5553b sraw a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 17, 7));
  EXPECT_EQ(-1, Call(test->entry(), -17, 7));
  EXPECT_EQ(8, Call(test->entry(), 17, 1));
  EXPECT_EQ(-9, Call(test->entry(), -17, 1));
  EXPECT_EQ(17, Call(test->entry(), 17, 0));
  EXPECT_EQ(-17, Call(test->entry(), -17, 0));
}

ASSEMBLER_TEST_GENERATE(NegateWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ negw(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(NegateWord, test) {
  EXPECT_DISASSEMBLY(
      "40a0053b negw a0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(-42, Call(test->entry(), 42));
  EXPECT_EQ(42, Call(test->entry(), -42));
  EXPECT_EQ(1, Call(test->entry(), 0x10FFFFFFFF));
}

ASSEMBLER_TEST_GENERATE(SignExtendWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ sextw(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SignExtendWord, test) {
  EXPECT_DISASSEMBLY(
      "0005051b sext.w a0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(42, Call(test->entry(), 42));
  EXPECT_EQ(-42, Call(test->entry(), -42));
  EXPECT_EQ(-1, Call(test->entry(), 0x10FFFFFFFF));
}
#endif  // XLEN >= 64

ASSEMBLER_TEST_GENERATE(Multiply, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ mul(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Multiply, test) {
  EXPECT_DISASSEMBLY(
      "02b50533 mul a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(68, Call(test->entry(), 4, 17));
  EXPECT_EQ(-68, Call(test->entry(), -4, 17));
  EXPECT_EQ(-68, Call(test->entry(), 4, -17));
  EXPECT_EQ(68, Call(test->entry(), -4, -17));
  EXPECT_EQ(68, Call(test->entry(), 17, 4));
  EXPECT_EQ(-68, Call(test->entry(), -17, 4));
  EXPECT_EQ(-68, Call(test->entry(), 17, -4));
  EXPECT_EQ(68, Call(test->entry(), -17, -4));
}

ASSEMBLER_TEST_GENERATE(MultiplyHigh, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ mulh(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(MultiplyHigh, test) {
  EXPECT_DISASSEMBLY(
      "02b51533 mulh a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 4, 17));
  EXPECT_EQ(-1, Call(test->entry(), -4, 17));
  EXPECT_EQ(-1, Call(test->entry(), 4, -17));
  EXPECT_EQ(0, Call(test->entry(), -4, -17));
  EXPECT_EQ(0, Call(test->entry(), 17, 4));
  EXPECT_EQ(-1, Call(test->entry(), -17, 4));
  EXPECT_EQ(-1, Call(test->entry(), 17, -4));
  EXPECT_EQ(0, Call(test->entry(), -17, -4));
}

ASSEMBLER_TEST_GENERATE(MultiplyHighSignedUnsigned, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ mulhsu(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(MultiplyHighSignedUnsigned, test) {
  EXPECT_DISASSEMBLY(
      "02b52533 mulhsu a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 4, 17));
  EXPECT_EQ(-1, Call(test->entry(), -4, 17));
  EXPECT_EQ(3, Call(test->entry(), 4, -17));
  EXPECT_EQ(-4, Call(test->entry(), -4, -17));
  EXPECT_EQ(0, Call(test->entry(), 17, 4));
  EXPECT_EQ(-1, Call(test->entry(), -17, 4));
  EXPECT_EQ(16, Call(test->entry(), 17, -4));
  EXPECT_EQ(-17, Call(test->entry(), -17, -4));
}

ASSEMBLER_TEST_GENERATE(MultiplyHighUnsigned, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ mulhu(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(MultiplyHighUnsigned, test) {
  EXPECT_DISASSEMBLY(
      "02b53533 mulhu a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 4, 17));
  EXPECT_EQ(16, Call(test->entry(), -4, 17));
  EXPECT_EQ(3, Call(test->entry(), 4, -17));
  EXPECT_EQ(-21, Call(test->entry(), -4, -17));
  EXPECT_EQ(0, Call(test->entry(), 17, 4));
  EXPECT_EQ(3, Call(test->entry(), -17, 4));
  EXPECT_EQ(16, Call(test->entry(), 17, -4));
  EXPECT_EQ(-21, Call(test->entry(), -17, -4));
}

ASSEMBLER_TEST_GENERATE(Divide, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ div(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Divide, test) {
  EXPECT_DISASSEMBLY(
      "02b54533 div a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 4, 17));
  EXPECT_EQ(0, Call(test->entry(), -4, 17));
  EXPECT_EQ(0, Call(test->entry(), 4, -17));
  EXPECT_EQ(0, Call(test->entry(), -4, -17));
  EXPECT_EQ(4, Call(test->entry(), 17, 4));
  EXPECT_EQ(-4, Call(test->entry(), -17, 4));
  EXPECT_EQ(-4, Call(test->entry(), 17, -4));
  EXPECT_EQ(4, Call(test->entry(), -17, -4));
}

ASSEMBLER_TEST_GENERATE(DivideUnsigned, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ divu(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DivideUnsigned, test) {
  EXPECT_DISASSEMBLY(
      "02b55533 divu a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 4, 17));
#if XLEN == 32
  EXPECT_EQ(252645134, Call(test->entry(), -4, 17));
#else
  EXPECT_EQ(1085102592571150094, Call(test->entry(), -4, 17));
#endif
  EXPECT_EQ(0, Call(test->entry(), 4, -17));
  EXPECT_EQ(1, Call(test->entry(), -4, -17));
  EXPECT_EQ(4, Call(test->entry(), 17, 4));
#if XLEN == 32
  EXPECT_EQ(1073741819, Call(test->entry(), -17, 4));
#else
  EXPECT_EQ(4611686018427387899, Call(test->entry(), -17, 4));
#endif
  EXPECT_EQ(0, Call(test->entry(), 17, -4));
  EXPECT_EQ(0, Call(test->entry(), -17, -4));
}

ASSEMBLER_TEST_GENERATE(Remainder, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ rem(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Remainder, test) {
  EXPECT_DISASSEMBLY(
      "02b56533 rem a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(4, Call(test->entry(), 4, 17));
  EXPECT_EQ(-4, Call(test->entry(), -4, 17));
  EXPECT_EQ(4, Call(test->entry(), 4, -17));
  EXPECT_EQ(-4, Call(test->entry(), -4, -17));
  EXPECT_EQ(1, Call(test->entry(), 17, 4));
  EXPECT_EQ(-1, Call(test->entry(), -17, 4));
  EXPECT_EQ(1, Call(test->entry(), 17, -4));
  EXPECT_EQ(-1, Call(test->entry(), -17, -4));
}

ASSEMBLER_TEST_GENERATE(RemainderUnsigned, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ remu(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(RemainderUnsigned, test) {
  EXPECT_DISASSEMBLY(
      "02b57533 remu a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(4, Call(test->entry(), 4, 17));
  EXPECT_EQ(14, Call(test->entry(), -4, 17));
  EXPECT_EQ(4, Call(test->entry(), 4, -17));
  EXPECT_EQ(13, Call(test->entry(), -4, -17));
  EXPECT_EQ(1, Call(test->entry(), 17, 4));
  EXPECT_EQ(3, Call(test->entry(), -17, 4));
  EXPECT_EQ(17, Call(test->entry(), 17, -4));
  EXPECT_EQ(-17, Call(test->entry(), -17, -4));
}

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(MultiplyWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ mulw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(MultiplyWord, test) {
  EXPECT_DISASSEMBLY(
      "02b5053b mulw a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(68, Call(test->entry(), 4, 17));
  EXPECT_EQ(-68, Call(test->entry(), -4, 17));
  EXPECT_EQ(-68, Call(test->entry(), 4, -17));
  EXPECT_EQ(68, Call(test->entry(), -4, -17));
  EXPECT_EQ(68, Call(test->entry(), 17, 4));
  EXPECT_EQ(-68, Call(test->entry(), -17, 4));
  EXPECT_EQ(-68, Call(test->entry(), 17, -4));
  EXPECT_EQ(68, Call(test->entry(), -17, -4));
}

ASSEMBLER_TEST_GENERATE(DivideWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ divw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DivideWord, test) {
  EXPECT_DISASSEMBLY(
      "02b5453b divw a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 4, 17));
  EXPECT_EQ(0, Call(test->entry(), -4, 17));
  EXPECT_EQ(0, Call(test->entry(), 4, -17));
  EXPECT_EQ(0, Call(test->entry(), -4, -17));
  EXPECT_EQ(4, Call(test->entry(), 17, 4));
  EXPECT_EQ(-4, Call(test->entry(), -17, 4));
  EXPECT_EQ(-4, Call(test->entry(), 17, -4));
  EXPECT_EQ(4, Call(test->entry(), -17, -4));
}

ASSEMBLER_TEST_GENERATE(DivideUnsignedWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ divuw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DivideUnsignedWord, test) {
  EXPECT_DISASSEMBLY(
      "02b5553b divuw a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 4, 17));
  EXPECT_EQ(252645134, Call(test->entry(), -4, 17));
  EXPECT_EQ(0, Call(test->entry(), 4, -17));
  EXPECT_EQ(1, Call(test->entry(), -4, -17));
  EXPECT_EQ(4, Call(test->entry(), 17, 4));
  EXPECT_EQ(1073741819, Call(test->entry(), -17, 4));
  EXPECT_EQ(0, Call(test->entry(), 17, -4));
  EXPECT_EQ(0, Call(test->entry(), -17, -4));
}

ASSEMBLER_TEST_GENERATE(RemainderWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ remw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(RemainderWord, test) {
  EXPECT_DISASSEMBLY(
      "02b5653b remw a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(4, Call(test->entry(), 4, 17));
  EXPECT_EQ(-4, Call(test->entry(), -4, 17));
  EXPECT_EQ(4, Call(test->entry(), 4, -17));
  EXPECT_EQ(-4, Call(test->entry(), -4, -17));
  EXPECT_EQ(1, Call(test->entry(), 17, 4));
  EXPECT_EQ(-1, Call(test->entry(), -17, 4));
  EXPECT_EQ(1, Call(test->entry(), 17, -4));
  EXPECT_EQ(-1, Call(test->entry(), -17, -4));
}

ASSEMBLER_TEST_GENERATE(RemainderUnsignedWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ remuw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(RemainderUnsignedWord, test) {
  EXPECT_DISASSEMBLY(
      "02b5753b remuw a0, a0, a1\n"
      "00008067 ret\n");
  EXPECT_EQ(4, Call(test->entry(), 4, 17));
  EXPECT_EQ(14, Call(test->entry(), -4, 17));
  EXPECT_EQ(4, Call(test->entry(), 4, -17));
  EXPECT_EQ(13, Call(test->entry(), -4, -17));
  EXPECT_EQ(1, Call(test->entry(), 17, 4));
  EXPECT_EQ(3, Call(test->entry(), -17, 4));
  EXPECT_EQ(17, Call(test->entry(), 17, -4));
  EXPECT_EQ(-17, Call(test->entry(), -17, -4));
}
#endif

ASSEMBLER_TEST_GENERATE(LoadReserveStoreConditionalWord_Success, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lrw(T0, Address(A0));
  __ addi(T0, T0, 1);
  __ scw(A0, T0, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadReserveStoreConditionalWord_Success, test) {
  EXPECT_DISASSEMBLY(
      "100522af lr.w t0, (a0)\n"
      "00128293 addi t0, t0, 1\n"
      "1855252f sc.w a0, t0, (a0)\n"
      "00008067 ret\n");

  int32_t* value = reinterpret_cast<int32_t*>(malloc(sizeof(int32_t)));
  *value = 0b1100;
  EXPECT_EQ(0, Call(test->entry(), reinterpret_cast<intx_t>(value)));
  EXPECT_EQ(0b1101, *value);
}

ASSEMBLER_TEST_GENERATE(LoadReserveStoreConditionalWord_Failure, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ li(T0, 42);
  __ scw(A0, T0, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadReserveStoreConditionalWord_Failure, test) {
  EXPECT_DISASSEMBLY(
      "02a00293 li t0, 42\n"
      "1855252f sc.w a0, t0, (a0)\n"
      "00008067 ret\n");

  int32_t* value = reinterpret_cast<int32_t*>(malloc(sizeof(int32_t)));
  *value = 0b1100;
  EXPECT_EQ(false, 0 == Call(test->entry(), reinterpret_cast<intx_t>(value)));
  EXPECT_EQ(0b1100, *value);
}

ASSEMBLER_TEST_GENERATE(AmoSwapWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amoswapw(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoSwapWord, test) {
  EXPECT_DISASSEMBLY(
      "08b5252f amoswap.w a0, a1, (a0)\n"
      "00008067 ret\n");

  int32_t* value = reinterpret_cast<int32_t*>(malloc(sizeof(int32_t)));
  *value = 0b1100;
  EXPECT_EQ(0b1100,
            Call(test->entry(), reinterpret_cast<intx_t>(value), 0b1010));
  EXPECT_EQ(0b1010, *value);
}

ASSEMBLER_TEST_GENERATE(AmoAddWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amoaddw(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoAddWord, test) {
  EXPECT_DISASSEMBLY(
      "00b5252f amoadd.w a0, a1, (a0)\n"
      "00008067 ret\n");

  int32_t* value = reinterpret_cast<int32_t*>(malloc(sizeof(int32_t)));
  *value = 42;
  EXPECT_EQ(42, Call(test->entry(), reinterpret_cast<intx_t>(value), 10));
  EXPECT_EQ(52, *value);
}

ASSEMBLER_TEST_GENERATE(AmoXorWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amoxorw(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoXorWord, test) {
  EXPECT_DISASSEMBLY(
      "20b5252f amoxor.w a0, a1, (a0)\n"
      "00008067 ret\n");

  int32_t* value = reinterpret_cast<int32_t*>(malloc(sizeof(int32_t)));
  *value = 0b1100;
  EXPECT_EQ(0b1100,
            Call(test->entry(), reinterpret_cast<intx_t>(value), 0b1010));
  EXPECT_EQ(0b0110, *value);
}

ASSEMBLER_TEST_GENERATE(AmoAndWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amoandw(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoAndWord, test) {
  EXPECT_DISASSEMBLY(
      "60b5252f amoand.w a0, a1, (a0)\n"
      "00008067 ret\n");

  int32_t* value = reinterpret_cast<int32_t*>(malloc(sizeof(int32_t)));
  *value = 0b1100;
  EXPECT_EQ(0b1100,
            Call(test->entry(), reinterpret_cast<intx_t>(value), 0b1010));
  EXPECT_EQ(0b1000, *value);
}

ASSEMBLER_TEST_GENERATE(AmoOrWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amoorw(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoOrWord, test) {
  EXPECT_DISASSEMBLY(
      "40b5252f amoor.w a0, a1, (a0)\n"
      "00008067 ret\n");

  int32_t* value = reinterpret_cast<int32_t*>(malloc(sizeof(int32_t)));
  *value = 0b1100;
  EXPECT_EQ(0b1100,
            Call(test->entry(), reinterpret_cast<intx_t>(value), 0b1010));
  EXPECT_EQ(0b1110, *value);
}

ASSEMBLER_TEST_GENERATE(AmoMinWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amominw(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoMinWord, test) {
  EXPECT_DISASSEMBLY(
      "80b5252f amomin.w a0, a1, (a0)\n"
      "00008067 ret\n");

  int32_t* value = reinterpret_cast<int32_t*>(malloc(sizeof(int32_t)));
  *value = -7;
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -4));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -7));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -11));
  EXPECT_EQ(-11, *value);
}

ASSEMBLER_TEST_GENERATE(AmoMaxWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amomaxw(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoMaxWord, test) {
  EXPECT_DISASSEMBLY(
      "a0b5252f amomax.w a0, a1, (a0)\n"
      "00008067 ret\n");

  int32_t* value = reinterpret_cast<int32_t*>(malloc(sizeof(int32_t)));
  *value = -7;
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -11));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -7));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -4));
  EXPECT_EQ(-4, *value);
}

ASSEMBLER_TEST_GENERATE(AmoMinUnsignedWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amominuw(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoMinUnsignedWord, test) {
  EXPECT_DISASSEMBLY(
      "c0b5252f amominu.w a0, a1, (a0)\n"
      "00008067 ret\n");

  int32_t* value = reinterpret_cast<int32_t*>(malloc(sizeof(int32_t)));
  *value = -7;
  EXPECT_EQ(sign_extend(static_cast<uint32_t>(-7)),
            Call(test->entry(), reinterpret_cast<intx_t>(value), -4));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(sign_extend(static_cast<uint32_t>(-7)),
            Call(test->entry(), reinterpret_cast<intx_t>(value), -7));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(sign_extend(static_cast<uint32_t>(-7)),
            Call(test->entry(), reinterpret_cast<intx_t>(value), -11));
  EXPECT_EQ(-11, *value);
}

ASSEMBLER_TEST_GENERATE(AmoMaxUnsignedWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amomaxuw(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoMaxUnsignedWord, test) {
  EXPECT_DISASSEMBLY(
      "e0b5252f amomaxu.w a0, a1, (a0)\n"
      "00008067 ret\n");

  int32_t* value = reinterpret_cast<int32_t*>(malloc(sizeof(int32_t)));
  *value = -7;
  EXPECT_EQ(sign_extend(static_cast<uint32_t>(-7)),
            Call(test->entry(), reinterpret_cast<intx_t>(value), -11));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(sign_extend(static_cast<uint32_t>(-7)),
            Call(test->entry(), reinterpret_cast<intx_t>(value), -7));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(sign_extend(static_cast<uint32_t>(-7)),
            Call(test->entry(), reinterpret_cast<intx_t>(value), -4));
  EXPECT_EQ(-4, *value);
}

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(LoadReserveStoreConditionalDoubleWord_Success,
                        assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ lrd(T0, Address(A0));
  __ addi(T0, T0, 1);
  __ scd(A0, T0, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadReserveStoreConditionalDoubleWord_Success, test) {
  EXPECT_DISASSEMBLY(
      "100532af lr.d t0, (a0)\n"
      "00128293 addi t0, t0, 1\n"
      "1855352f sc.d a0, t0, (a0)\n"
      "00008067 ret\n");

  int64_t* value = reinterpret_cast<int64_t*>(malloc(sizeof(int64_t)));
  *value = 0b1100;
  EXPECT_EQ(0, Call(test->entry(), reinterpret_cast<intx_t>(value)));
  EXPECT_EQ(0b1101, *value);
}

ASSEMBLER_TEST_GENERATE(LoadReserveStoreConditionalDoubleWord_Failure,
                        assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ li(T0, 42);
  __ scd(A0, T0, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadReserveStoreConditionalDoubleWord_Failure, test) {
  EXPECT_DISASSEMBLY(
      "02a00293 li t0, 42\n"
      "1855352f sc.d a0, t0, (a0)\n"
      "00008067 ret\n");

  int64_t* value = reinterpret_cast<int64_t*>(malloc(sizeof(int64_t)));
  *value = 0b1100;
  EXPECT_EQ(false, 0 == Call(test->entry(), reinterpret_cast<intx_t>(value)));
  EXPECT_EQ(0b1100, *value);
}

ASSEMBLER_TEST_GENERATE(AmoSwapDoubleWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amoswapd(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoSwapDoubleWord, test) {
  EXPECT_DISASSEMBLY(
      "08b5352f amoswap.d a0, a1, (a0)\n"
      "00008067 ret\n");

  int64_t* value = reinterpret_cast<int64_t*>(malloc(sizeof(int64_t)));
  *value = 0b1100;
  EXPECT_EQ(0b1100,
            Call(test->entry(), reinterpret_cast<intx_t>(value), 0b1010));
  EXPECT_EQ(0b1010, *value);
}

ASSEMBLER_TEST_GENERATE(AmoAddDoubleWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amoaddd(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoAddDoubleWord, test) {
  EXPECT_DISASSEMBLY(
      "00b5352f amoadd.d a0, a1, (a0)\n"
      "00008067 ret\n");

  int64_t* value = reinterpret_cast<int64_t*>(malloc(sizeof(int64_t)));
  *value = 42;
  EXPECT_EQ(42, Call(test->entry(), reinterpret_cast<intx_t>(value), 10));
  EXPECT_EQ(52, *value);
}

ASSEMBLER_TEST_GENERATE(AmoXorDoubleWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amoxord(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoXorDoubleWord, test) {
  EXPECT_DISASSEMBLY(
      "20b5352f amoxor.d a0, a1, (a0)\n"
      "00008067 ret\n");

  int64_t* value = reinterpret_cast<int64_t*>(malloc(sizeof(int64_t)));
  *value = 0b1100;
  EXPECT_EQ(0b1100,
            Call(test->entry(), reinterpret_cast<intx_t>(value), 0b1010));
  EXPECT_EQ(0b0110, *value);
}

ASSEMBLER_TEST_GENERATE(AmoAndDoubleWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amoandd(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoAndDoubleWord, test) {
  EXPECT_DISASSEMBLY(
      "60b5352f amoand.d a0, a1, (a0)\n"
      "00008067 ret\n");

  int64_t* value = reinterpret_cast<int64_t*>(malloc(sizeof(int64_t)));
  *value = 0b1100;
  EXPECT_EQ(0b1100,
            Call(test->entry(), reinterpret_cast<intx_t>(value), 0b1010));
  EXPECT_EQ(0b1000, *value);
}

ASSEMBLER_TEST_GENERATE(AmoOrDoubleWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amoord(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoOrDoubleWord, test) {
  EXPECT_DISASSEMBLY(
      "40b5352f amoor.d a0, a1, (a0)\n"
      "00008067 ret\n");

  int64_t* value = reinterpret_cast<int64_t*>(malloc(sizeof(int64_t)));
  *value = 0b1100;
  EXPECT_EQ(0b1100,
            Call(test->entry(), reinterpret_cast<intx_t>(value), 0b1010));
  EXPECT_EQ(0b1110, *value);
}

ASSEMBLER_TEST_GENERATE(AmoMinDoubleWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amomind(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoMinDoubleWord, test) {
  EXPECT_DISASSEMBLY(
      "80b5352f amomin.d a0, a1, (a0)\n"
      "00008067 ret\n");

  int64_t* value = reinterpret_cast<int64_t*>(malloc(sizeof(int64_t)));
  *value = -7;
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -4));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -7));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -11));
  EXPECT_EQ(-11, *value);
}

ASSEMBLER_TEST_GENERATE(AmoMaxDoubleWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amomaxd(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoMaxDoubleWord, test) {
  EXPECT_DISASSEMBLY(
      "a0b5352f amomax.d a0, a1, (a0)\n"
      "00008067 ret\n");

  int64_t* value = reinterpret_cast<int64_t*>(malloc(sizeof(int64_t)));
  *value = -7;
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -11));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -7));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -4));
  EXPECT_EQ(-4, *value);
}

ASSEMBLER_TEST_GENERATE(AmoMinUnsignedDoubleWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amominud(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoMinUnsignedDoubleWord, test) {
  EXPECT_DISASSEMBLY(
      "c0b5352f amominu.d a0, a1, (a0)\n"
      "00008067 ret\n");

  int64_t* value = reinterpret_cast<int64_t*>(malloc(sizeof(int64_t)));
  *value = -7;
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -4));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -7));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -11));
  EXPECT_EQ(-11, *value);
}

ASSEMBLER_TEST_GENERATE(AmoMaxUnsignedDoubleWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ amomaxud(A0, A1, Address(A0));
  __ ret();
}
ASSEMBLER_TEST_RUN(AmoMaxUnsignedDoubleWord, test) {
  EXPECT_DISASSEMBLY(
      "e0b5352f amomaxu.d a0, a1, (a0)\n"
      "00008067 ret\n");

  int64_t* value = reinterpret_cast<int64_t*>(malloc(sizeof(int64_t)));
  *value = -7;
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -11));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -7));
  EXPECT_EQ(-7, *value);
  EXPECT_EQ(-7, Call(test->entry(), reinterpret_cast<intx_t>(value), -4));
  EXPECT_EQ(-4, *value);
}
#endif

ASSEMBLER_TEST_GENERATE(LoadSingleFloat, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ flw(FA0, Address(A0, 1 * sizeof(float)));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadSingleFloat, test) {
  EXPECT_DISASSEMBLY(
      "00452507 flw fa0, 4(a0)\n"
      "00008067 ret\n");

  float* data = reinterpret_cast<float*>(malloc(3 * sizeof(float)));
  data[0] = 1.7f;
  data[1] = 2.8f;
  data[2] = 3.9f;
  EXPECT_EQ(data[1], CallF(test->entry(), reinterpret_cast<intx_t>(data)));
}

ASSEMBLER_TEST_GENERATE(StoreSingleFloat, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fsw(FA0, Address(A0, 1 * sizeof(float)));
  __ ret();
}
ASSEMBLER_TEST_RUN(StoreSingleFloat, test) {
  EXPECT_DISASSEMBLY(
      "00a52227 fsw fa0, 4(a0)\n"
      "00008067 ret\n");

  float* data = reinterpret_cast<float*>(malloc(3 * sizeof(float)));
  data[0] = 1.7f;
  data[1] = 2.8f;
  data[2] = 3.9f;
  CallF(test->entry(), reinterpret_cast<intx_t>(data), 4.2f);
  EXPECT_EQ(4.2f, data[1]);
}

ASSEMBLER_TEST_GENERATE(SingleMultiplyAdd, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmadds(FA0, FA0, FA1, FA2);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleMultiplyAdd, test) {
  EXPECT_DISASSEMBLY(
      "60b50543 fmadd.s fa0, fa0, fa1, fa2\n"
      "00008067 ret\n");
  EXPECT_EQ(22.0, CallF(test->entry(), 3.0, 5.0, 7.0));
  EXPECT_EQ(-8.0, CallF(test->entry(), -3.0, 5.0, 7.0));
  EXPECT_EQ(-8.0, CallF(test->entry(), 3.0, -5.0, 7.0));
  EXPECT_EQ(8.0, CallF(test->entry(), 3.0, 5.0, -7.0));

  EXPECT_EQ(26.0, CallF(test->entry(), 7.0, 3.0, 5.0));
  EXPECT_EQ(-16.0, CallF(test->entry(), -7.0, 3.0, 5.0));
  EXPECT_EQ(-16.0, CallF(test->entry(), 7.0, -3.0, 5.0));
  EXPECT_EQ(16.0, CallF(test->entry(), 7.0, 3.0, -5.0));
}

ASSEMBLER_TEST_GENERATE(SingleMultiplySubtract, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmsubs(FA0, FA0, FA1, FA2);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleMultiplySubtract, test) {
  EXPECT_DISASSEMBLY(
      "60b50547 fmsub.s fa0, fa0, fa1, fa2\n"
      "00008067 ret\n");
  EXPECT_EQ(8.0, CallF(test->entry(), 3.0, 5.0, 7.0));
  EXPECT_EQ(-22.0, CallF(test->entry(), -3.0, 5.0, 7.0));
  EXPECT_EQ(-22.0, CallF(test->entry(), 3.0, -5.0, 7.0));
  EXPECT_EQ(22.0, CallF(test->entry(), 3.0, 5.0, -7.0));

  EXPECT_EQ(16.0, CallF(test->entry(), 7.0, 3.0, 5.0));
  EXPECT_EQ(-26.0, CallF(test->entry(), -7.0, 3.0, 5.0));
  EXPECT_EQ(-26.0, CallF(test->entry(), 7.0, -3.0, 5.0));
  EXPECT_EQ(26.0, CallF(test->entry(), 7.0, 3.0, -5.0));
}

ASSEMBLER_TEST_GENERATE(SingleNegateMultiplySubtract, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fnmsubs(FA0, FA0, FA1, FA2);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleNegateMultiplySubtract, test) {
  EXPECT_DISASSEMBLY(
      "60b5054b fnmsub.s fa0, fa0, fa1, fa2\n"
      "00008067 ret\n");
  EXPECT_EQ(-8.0, CallF(test->entry(), 3.0, 5.0, 7.0));
  EXPECT_EQ(22.0, CallF(test->entry(), -3.0, 5.0, 7.0));
  EXPECT_EQ(22.0, CallF(test->entry(), 3.0, -5.0, 7.0));
  EXPECT_EQ(-22.0, CallF(test->entry(), 3.0, 5.0, -7.0));

  EXPECT_EQ(-16.0, CallF(test->entry(), 7.0, 3.0, 5.0));
  EXPECT_EQ(26.0, CallF(test->entry(), -7.0, 3.0, 5.0));
  EXPECT_EQ(26.0, CallF(test->entry(), 7.0, -3.0, 5.0));
  EXPECT_EQ(-26.0, CallF(test->entry(), 7.0, 3.0, -5.0));
}

ASSEMBLER_TEST_GENERATE(SingleNegateMultiplyAdd, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fnmadds(FA0, FA0, FA1, FA2);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleNegateMultiplyAdd, test) {
  EXPECT_DISASSEMBLY(
      "60b5054f fnmadd.s fa0, fa0, fa1, fa2\n"
      "00008067 ret\n");
  EXPECT_EQ(-22.0, CallF(test->entry(), 3.0, 5.0, 7.0));
  EXPECT_EQ(8.0, CallF(test->entry(), -3.0, 5.0, 7.0));
  EXPECT_EQ(8.0, CallF(test->entry(), 3.0, -5.0, 7.0));
  EXPECT_EQ(-8.0, CallF(test->entry(), 3.0, 5.0, -7.0));

  EXPECT_EQ(-26.0, CallF(test->entry(), 7.0, 3.0, 5.0));
  EXPECT_EQ(16.0, CallF(test->entry(), -7.0, 3.0, 5.0));
  EXPECT_EQ(16.0, CallF(test->entry(), 7.0, -3.0, 5.0));
  EXPECT_EQ(-16.0, CallF(test->entry(), 7.0, 3.0, -5.0));
}

ASSEMBLER_TEST_GENERATE(SingleAdd, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fadds(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleAdd, test) {
  EXPECT_DISASSEMBLY(
      "00b50553 fadd.s fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(8.0f, CallF(test->entry(), 3.0f, 5.0f));
  EXPECT_EQ(2.0f, CallF(test->entry(), -3.0f, 5.0f));
  EXPECT_EQ(-2.0f, CallF(test->entry(), 3.0f, -5.0f));
  EXPECT_EQ(-8.0f, CallF(test->entry(), -3.0f, -5.0f));

  EXPECT_EQ(10.0f, CallF(test->entry(), 7.0f, 3.0f));
  EXPECT_EQ(-4.0f, CallF(test->entry(), -7.0f, 3.0f));
  EXPECT_EQ(4.0f, CallF(test->entry(), 7.0f, -3.0f));
  EXPECT_EQ(-10.0f, CallF(test->entry(), -7.0f, -3.0f));
}

ASSEMBLER_TEST_GENERATE(SingleSubtract, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fsubs(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleSubtract, test) {
  EXPECT_DISASSEMBLY(
      "08b50553 fsub.s fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(-2.0f, CallF(test->entry(), 3.0f, 5.0f));
  EXPECT_EQ(-8.0f, CallF(test->entry(), -3.0f, 5.0f));
  EXPECT_EQ(8.0f, CallF(test->entry(), 3.0f, -5.0f));
  EXPECT_EQ(2.0f, CallF(test->entry(), -3.0f, -5.0f));

  EXPECT_EQ(4.0f, CallF(test->entry(), 7.0f, 3.0f));
  EXPECT_EQ(-10.0f, CallF(test->entry(), -7.0f, 3.0f));
  EXPECT_EQ(10.0f, CallF(test->entry(), 7.0f, -3.0f));
  EXPECT_EQ(-4.0f, CallF(test->entry(), -7.0f, -3.0f));
}

ASSEMBLER_TEST_GENERATE(SingleMultiply, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmuls(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleMultiply, test) {
  EXPECT_DISASSEMBLY(
      "10b50553 fmul.s fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(15.0f, CallF(test->entry(), 3.0f, 5.0f));
  EXPECT_EQ(-15.0f, CallF(test->entry(), -3.0f, 5.0f));
  EXPECT_EQ(-15.0f, CallF(test->entry(), 3.0f, -5.0f));
  EXPECT_EQ(15.0f, CallF(test->entry(), -3.0f, -5.0f));

  EXPECT_EQ(21.0f, CallF(test->entry(), 7.0f, 3.0f));
  EXPECT_EQ(-21.0f, CallF(test->entry(), -7.0f, 3.0f));
  EXPECT_EQ(-21.0f, CallF(test->entry(), 7.0f, -3.0f));
  EXPECT_EQ(21.0f, CallF(test->entry(), -7.0f, -3.0f));
}

ASSEMBLER_TEST_GENERATE(SingleDivide, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fdivs(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleDivide, test) {
  EXPECT_DISASSEMBLY(
      "18b50553 fdiv.s fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(2.0f, CallF(test->entry(), 10.0f, 5.0f));
  EXPECT_EQ(-2.0f, CallF(test->entry(), -10.0f, 5.0f));
  EXPECT_EQ(-2.0f, CallF(test->entry(), 10.0f, -5.0f));
  EXPECT_EQ(2.0f, CallF(test->entry(), -10.0f, -5.0f));
}

ASSEMBLER_TEST_GENERATE(SingleSquareRoot, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fsqrts(FA0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleSquareRoot, test) {
  EXPECT_DISASSEMBLY(
      "58050553 fsqrt.s fa0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(0.0f, CallF(test->entry(), 0.0f));
  EXPECT_EQ(1.0f, CallF(test->entry(), 1.0f));
  EXPECT_EQ(2.0f, CallF(test->entry(), 4.0f));
  EXPECT_EQ(3.0f, CallF(test->entry(), 9.0f));
}

ASSEMBLER_TEST_GENERATE(SingleSignInject, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fsgnjs(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleSignInject, test) {
  EXPECT_DISASSEMBLY(
      "20b50553 fsgnj.s fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, 5.0f));
  EXPECT_EQ(3.0f, CallF(test->entry(), -3.0f, 5.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), 3.0f, -5.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, -5.0f));
}

ASSEMBLER_TEST_GENERATE(SingleNegatedSignInject, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fsgnjns(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleNegatedSignInject, test) {
  EXPECT_DISASSEMBLY(
      "20b51553 fsgnjn.s fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(-3.0f, CallF(test->entry(), 3.0f, 5.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, 5.0f));
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, -5.0f));
  EXPECT_EQ(3.0f, CallF(test->entry(), -3.0f, -5.0f));
}

ASSEMBLER_TEST_GENERATE(SingleXorSignInject, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fsgnjxs(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleXorSignInject, test) {
  EXPECT_DISASSEMBLY(
      "20b52553 fsgnjx.s fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, 5.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, 5.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), 3.0f, -5.0f));
  EXPECT_EQ(3.0f, CallF(test->entry(), -3.0f, -5.0f));
}

ASSEMBLER_TEST_GENERATE(SingleMin, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmins(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleMin, test) {
  EXPECT_DISASSEMBLY(
      "28b50553 fmin.s fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(1.0f, CallF(test->entry(), 3.0f, 1.0f));
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, 3.0f));
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, 5.0f));
  EXPECT_EQ(-1.0f, CallF(test->entry(), 3.0f, -1.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), 3.0f, -3.0f));
  EXPECT_EQ(-5.0f, CallF(test->entry(), 3.0f, -5.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, 1.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, 3.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, 5.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, -1.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, -3.0f));
  EXPECT_EQ(-5.0f, CallF(test->entry(), -3.0f, -5.0f));

  EXPECT_EQ(bit_cast<uint32_t>(-0.0f),
            bit_cast<uint32_t>(CallF(test->entry(), 0.0f, -0.0f)));
  EXPECT_EQ(bit_cast<uint32_t>(-0.0f),
            bit_cast<uint32_t>(CallF(test->entry(), -0.0f, 0.0f)));

  float qNAN = std::numeric_limits<float>::quiet_NaN();
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, qNAN));
  EXPECT_EQ(3.0f, CallF(test->entry(), qNAN, 3.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, qNAN));
  EXPECT_EQ(-3.0f, CallF(test->entry(), qNAN, -3.0f));

  float sNAN = std::numeric_limits<float>::signaling_NaN();
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, sNAN));
  EXPECT_EQ(3.0f, CallF(test->entry(), sNAN, 3.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, sNAN));
  EXPECT_EQ(-3.0f, CallF(test->entry(), sNAN, -3.0f));

  EXPECT_EQ(bit_cast<uint32_t>(qNAN),
            bit_cast<uint32_t>(CallF(test->entry(), qNAN, qNAN)));
  EXPECT_EQ(bit_cast<uint32_t>(qNAN),
            bit_cast<uint32_t>(CallF(test->entry(), sNAN, sNAN)));
  EXPECT_EQ(bit_cast<uint32_t>(qNAN),
            bit_cast<uint32_t>(CallF(test->entry(), qNAN, sNAN)));
  EXPECT_EQ(bit_cast<uint32_t>(qNAN),
            bit_cast<uint32_t>(CallF(test->entry(), sNAN, qNAN)));
}

ASSEMBLER_TEST_GENERATE(SingleMax, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmaxs(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleMax, test) {
  EXPECT_DISASSEMBLY(
      "28b51553 fmax.s fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, 1.0f));
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, 3.0f));
  EXPECT_EQ(5.0f, CallF(test->entry(), 3.0f, 5.0f));
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, -1.0f));
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, -3.0f));
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, -5.0f));
  EXPECT_EQ(1.0f, CallF(test->entry(), -3.0f, 1.0f));
  EXPECT_EQ(3.0f, CallF(test->entry(), -3.0f, 3.0f));
  EXPECT_EQ(5.0f, CallF(test->entry(), -3.0f, 5.0f));
  EXPECT_EQ(-1.0f, CallF(test->entry(), -3.0f, -1.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, -3.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, -5.0f));

  EXPECT_EQ(bit_cast<uint32_t>(0.0f),
            bit_cast<uint32_t>(CallF(test->entry(), 0.0f, -0.0f)));
  EXPECT_EQ(bit_cast<uint32_t>(0.0f),
            bit_cast<uint32_t>(CallF(test->entry(), -0.0f, 0.0f)));

  float qNAN = std::numeric_limits<float>::quiet_NaN();
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, qNAN));
  EXPECT_EQ(3.0f, CallF(test->entry(), qNAN, 3.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, qNAN));
  EXPECT_EQ(-3.0f, CallF(test->entry(), qNAN, -3.0f));

  float sNAN = std::numeric_limits<float>::signaling_NaN();
  EXPECT_EQ(3.0f, CallF(test->entry(), 3.0f, sNAN));
  EXPECT_EQ(3.0f, CallF(test->entry(), sNAN, 3.0f));
  EXPECT_EQ(-3.0f, CallF(test->entry(), -3.0f, sNAN));
  EXPECT_EQ(-3.0f, CallF(test->entry(), sNAN, -3.0f));

  EXPECT_EQ(bit_cast<uint32_t>(qNAN),
            bit_cast<uint32_t>(CallF(test->entry(), qNAN, qNAN)));
  EXPECT_EQ(bit_cast<uint32_t>(qNAN),
            bit_cast<uint32_t>(CallF(test->entry(), sNAN, sNAN)));
  EXPECT_EQ(bit_cast<uint32_t>(qNAN),
            bit_cast<uint32_t>(CallF(test->entry(), qNAN, sNAN)));
  EXPECT_EQ(bit_cast<uint32_t>(qNAN),
            bit_cast<uint32_t>(CallF(test->entry(), sNAN, qNAN)));
}

ASSEMBLER_TEST_GENERATE(SingleEqual, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ feqs(A0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleEqual, test) {
  EXPECT_DISASSEMBLY(
      "a0b52553 feq.s a0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, 1.0f));
  EXPECT_EQ(1, CallI(test->entry(), 3.0f, 3.0f));
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, 5.0f));
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, -1.0f));
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, -3.0f));
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, -5.0f));
  EXPECT_EQ(0, CallI(test->entry(), -3.0f, 1.0f));
  EXPECT_EQ(0, CallI(test->entry(), -3.0f, 3.0f));
  EXPECT_EQ(0, CallI(test->entry(), -3.0f, 5.0f));
  EXPECT_EQ(0, CallI(test->entry(), -3.0f, -1.0f));
  EXPECT_EQ(1, CallI(test->entry(), -3.0f, -3.0f));
  EXPECT_EQ(0, CallI(test->entry(), -3.0f, -5.0f));

  float qNAN = std::numeric_limits<float>::quiet_NaN();
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, qNAN));
  EXPECT_EQ(0, CallI(test->entry(), qNAN, 3.0f));
  EXPECT_EQ(0, CallI(test->entry(), -3.0f, qNAN));
  EXPECT_EQ(0, CallI(test->entry(), qNAN, -3.0f));
}

ASSEMBLER_TEST_GENERATE(SingleLessThan, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ flts(A0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleLessThan, test) {
  EXPECT_DISASSEMBLY(
      "a0b51553 flt.s a0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, 1.0f));
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, 3.0f));
  EXPECT_EQ(1, CallI(test->entry(), 3.0f, 5.0f));
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, -1.0f));
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, -3.0f));
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, -5.0f));
  EXPECT_EQ(1, CallI(test->entry(), -3.0f, 1.0f));
  EXPECT_EQ(1, CallI(test->entry(), -3.0f, 3.0f));
  EXPECT_EQ(1, CallI(test->entry(), -3.0f, 5.0f));
  EXPECT_EQ(1, CallI(test->entry(), -3.0f, -1.0f));
  EXPECT_EQ(0, CallI(test->entry(), -3.0f, -3.0f));
  EXPECT_EQ(0, CallI(test->entry(), -3.0f, -5.0f));

  float qNAN = std::numeric_limits<float>::quiet_NaN();
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, qNAN));
  EXPECT_EQ(0, CallI(test->entry(), qNAN, 3.0f));
  EXPECT_EQ(0, CallI(test->entry(), -3.0f, qNAN));
  EXPECT_EQ(0, CallI(test->entry(), qNAN, -3.0f));
}

ASSEMBLER_TEST_GENERATE(SingleLessOrEqual, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fles(A0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleLessOrEqual, test) {
  EXPECT_DISASSEMBLY(
      "a0b50553 fle.s a0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, 1.0f));
  EXPECT_EQ(1, CallI(test->entry(), 3.0f, 3.0f));
  EXPECT_EQ(1, CallI(test->entry(), 3.0f, 5.0f));
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, -1.0f));
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, -3.0f));
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, -5.0f));
  EXPECT_EQ(1, CallI(test->entry(), -3.0f, 1.0f));
  EXPECT_EQ(1, CallI(test->entry(), -3.0f, 3.0f));
  EXPECT_EQ(1, CallI(test->entry(), -3.0f, 5.0f));
  EXPECT_EQ(1, CallI(test->entry(), -3.0f, -1.0f));
  EXPECT_EQ(1, CallI(test->entry(), -3.0f, -3.0f));
  EXPECT_EQ(0, CallI(test->entry(), -3.0f, -5.0f));

  float qNAN = std::numeric_limits<float>::quiet_NaN();
  EXPECT_EQ(0, CallI(test->entry(), 3.0f, qNAN));
  EXPECT_EQ(0, CallI(test->entry(), qNAN, 3.0f));
  EXPECT_EQ(0, CallI(test->entry(), -3.0f, qNAN));
  EXPECT_EQ(0, CallI(test->entry(), qNAN, -3.0f));
}

ASSEMBLER_TEST_GENERATE(SingleClassify, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fclasss(A0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleClassify, test) {
  EXPECT_DISASSEMBLY(
      "e0051553 fclass.s a0, fa0\n"
      "00008067 ret\n");
  // Neg infinity
  EXPECT_EQ(1 << 0,
            CallI(test->entry(), -std::numeric_limits<float>::infinity()));
  // Neg normal
  EXPECT_EQ(1 << 1, CallI(test->entry(), -1.0f));
  // Neg subnormal
  EXPECT_EQ(1 << 2,
            CallI(test->entry(), -std::numeric_limits<float>::min() / 2.0f));
  // Neg zero
  EXPECT_EQ(1 << 3, CallI(test->entry(), -0.0f));
  // Pos zero
  EXPECT_EQ(1 << 4, CallI(test->entry(), 0.0f));
  // Pos subnormal
  EXPECT_EQ(1 << 5,
            CallI(test->entry(), std::numeric_limits<float>::min() / 2.0f));
  // Pos normal
  EXPECT_EQ(1 << 6, CallI(test->entry(), 1.0f));
  // Pos infinity
  EXPECT_EQ(1 << 7,
            CallI(test->entry(), std::numeric_limits<float>::infinity()));
  // Signaling NaN
  EXPECT_EQ(1 << 8,
            CallI(test->entry(), std::numeric_limits<float>::signaling_NaN()));
  // Queit NaN
  EXPECT_EQ(1 << 9,
            CallI(test->entry(), std::numeric_limits<float>::quiet_NaN()));
}

ASSEMBLER_TEST_GENERATE(ConvertSingleToWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtws(A0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertSingleToWord, test) {
  EXPECT_DISASSEMBLY(
      "c0050553 fcvt.w.s a0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(-42, CallI(test->entry(), static_cast<float>(-42)));
  EXPECT_EQ(0, CallI(test->entry(), static_cast<float>(0)));
  EXPECT_EQ(42, CallI(test->entry(), static_cast<float>(42)));
  EXPECT_EQ(sign_extend(kMinInt32),
            CallI(test->entry(), static_cast<float>(kMinInt32)));
  EXPECT_EQ(sign_extend(kMaxInt32),
            CallI(test->entry(), static_cast<float>(kMaxInt32)));
  EXPECT_EQ(sign_extend(kMaxInt32),
            CallI(test->entry(), static_cast<float>(kMaxUint32)));
  EXPECT_EQ(sign_extend(kMinInt32),
            CallI(test->entry(), static_cast<float>(kMinInt64)));
  EXPECT_EQ(sign_extend(kMaxInt32),
            CallI(test->entry(), static_cast<float>(kMaxInt64)));
  EXPECT_EQ(sign_extend(kMaxInt32),
            CallI(test->entry(), static_cast<float>(kMaxUint64)));
  EXPECT_EQ(sign_extend(kMinInt32),
            CallI(test->entry(), -std::numeric_limits<float>::infinity()));
  EXPECT_EQ(sign_extend(kMaxInt32),
            CallI(test->entry(), std::numeric_limits<float>::infinity()));
  EXPECT_EQ(sign_extend(kMaxInt32),
            CallI(test->entry(), std::numeric_limits<float>::signaling_NaN()));
}

ASSEMBLER_TEST_GENERATE(ConvertSingleToWord_RNE, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtws(A0, FA0, RNE);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertSingleToWord_RNE, test) {
  EXPECT_DISASSEMBLY(
      "c0050553 fcvt.w.s a0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(-44, CallI(test->entry(), -43.6f));
  EXPECT_EQ(-44, CallI(test->entry(), -43.5f));
  EXPECT_EQ(-43, CallI(test->entry(), -43.4f));
  EXPECT_EQ(-43, CallI(test->entry(), -43.0f));
  EXPECT_EQ(-43, CallI(test->entry(), -42.6f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.5f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.4f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.0f));
  EXPECT_EQ(0, CallI(test->entry(), -0.0f));
  EXPECT_EQ(0, CallI(test->entry(), +0.0f));
  EXPECT_EQ(42, CallI(test->entry(), 42.0f));
  EXPECT_EQ(42, CallI(test->entry(), 42.4f));
  EXPECT_EQ(42, CallI(test->entry(), 42.5f));
  EXPECT_EQ(43, CallI(test->entry(), 42.6f));
  EXPECT_EQ(43, CallI(test->entry(), 43.0f));
  EXPECT_EQ(43, CallI(test->entry(), 43.4f));
  EXPECT_EQ(44, CallI(test->entry(), 43.5f));
  EXPECT_EQ(44, CallI(test->entry(), 43.6f));
}

ASSEMBLER_TEST_GENERATE(ConvertSingleToWord_RTZ, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtws(A0, FA0, RTZ);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertSingleToWord_RTZ, test) {
  EXPECT_DISASSEMBLY(
      "c0051553 fcvt.w.s a0, fa0, rtz\n"
      "00008067 ret\n");
  EXPECT_EQ(-43, CallI(test->entry(), -43.6f));
  EXPECT_EQ(-43, CallI(test->entry(), -43.5f));
  EXPECT_EQ(-43, CallI(test->entry(), -43.4f));
  EXPECT_EQ(-43, CallI(test->entry(), -43.0f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.6f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.5f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.4f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.0f));
  EXPECT_EQ(0, CallI(test->entry(), -0.0f));
  EXPECT_EQ(0, CallI(test->entry(), +0.0f));
  EXPECT_EQ(42, CallI(test->entry(), 42.0f));
  EXPECT_EQ(42, CallI(test->entry(), 42.4f));
  EXPECT_EQ(42, CallI(test->entry(), 42.5f));
  EXPECT_EQ(42, CallI(test->entry(), 42.6f));
  EXPECT_EQ(43, CallI(test->entry(), 43.0f));
  EXPECT_EQ(43, CallI(test->entry(), 43.4f));
  EXPECT_EQ(43, CallI(test->entry(), 43.5f));
  EXPECT_EQ(43, CallI(test->entry(), 43.6f));
}

ASSEMBLER_TEST_GENERATE(ConvertSingleToWord_RDN, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtws(A0, FA0, RDN);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertSingleToWord_RDN, test) {
  EXPECT_DISASSEMBLY(
      "c0052553 fcvt.w.s a0, fa0, rdn\n"
      "00008067 ret\n");
  EXPECT_EQ(-44, CallI(test->entry(), -43.6f));
  EXPECT_EQ(-44, CallI(test->entry(), -43.5f));
  EXPECT_EQ(-44, CallI(test->entry(), -43.4f));
  EXPECT_EQ(-43, CallI(test->entry(), -43.0f));
  EXPECT_EQ(-43, CallI(test->entry(), -42.6f));
  EXPECT_EQ(-43, CallI(test->entry(), -42.5f));
  EXPECT_EQ(-43, CallI(test->entry(), -42.4f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.0f));
  EXPECT_EQ(0, CallI(test->entry(), -0.0f));
  EXPECT_EQ(0, CallI(test->entry(), +0.0f));
  EXPECT_EQ(42, CallI(test->entry(), 42.0f));
  EXPECT_EQ(42, CallI(test->entry(), 42.4f));
  EXPECT_EQ(42, CallI(test->entry(), 42.5f));
  EXPECT_EQ(42, CallI(test->entry(), 42.6f));
  EXPECT_EQ(43, CallI(test->entry(), 43.0f));
  EXPECT_EQ(43, CallI(test->entry(), 43.4f));
  EXPECT_EQ(43, CallI(test->entry(), 43.5f));
  EXPECT_EQ(43, CallI(test->entry(), 43.6f));
}

ASSEMBLER_TEST_GENERATE(ConvertSingleToWord_RUP, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtws(A0, FA0, RUP);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertSingleToWord_RUP, test) {
  EXPECT_DISASSEMBLY(
      "c0053553 fcvt.w.s a0, fa0, rup\n"
      "00008067 ret\n");
  EXPECT_EQ(-43, CallI(test->entry(), -43.6f));
  EXPECT_EQ(-43, CallI(test->entry(), -43.5f));
  EXPECT_EQ(-43, CallI(test->entry(), -43.4f));
  EXPECT_EQ(-43, CallI(test->entry(), -43.0f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.6f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.5f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.4f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.0f));
  EXPECT_EQ(0, CallI(test->entry(), -0.0f));
  EXPECT_EQ(0, CallI(test->entry(), +0.0f));
  EXPECT_EQ(42, CallI(test->entry(), 42.0f));
  EXPECT_EQ(43, CallI(test->entry(), 42.4f));
  EXPECT_EQ(43, CallI(test->entry(), 42.5f));
  EXPECT_EQ(43, CallI(test->entry(), 42.6f));
  EXPECT_EQ(43, CallI(test->entry(), 43.0f));
  EXPECT_EQ(44, CallI(test->entry(), 43.5f));
  EXPECT_EQ(44, CallI(test->entry(), 43.5f));
  EXPECT_EQ(44, CallI(test->entry(), 43.6f));
}

ASSEMBLER_TEST_GENERATE(ConvertSingleToWord_RMM, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtws(A0, FA0, RMM);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertSingleToWord_RMM, test) {
  EXPECT_DISASSEMBLY(
      "c0054553 fcvt.w.s a0, fa0, rmm\n"
      "00008067 ret\n");
  EXPECT_EQ(-44, CallI(test->entry(), -43.6f));
  EXPECT_EQ(-44, CallI(test->entry(), -43.5f));
  EXPECT_EQ(-43, CallI(test->entry(), -43.4f));
  EXPECT_EQ(-43, CallI(test->entry(), -43.0f));
  EXPECT_EQ(-43, CallI(test->entry(), -42.6f));
  EXPECT_EQ(-43, CallI(test->entry(), -42.5f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.4f));
  EXPECT_EQ(-42, CallI(test->entry(), -42.0f));
  EXPECT_EQ(0, CallI(test->entry(), -0.0f));
  EXPECT_EQ(0, CallI(test->entry(), +0.0f));
  EXPECT_EQ(42, CallI(test->entry(), 42.0f));
  EXPECT_EQ(42, CallI(test->entry(), 42.4f));
  EXPECT_EQ(43, CallI(test->entry(), 42.5f));
  EXPECT_EQ(43, CallI(test->entry(), 42.6f));
  EXPECT_EQ(43, CallI(test->entry(), 43.0f));
  EXPECT_EQ(43, CallI(test->entry(), 43.4f));
  EXPECT_EQ(44, CallI(test->entry(), 43.5f));
  EXPECT_EQ(44, CallI(test->entry(), 43.6f));
}

ASSEMBLER_TEST_GENERATE(ConvertSingleToUnsignedWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtwus(A0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertSingleToUnsignedWord, test) {
  EXPECT_DISASSEMBLY(
      "c0150553 fcvt.wu.s a0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(0, CallI(test->entry(), static_cast<float>(-42)));
  EXPECT_EQ(0, CallI(test->entry(), static_cast<float>(0)));
  EXPECT_EQ(42, CallI(test->entry(), static_cast<float>(42)));
  EXPECT_EQ(sign_extend(0),
            CallI(test->entry(), static_cast<float>(kMinInt32)));
  // float loss of precision
  EXPECT_EQ(-2147483648, CallI(test->entry(), static_cast<float>(kMaxInt32)));
  EXPECT_EQ(sign_extend(kMaxUint32),
            CallI(test->entry(), static_cast<float>(kMaxUint32)));
  EXPECT_EQ(sign_extend(0),
            CallI(test->entry(), static_cast<float>(kMinInt64)));
  EXPECT_EQ(sign_extend(kMaxUint32),
            CallI(test->entry(), static_cast<float>(kMaxInt64)));
  EXPECT_EQ(sign_extend(kMaxUint32),
            CallI(test->entry(), static_cast<float>(kMaxUint64)));
  EXPECT_EQ(sign_extend(0),
            CallI(test->entry(), -std::numeric_limits<float>::infinity()));
  EXPECT_EQ(sign_extend(kMaxUint32),
            CallI(test->entry(), std::numeric_limits<float>::infinity()));
  EXPECT_EQ(sign_extend(kMaxUint32),
            CallI(test->entry(), std::numeric_limits<float>::signaling_NaN()));
}

ASSEMBLER_TEST_GENERATE(ConvertWordToSingle, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtsw(FA0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertWordToSingle, test) {
  EXPECT_DISASSEMBLY(
      "d0050553 fcvt.s.w fa0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(-42.0f, CallF(test->entry(), sign_extend(-42)));
  EXPECT_EQ(0.0f, CallF(test->entry(), sign_extend(0)));
  EXPECT_EQ(42.0f, CallF(test->entry(), sign_extend(42)));
  EXPECT_EQ(static_cast<float>(kMinInt32),
            CallF(test->entry(), sign_extend(kMinInt32)));
  EXPECT_EQ(static_cast<float>(kMaxInt32),
            CallF(test->entry(), sign_extend(kMaxInt32)));
  EXPECT_EQ(-1.0f, CallF(test->entry(), sign_extend(kMaxUint32)));
}

ASSEMBLER_TEST_GENERATE(ConvertUnsignedWordToSingle, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtswu(FA0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertUnsignedWordToSingle, test) {
  EXPECT_DISASSEMBLY(
      "d0150553 fcvt.s.wu fa0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(
      static_cast<float>(static_cast<uint32_t>(static_cast<int32_t>(-42))),
      CallF(test->entry(), sign_extend(-42)));
  EXPECT_EQ(0.0f, CallF(test->entry(), sign_extend(0)));
  EXPECT_EQ(42.0f, CallF(test->entry(), sign_extend(42)));
  EXPECT_EQ(static_cast<float>(static_cast<uint32_t>(kMinInt32)),
            CallF(test->entry(), sign_extend(kMinInt32)));
  EXPECT_EQ(static_cast<float>(kMaxInt32),
            CallF(test->entry(), sign_extend(kMaxInt32)));
  EXPECT_EQ(static_cast<float>(kMaxUint32),
            CallF(test->entry(), sign_extend(kMaxUint32)));
}

ASSEMBLER_TEST_GENERATE(SingleMove, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmvs(FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleMove, test) {
  EXPECT_DISASSEMBLY(
      "20b58553 fmv.s fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(36.0f, CallF(test->entry(), 42.0f, 36.0f));
  EXPECT_EQ(std::numeric_limits<float>::infinity(),
            CallF(test->entry(), -std::numeric_limits<float>::infinity(),
                  std::numeric_limits<float>::infinity()));
}

ASSEMBLER_TEST_GENERATE(SingleAbsoluteValue, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fabss(FA0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleAbsoluteValue, test) {
  EXPECT_DISASSEMBLY(
      "20a52553 fabs.s fa0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(0.0f, CallF(test->entry(), 0.0f));
  EXPECT_EQ(0.0f, CallF(test->entry(), -0.0f));
  EXPECT_EQ(42.0f, CallF(test->entry(), 42.0f));
  EXPECT_EQ(42.0f, CallF(test->entry(), -42.0f));
  EXPECT_EQ(std::numeric_limits<float>::infinity(),
            CallF(test->entry(), std::numeric_limits<float>::infinity()));
  EXPECT_EQ(std::numeric_limits<float>::infinity(),
            CallF(test->entry(), -std::numeric_limits<float>::infinity()));
}

ASSEMBLER_TEST_GENERATE(SingleNegate, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fnegs(FA0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleNegate, test) {
  EXPECT_DISASSEMBLY(
      "20a51553 fneg.s fa0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(-0.0f, CallF(test->entry(), 0.0f));
  EXPECT_EQ(0.0f, CallF(test->entry(), -0.0f));
  EXPECT_EQ(-42.0f, CallF(test->entry(), 42.0f));
  EXPECT_EQ(42.0f, CallF(test->entry(), -42.0f));
  EXPECT_EQ(-std::numeric_limits<float>::infinity(),
            CallF(test->entry(), std::numeric_limits<float>::infinity()));
  EXPECT_EQ(std::numeric_limits<float>::infinity(),
            CallF(test->entry(), -std::numeric_limits<float>::infinity()));
}

ASSEMBLER_TEST_GENERATE(BitCastSingleToInteger, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmvxw(A0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitCastSingleToInteger, test) {
  EXPECT_DISASSEMBLY(
      "e0050553 fmv.x.w a0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(bit_cast<int32_t>(0.0f), CallI(test->entry(), 0.0f));
  EXPECT_EQ(bit_cast<int32_t>(-0.0f), CallI(test->entry(), -0.0f));
  EXPECT_EQ(bit_cast<int32_t>(42.0f), CallI(test->entry(), 42.0f));
  EXPECT_EQ(bit_cast<int32_t>(-42.0f), CallI(test->entry(), -42.0f));
  EXPECT_EQ(bit_cast<int32_t>(std::numeric_limits<float>::quiet_NaN()),
            CallI(test->entry(), std::numeric_limits<float>::quiet_NaN()));
  EXPECT_EQ(bit_cast<int32_t>(std::numeric_limits<float>::signaling_NaN()),
            CallI(test->entry(), std::numeric_limits<float>::signaling_NaN()));
  EXPECT_EQ(bit_cast<int32_t>(std::numeric_limits<float>::infinity()),
            CallI(test->entry(), std::numeric_limits<float>::infinity()));
  EXPECT_EQ(bit_cast<int32_t>(-std::numeric_limits<float>::infinity()),
            CallI(test->entry(), -std::numeric_limits<float>::infinity()));
}

ASSEMBLER_TEST_GENERATE(BitCastIntegerToSingle, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmvwx(FA0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitCastIntegerToSingle, test) {
  EXPECT_DISASSEMBLY(
      "f0050553 fmv.w.x fa0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(0.0f, CallF(test->entry(), sign_extend(bit_cast<int32_t>(0.0f))));
  EXPECT_EQ(-0.0f, CallF(test->entry(), sign_extend(bit_cast<int32_t>(-0.0f))));
  EXPECT_EQ(42.0f, CallF(test->entry(), sign_extend(bit_cast<int32_t>(42.0f))));
  EXPECT_EQ(-42.0f,
            CallF(test->entry(), sign_extend(bit_cast<int32_t>(-42.0f))));
  EXPECT_EQ(true, isnan(CallF(test->entry(),
                              sign_extend(bit_cast<int32_t>(
                                  std::numeric_limits<float>::quiet_NaN())))));
  EXPECT_EQ(true,
            isnan(CallF(test->entry(),
                        sign_extend(bit_cast<int32_t>(
                            std::numeric_limits<float>::signaling_NaN())))));
  EXPECT_EQ(std::numeric_limits<float>::infinity(),
            CallF(test->entry(), sign_extend(bit_cast<int32_t>(
                                     std::numeric_limits<float>::infinity()))));
  EXPECT_EQ(
      -std::numeric_limits<float>::infinity(),
      CallF(test->entry(), sign_extend(bit_cast<int32_t>(
                               -std::numeric_limits<float>::infinity()))));
}

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(ConvertSingleToDoubleWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtls(A0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertSingleToDoubleWord, test) {
  EXPECT_DISASSEMBLY(
      "c0250553 fcvt.l.s a0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(-42, CallI(test->entry(), static_cast<float>(-42)));
  EXPECT_EQ(0, CallI(test->entry(), static_cast<float>(0)));
  EXPECT_EQ(42, CallI(test->entry(), static_cast<float>(42)));
  EXPECT_EQ(static_cast<int64_t>(kMinInt32),
            CallI(test->entry(), static_cast<float>(kMinInt32)));
  // float loses precision:
  EXPECT_EQ(static_cast<int64_t>(kMaxInt32) + 1,
            CallI(test->entry(), static_cast<float>(kMaxInt32)));
  EXPECT_EQ(static_cast<int64_t>(kMaxUint32) + 1,
            CallI(test->entry(), static_cast<float>(kMaxUint32)));
  EXPECT_EQ(kMinInt64, CallI(test->entry(), static_cast<float>(kMinInt64)));
  EXPECT_EQ(kMaxInt64, CallI(test->entry(), static_cast<float>(kMaxInt64)));
  EXPECT_EQ(kMaxInt64, CallI(test->entry(), static_cast<float>(kMaxUint64)));
  EXPECT_EQ(kMinInt64,
            CallI(test->entry(), -std::numeric_limits<float>::infinity()));
  EXPECT_EQ(kMaxInt64,
            CallI(test->entry(), std::numeric_limits<float>::infinity()));
  EXPECT_EQ(kMaxInt64,
            CallI(test->entry(), std::numeric_limits<float>::signaling_NaN()));
}

ASSEMBLER_TEST_GENERATE(ConvertSingleToUnsignedDoubleWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtlus(A0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertSingleToUnsignedDoubleWord, test) {
  EXPECT_DISASSEMBLY(
      "c0350553 fcvt.lu.s a0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(0, CallI(test->entry(), static_cast<float>(-42)));
  EXPECT_EQ(0, CallI(test->entry(), static_cast<float>(0)));
  EXPECT_EQ(42, CallI(test->entry(), static_cast<float>(42)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(0)),
            CallI(test->entry(), static_cast<float>(kMinInt32)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(kMaxInt32) + 1),
            CallI(test->entry(), static_cast<float>(kMaxInt32)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(kMaxUint32) + 1),
            CallI(test->entry(), static_cast<float>(kMaxUint32)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(0)),
            CallI(test->entry(), static_cast<float>(kMinInt64)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(kMaxInt64) + 1),
            CallI(test->entry(), static_cast<float>(kMaxInt64)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(kMaxUint64)),
            CallI(test->entry(), static_cast<float>(kMaxUint64)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(0)),
            CallI(test->entry(), -std::numeric_limits<float>::infinity()));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(kMaxUint64)),
            CallI(test->entry(), std::numeric_limits<float>::infinity()));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(kMaxUint64)),
            CallI(test->entry(), std::numeric_limits<float>::signaling_NaN()));
}

ASSEMBLER_TEST_GENERATE(ConvertDoubleWordToSingle, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtsl(FA0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertDoubleWordToSingle, test) {
  EXPECT_DISASSEMBLY(
      "d0250553 fcvt.s.l fa0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(0.0f, CallF(test->entry(), sign_extend(0)));
  EXPECT_EQ(42.0f, CallF(test->entry(), sign_extend(42)));
  EXPECT_EQ(-42.0f, CallF(test->entry(), sign_extend(-42)));
  EXPECT_EQ(static_cast<float>(kMinInt32),
            CallF(test->entry(), sign_extend(kMinInt32)));
  EXPECT_EQ(static_cast<float>(kMaxInt32),
            CallF(test->entry(), sign_extend(kMaxInt32)));
  EXPECT_EQ(static_cast<float>(sign_extend(kMaxUint32)),
            CallF(test->entry(), sign_extend(kMaxUint32)));
  EXPECT_EQ(static_cast<float>(kMinInt64),
            CallF(test->entry(), sign_extend(kMinInt64)));
  EXPECT_EQ(static_cast<float>(kMaxInt64),
            CallF(test->entry(), sign_extend(kMaxInt64)));
  EXPECT_EQ(static_cast<float>(sign_extend(kMaxUint64)),
            CallF(test->entry(), sign_extend(kMaxUint64)));
}

ASSEMBLER_TEST_GENERATE(ConvertUnsignedDoubleWordToSingle, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtslu(FA0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertUnsignedDoubleWordToSingle, test) {
  EXPECT_DISASSEMBLY(
      "d0350553 fcvt.s.lu fa0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(0.0f, CallF(test->entry(), sign_extend(0)));
  EXPECT_EQ(42.0f, CallF(test->entry(), sign_extend(42)));
  EXPECT_EQ(static_cast<float>(static_cast<uint64_t>(sign_extend(-42))),
            CallF(test->entry(), sign_extend(-42)));
  EXPECT_EQ(static_cast<float>(static_cast<uint64_t>(sign_extend(kMinInt32))),
            CallF(test->entry(), sign_extend(kMinInt32)));
  EXPECT_EQ(static_cast<float>(static_cast<uint64_t>(sign_extend(kMaxInt32))),
            CallF(test->entry(), sign_extend(kMaxInt32)));
  EXPECT_EQ(static_cast<float>(static_cast<uint64_t>(sign_extend(kMaxUint32))),
            CallF(test->entry(), sign_extend(kMaxUint32)));
  EXPECT_EQ(static_cast<float>(static_cast<uint64_t>(sign_extend(kMinInt64))),
            CallF(test->entry(), sign_extend(kMinInt64)));
  EXPECT_EQ(static_cast<float>(static_cast<uint64_t>(sign_extend(kMaxInt64))),
            CallF(test->entry(), sign_extend(kMaxInt64)));
  EXPECT_EQ(static_cast<float>(kMaxUint64),
            CallF(test->entry(), sign_extend(kMaxUint64)));
}
#endif

ASSEMBLER_TEST_GENERATE(LoadDoubleFloat, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fld(FA0, Address(A0, 1 * sizeof(double)));
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadDoubleFloat, test) {
  EXPECT_DISASSEMBLY(
      "00853507 fld fa0, 8(a0)\n"
      "00008067 ret\n");

  double* data = reinterpret_cast<double*>(malloc(3 * sizeof(double)));
  data[0] = 1.7;
  data[1] = 2.8;
  data[2] = 3.9;
  EXPECT_EQ(data[1], CallD(test->entry(), reinterpret_cast<intx_t>(data)));
}

ASSEMBLER_TEST_GENERATE(StoreDoubleFloat, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fsd(FA0, Address(A0, 1 * sizeof(double)));
  __ ret();
}
ASSEMBLER_TEST_RUN(StoreDoubleFloat, test) {
  EXPECT_DISASSEMBLY(
      "00a53427 fsd fa0, 8(a0)\n"
      "00008067 ret\n");

  double* data = reinterpret_cast<double*>(malloc(3 * sizeof(double)));
  data[0] = 1.7;
  data[1] = 2.8;
  data[2] = 3.9;
  CallD(test->entry(), reinterpret_cast<intx_t>(data), 4.2);
  EXPECT_EQ(4.2, data[1]);
}

ASSEMBLER_TEST_GENERATE(DoubleMultiplyAdd, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmaddd(FA0, FA0, FA1, FA2);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleMultiplyAdd, test) {
  EXPECT_DISASSEMBLY(
      "62b50543 fmadd.d fa0, fa0, fa1, fa2\n"
      "00008067 ret\n");
  EXPECT_EQ(22.0, CallD(test->entry(), 3.0, 5.0, 7.0));
  EXPECT_EQ(-8.0, CallD(test->entry(), -3.0, 5.0, 7.0));
  EXPECT_EQ(-8.0, CallD(test->entry(), 3.0, -5.0, 7.0));
  EXPECT_EQ(8.0, CallD(test->entry(), 3.0, 5.0, -7.0));

  EXPECT_EQ(26.0, CallD(test->entry(), 7.0, 3.0, 5.0));
  EXPECT_EQ(-16.0, CallD(test->entry(), -7.0, 3.0, 5.0));
  EXPECT_EQ(-16.0, CallD(test->entry(), 7.0, -3.0, 5.0));
  EXPECT_EQ(16.0, CallD(test->entry(), 7.0, 3.0, -5.0));
}

ASSEMBLER_TEST_GENERATE(DoubleMultiplySubtract, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmsubd(FA0, FA0, FA1, FA2);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleMultiplySubtract, test) {
  EXPECT_DISASSEMBLY(
      "62b50547 fmsub.d fa0, fa0, fa1, fa2\n"
      "00008067 ret\n");
  EXPECT_EQ(8.0, CallD(test->entry(), 3.0, 5.0, 7.0));
  EXPECT_EQ(-22.0, CallD(test->entry(), -3.0, 5.0, 7.0));
  EXPECT_EQ(-22.0, CallD(test->entry(), 3.0, -5.0, 7.0));
  EXPECT_EQ(22.0, CallD(test->entry(), 3.0, 5.0, -7.0));

  EXPECT_EQ(16.0, CallD(test->entry(), 7.0, 3.0, 5.0));
  EXPECT_EQ(-26.0, CallD(test->entry(), -7.0, 3.0, 5.0));
  EXPECT_EQ(-26.0, CallD(test->entry(), 7.0, -3.0, 5.0));
  EXPECT_EQ(26.0, CallD(test->entry(), 7.0, 3.0, -5.0));
}

ASSEMBLER_TEST_GENERATE(DoubleNegateMultiplySubtract, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fnmsubd(FA0, FA0, FA1, FA2);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleNegateMultiplySubtract, test) {
  EXPECT_DISASSEMBLY(
      "62b5054b fnmsub.d fa0, fa0, fa1, fa2\n"
      "00008067 ret\n");
  EXPECT_EQ(-8.0, CallD(test->entry(), 3.0, 5.0, 7.0));
  EXPECT_EQ(22.0, CallD(test->entry(), -3.0, 5.0, 7.0));
  EXPECT_EQ(22.0, CallD(test->entry(), 3.0, -5.0, 7.0));
  EXPECT_EQ(-22.0, CallD(test->entry(), 3.0, 5.0, -7.0));

  EXPECT_EQ(-16.0, CallD(test->entry(), 7.0, 3.0, 5.0));
  EXPECT_EQ(26.0, CallD(test->entry(), -7.0, 3.0, 5.0));
  EXPECT_EQ(26.0, CallD(test->entry(), 7.0, -3.0, 5.0));
  EXPECT_EQ(-26.0, CallD(test->entry(), 7.0, 3.0, -5.0));
}

ASSEMBLER_TEST_GENERATE(DoubleNegateMultiplyAdd, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fnmaddd(FA0, FA0, FA1, FA2);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleNegateMultiplyAdd, test) {
  EXPECT_DISASSEMBLY(
      "62b5054f fnmadd.d fa0, fa0, fa1, fa2\n"
      "00008067 ret\n");
  EXPECT_EQ(-22.0, CallD(test->entry(), 3.0, 5.0, 7.0));
  EXPECT_EQ(8.0, CallD(test->entry(), -3.0, 5.0, 7.0));
  EXPECT_EQ(8.0, CallD(test->entry(), 3.0, -5.0, 7.0));
  EXPECT_EQ(-8.0, CallD(test->entry(), 3.0, 5.0, -7.0));

  EXPECT_EQ(-26.0, CallD(test->entry(), 7.0, 3.0, 5.0));
  EXPECT_EQ(16.0, CallD(test->entry(), -7.0, 3.0, 5.0));
  EXPECT_EQ(16.0, CallD(test->entry(), 7.0, -3.0, 5.0));
  EXPECT_EQ(-16.0, CallD(test->entry(), 7.0, 3.0, -5.0));
}

ASSEMBLER_TEST_GENERATE(DoubleAdd, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ faddd(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleAdd, test) {
  EXPECT_DISASSEMBLY(
      "02b50553 fadd.d fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(8.0, CallD(test->entry(), 3.0, 5.0));
  EXPECT_EQ(2.0, CallD(test->entry(), -3.0, 5.0));
  EXPECT_EQ(-2.0, CallD(test->entry(), 3.0, -5.0));
  EXPECT_EQ(-8.0, CallD(test->entry(), -3.0, -5.0));

  EXPECT_EQ(10.0, CallD(test->entry(), 7.0, 3.0));
  EXPECT_EQ(-4.0, CallD(test->entry(), -7.0, 3.0));
  EXPECT_EQ(4.0, CallD(test->entry(), 7.0, -3.0));
  EXPECT_EQ(-10.0, CallD(test->entry(), -7.0, -3.0));
}

ASSEMBLER_TEST_GENERATE(DoubleSubtract, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fsubd(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleSubtract, test) {
  EXPECT_DISASSEMBLY(
      "0ab50553 fsub.d fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(-2.0, CallD(test->entry(), 3.0, 5.0));
  EXPECT_EQ(-8.0, CallD(test->entry(), -3.0, 5.0));
  EXPECT_EQ(8.0, CallD(test->entry(), 3.0, -5.0));
  EXPECT_EQ(2.0, CallD(test->entry(), -3.0, -5.0));

  EXPECT_EQ(4.0, CallD(test->entry(), 7.0, 3.0));
  EXPECT_EQ(-10.0, CallD(test->entry(), -7.0, 3.0));
  EXPECT_EQ(10.0, CallD(test->entry(), 7.0, -3.0));
  EXPECT_EQ(-4.0, CallD(test->entry(), -7.0, -3.0));
}

ASSEMBLER_TEST_GENERATE(DoubleMultiply, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmuld(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleMultiply, test) {
  EXPECT_DISASSEMBLY(
      "12b50553 fmul.d fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(15.0, CallD(test->entry(), 3.0, 5.0));
  EXPECT_EQ(-15.0, CallD(test->entry(), -3.0, 5.0));
  EXPECT_EQ(-15.0, CallD(test->entry(), 3.0, -5.0));
  EXPECT_EQ(15.0, CallD(test->entry(), -3.0, -5.0));

  EXPECT_EQ(21.0, CallD(test->entry(), 7.0, 3.0));
  EXPECT_EQ(-21.0, CallD(test->entry(), -7.0, 3.0));
  EXPECT_EQ(-21.0, CallD(test->entry(), 7.0, -3.0));
  EXPECT_EQ(21.0, CallD(test->entry(), -7.0, -3.0));
}

ASSEMBLER_TEST_GENERATE(DoubleDivide, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fdivd(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleDivide, test) {
  EXPECT_DISASSEMBLY(
      "1ab50553 fdiv.d fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(2.0, CallD(test->entry(), 10.0, 5.0));
  EXPECT_EQ(-2.0, CallD(test->entry(), -10.0, 5.0));
  EXPECT_EQ(-2.0, CallD(test->entry(), 10.0, -5.0));
  EXPECT_EQ(2.0, CallD(test->entry(), -10.0, -5.0));
}

ASSEMBLER_TEST_GENERATE(DoubleSquareRoot, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fsqrtd(FA0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleSquareRoot, test) {
  EXPECT_DISASSEMBLY(
      "5a050553 fsqrt.d fa0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(0.0, CallD(test->entry(), 0.0));
  EXPECT_EQ(1.0, CallD(test->entry(), 1.0));
  EXPECT_EQ(2.0, CallD(test->entry(), 4.0));
  EXPECT_EQ(3.0, CallD(test->entry(), 9.0));
}

ASSEMBLER_TEST_GENERATE(DoubleSignInject, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fsgnjd(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleSignInject, test) {
  EXPECT_DISASSEMBLY(
      "22b50553 fsgnj.d fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, 5.0));
  EXPECT_EQ(3.0, CallD(test->entry(), -3.0, 5.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), 3.0, -5.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, -5.0));
}

ASSEMBLER_TEST_GENERATE(DoubleNegatedSignInject, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fsgnjnd(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleNegatedSignInject, test) {
  EXPECT_DISASSEMBLY(
      "22b51553 fsgnjn.d fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(-3.0, CallD(test->entry(), 3.0, 5.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, 5.0));
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, -5.0));
  EXPECT_EQ(3.0, CallD(test->entry(), -3.0, -5.0));
}

ASSEMBLER_TEST_GENERATE(DoubleXorSignInject, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fsgnjxd(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleXorSignInject, test) {
  EXPECT_DISASSEMBLY(
      "22b52553 fsgnjx.d fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, 5.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, 5.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), 3.0, -5.0));
  EXPECT_EQ(3.0, CallD(test->entry(), -3.0, -5.0));
}

ASSEMBLER_TEST_GENERATE(DoubleMin, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmind(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleMin, test) {
  EXPECT_DISASSEMBLY(
      "2ab50553 fmin.d fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(1.0, CallD(test->entry(), 3.0, 1.0));
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, 3.0));
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, 5.0));
  EXPECT_EQ(-1.0, CallD(test->entry(), 3.0, -1.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), 3.0, -3.0));
  EXPECT_EQ(-5.0, CallD(test->entry(), 3.0, -5.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, 1.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, 3.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, 5.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, -1.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, -3.0));
  EXPECT_EQ(-5.0, CallD(test->entry(), -3.0, -5.0));

  EXPECT_EQ(bit_cast<uint64_t>(-0.0),
            bit_cast<uint64_t>(CallD(test->entry(), 0.0, -0.0)));
  EXPECT_EQ(bit_cast<uint64_t>(-0.0),
            bit_cast<uint64_t>(CallD(test->entry(), -0.0, 0.0)));

  double qNAN = std::numeric_limits<double>::quiet_NaN();
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, qNAN));
  EXPECT_EQ(3.0, CallD(test->entry(), qNAN, 3.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, qNAN));
  EXPECT_EQ(-3.0, CallD(test->entry(), qNAN, -3.0));

  double sNAN = std::numeric_limits<double>::signaling_NaN();
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, sNAN));
  EXPECT_EQ(3.0, CallD(test->entry(), sNAN, 3.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, sNAN));
  EXPECT_EQ(-3.0, CallD(test->entry(), sNAN, -3.0));

  EXPECT_EQ(bit_cast<uint64_t>(qNAN),
            bit_cast<uint64_t>(CallD(test->entry(), sNAN, sNAN)));
  EXPECT_EQ(bit_cast<uint64_t>(qNAN),
            bit_cast<uint64_t>(CallD(test->entry(), qNAN, qNAN)));
  EXPECT_EQ(bit_cast<uint64_t>(qNAN),
            bit_cast<uint64_t>(CallD(test->entry(), qNAN, sNAN)));
  EXPECT_EQ(bit_cast<uint64_t>(qNAN),
            bit_cast<uint64_t>(CallD(test->entry(), sNAN, qNAN)));
}

ASSEMBLER_TEST_GENERATE(DoubleMax, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmaxd(FA0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleMax, test) {
  EXPECT_DISASSEMBLY(
      "2ab51553 fmax.d fa0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, 1.0));
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, 3.0));
  EXPECT_EQ(5.0, CallD(test->entry(), 3.0, 5.0));
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, -1.0));
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, -3.0));
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, -5.0));
  EXPECT_EQ(1.0, CallD(test->entry(), -3.0, 1.0));
  EXPECT_EQ(3.0, CallD(test->entry(), -3.0, 3.0));
  EXPECT_EQ(5.0, CallD(test->entry(), -3.0, 5.0));
  EXPECT_EQ(-1.0, CallD(test->entry(), -3.0, -1.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, -3.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, -5.0));

  EXPECT_EQ(bit_cast<uint64_t>(0.0),
            bit_cast<uint64_t>(CallD(test->entry(), 0.0, -0.0)));
  EXPECT_EQ(bit_cast<uint64_t>(0.0),
            bit_cast<uint64_t>(CallD(test->entry(), -0.0, 0.0)));

  double qNAN = std::numeric_limits<double>::quiet_NaN();
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, qNAN));
  EXPECT_EQ(3.0, CallD(test->entry(), qNAN, 3.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, qNAN));
  EXPECT_EQ(-3.0, CallD(test->entry(), qNAN, -3.0));

  double sNAN = std::numeric_limits<double>::signaling_NaN();
  EXPECT_EQ(3.0, CallD(test->entry(), 3.0, sNAN));
  EXPECT_EQ(3.0, CallD(test->entry(), sNAN, 3.0));
  EXPECT_EQ(-3.0, CallD(test->entry(), -3.0, sNAN));
  EXPECT_EQ(-3.0, CallD(test->entry(), sNAN, -3.0));

  EXPECT_EQ(bit_cast<uint64_t>(qNAN),
            bit_cast<uint64_t>(CallD(test->entry(), sNAN, sNAN)));
  EXPECT_EQ(bit_cast<uint64_t>(qNAN),
            bit_cast<uint64_t>(CallD(test->entry(), qNAN, qNAN)));
  EXPECT_EQ(bit_cast<uint64_t>(qNAN),
            bit_cast<uint64_t>(CallD(test->entry(), qNAN, sNAN)));
  EXPECT_EQ(bit_cast<uint64_t>(qNAN),
            bit_cast<uint64_t>(CallD(test->entry(), sNAN, qNAN)));
}

ASSEMBLER_TEST_GENERATE(DoubleToSingle, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtsd(FA0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleToSingle, test) {
  EXPECT_DISASSEMBLY(
      "40150553 fcvt.s.d fa0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(0.0f, CallF(test->entry(), 0.0));
  EXPECT_EQ(42.0f, CallF(test->entry(), 42.0));
  EXPECT_EQ(-42.0f, CallF(test->entry(), -42.0));
  EXPECT_EQ(true, isnan(CallF(test->entry(),
                              std::numeric_limits<double>::quiet_NaN())));
  EXPECT_EQ(true, isnan(CallF(test->entry(),
                              std::numeric_limits<double>::signaling_NaN())));
  EXPECT_EQ(std::numeric_limits<float>::infinity(),
            CallF(test->entry(), std::numeric_limits<double>::infinity()));
  EXPECT_EQ(-std::numeric_limits<float>::infinity(),
            CallF(test->entry(), -std::numeric_limits<double>::infinity()));
}

ASSEMBLER_TEST_GENERATE(SingleToDouble, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtds(FA0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SingleToDouble, test) {
  EXPECT_DISASSEMBLY(
      "42050553 fcvt.d.s fa0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(0.0, CallD(test->entry(), 0.0f));
  EXPECT_EQ(42.0, CallD(test->entry(), 42.0f));
  EXPECT_EQ(-42.0, CallD(test->entry(), -42.0f));
  EXPECT_EQ(true, isnan(CallD(test->entry(),
                              std::numeric_limits<float>::quiet_NaN())));
  EXPECT_EQ(true, isnan(CallD(test->entry(),
                              std::numeric_limits<float>::signaling_NaN())));
  EXPECT_EQ(std::numeric_limits<double>::infinity(),
            CallD(test->entry(), std::numeric_limits<float>::infinity()));
  EXPECT_EQ(-std::numeric_limits<double>::infinity(),
            CallD(test->entry(), -std::numeric_limits<float>::infinity()));
}

ASSEMBLER_TEST_GENERATE(NaNBoxing, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ ret();
}
ASSEMBLER_TEST_RUN(NaNBoxing, test) {
  EXPECT_DISASSEMBLY("00008067 ret\n");
  EXPECT_EQ(true, isnan(CallD(test->entry(), 42.0f)));
}

ASSEMBLER_TEST_GENERATE(DoubleEqual, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ feqd(A0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleEqual, test) {
  EXPECT_DISASSEMBLY(
      "a2b52553 feq.d a0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, CallI(test->entry(), 3.0, 1.0));
  EXPECT_EQ(1, CallI(test->entry(), 3.0, 3.0));
  EXPECT_EQ(0, CallI(test->entry(), 3.0, 5.0));
  EXPECT_EQ(0, CallI(test->entry(), 3.0, -1.0));
  EXPECT_EQ(0, CallI(test->entry(), 3.0, -3.0));
  EXPECT_EQ(0, CallI(test->entry(), 3.0, -5.0));
  EXPECT_EQ(0, CallI(test->entry(), -3.0, 1.0));
  EXPECT_EQ(0, CallI(test->entry(), -3.0, 3.0));
  EXPECT_EQ(0, CallI(test->entry(), -3.0, 5.0));
  EXPECT_EQ(0, CallI(test->entry(), -3.0, -1.0));
  EXPECT_EQ(1, CallI(test->entry(), -3.0, -3.0));
  EXPECT_EQ(0, CallI(test->entry(), -3.0, -5.0));

  double qNAN = std::numeric_limits<double>::quiet_NaN();
  EXPECT_EQ(0, CallI(test->entry(), 3.0, qNAN));
  EXPECT_EQ(0, CallI(test->entry(), qNAN, 3.0));
  EXPECT_EQ(0, CallI(test->entry(), -3.0, qNAN));
  EXPECT_EQ(0, CallI(test->entry(), qNAN, -3.0));
}

ASSEMBLER_TEST_GENERATE(DoubleLessThan, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fltd(A0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleLessThan, test) {
  EXPECT_DISASSEMBLY(
      "a2b51553 flt.d a0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, CallI(test->entry(), 3.0, 1.0));
  EXPECT_EQ(0, CallI(test->entry(), 3.0, 3.0));
  EXPECT_EQ(1, CallI(test->entry(), 3.0, 5.0));
  EXPECT_EQ(0, CallI(test->entry(), 3.0, -1.0));
  EXPECT_EQ(0, CallI(test->entry(), 3.0, -3.0));
  EXPECT_EQ(0, CallI(test->entry(), 3.0, -5.0));
  EXPECT_EQ(1, CallI(test->entry(), -3.0, 1.0));
  EXPECT_EQ(1, CallI(test->entry(), -3.0, 3.0));
  EXPECT_EQ(1, CallI(test->entry(), -3.0, 5.0));
  EXPECT_EQ(1, CallI(test->entry(), -3.0, -1.0));
  EXPECT_EQ(0, CallI(test->entry(), -3.0, -3.0));
  EXPECT_EQ(0, CallI(test->entry(), -3.0, -5.0));

  double qNAN = std::numeric_limits<double>::quiet_NaN();
  EXPECT_EQ(0, CallI(test->entry(), 3.0, qNAN));
  EXPECT_EQ(0, CallI(test->entry(), qNAN, 3.0));
  EXPECT_EQ(0, CallI(test->entry(), -3.0, qNAN));
  EXPECT_EQ(0, CallI(test->entry(), qNAN, -3.0));
}

ASSEMBLER_TEST_GENERATE(DoubleLessOrEqual, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fled(A0, FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleLessOrEqual, test) {
  EXPECT_DISASSEMBLY(
      "a2b50553 fle.d a0, fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(0, CallI(test->entry(), 3.0, 1.0));
  EXPECT_EQ(1, CallI(test->entry(), 3.0, 3.0));
  EXPECT_EQ(1, CallI(test->entry(), 3.0, 5.0));
  EXPECT_EQ(0, CallI(test->entry(), 3.0, -1.0));
  EXPECT_EQ(0, CallI(test->entry(), 3.0, -3.0));
  EXPECT_EQ(0, CallI(test->entry(), 3.0, -5.0));
  EXPECT_EQ(1, CallI(test->entry(), -3.0, 1.0));
  EXPECT_EQ(1, CallI(test->entry(), -3.0, 3.0));
  EXPECT_EQ(1, CallI(test->entry(), -3.0, 5.0));
  EXPECT_EQ(1, CallI(test->entry(), -3.0, -1.0));
  EXPECT_EQ(1, CallI(test->entry(), -3.0, -3.0));
  EXPECT_EQ(0, CallI(test->entry(), -3.0, -5.0));

  double qNAN = std::numeric_limits<double>::quiet_NaN();
  EXPECT_EQ(0, CallI(test->entry(), 3.0, qNAN));
  EXPECT_EQ(0, CallI(test->entry(), qNAN, 3.0));
  EXPECT_EQ(0, CallI(test->entry(), -3.0, qNAN));
  EXPECT_EQ(0, CallI(test->entry(), qNAN, -3.0));
}

ASSEMBLER_TEST_GENERATE(DoubleClassify, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fclassd(A0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleClassify, test) {
  EXPECT_DISASSEMBLY(
      "e2051553 fclass.d a0, fa0\n"
      "00008067 ret\n");
  // Neg infinity
  EXPECT_EQ(1 << 0,
            CallI(test->entry(), -std::numeric_limits<double>::infinity()));
  // Neg normal
  EXPECT_EQ(1 << 1, CallI(test->entry(), -1.0));
  // Neg subnormal
  EXPECT_EQ(1 << 2,
            CallI(test->entry(), -std::numeric_limits<double>::min() / 2.0));
  // Neg zero
  EXPECT_EQ(1 << 3, CallI(test->entry(), -0.0));
  // Pos zero
  EXPECT_EQ(1 << 4, CallI(test->entry(), 0.0));
  // Pos subnormal
  EXPECT_EQ(1 << 5,
            CallI(test->entry(), std::numeric_limits<double>::min() / 2.0));
  // Pos normal
  EXPECT_EQ(1 << 6, CallI(test->entry(), 1.0));
  // Pos infinity
  EXPECT_EQ(1 << 7,
            CallI(test->entry(), std::numeric_limits<double>::infinity()));
  // Signaling NaN
  EXPECT_EQ(1 << 8,
            CallI(test->entry(), std::numeric_limits<double>::signaling_NaN()));
  // Queit NaN
  EXPECT_EQ(1 << 9,
            CallI(test->entry(), std::numeric_limits<double>::quiet_NaN()));
}

ASSEMBLER_TEST_GENERATE(ConvertDoubleToWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtwd(A0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertDoubleToWord, test) {
  EXPECT_DISASSEMBLY(
      "c2050553 fcvt.w.d a0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(-42, CallI(test->entry(), static_cast<double>(-42)));
  EXPECT_EQ(0, CallI(test->entry(), static_cast<double>(0)));
  EXPECT_EQ(42, CallI(test->entry(), static_cast<double>(42)));
  EXPECT_EQ(sign_extend(kMinInt32),
            CallI(test->entry(), static_cast<double>(kMinInt32)));
  EXPECT_EQ(sign_extend(kMaxInt32),
            CallI(test->entry(), static_cast<double>(kMaxInt32)));
  EXPECT_EQ(sign_extend(kMaxInt32),
            CallI(test->entry(), static_cast<double>(kMaxUint32)));
  EXPECT_EQ(sign_extend(kMinInt32),
            CallI(test->entry(), static_cast<double>(kMinInt64)));
  EXPECT_EQ(sign_extend(kMaxInt32),
            CallI(test->entry(), static_cast<double>(kMaxInt64)));
  EXPECT_EQ(sign_extend(kMaxInt32),
            CallI(test->entry(), static_cast<double>(kMaxUint64)));
  EXPECT_EQ(sign_extend(kMinInt32),
            CallI(test->entry(), -std::numeric_limits<double>::infinity()));
  EXPECT_EQ(sign_extend(kMaxInt32),
            CallI(test->entry(), std::numeric_limits<double>::infinity()));
  EXPECT_EQ(sign_extend(kMaxInt32),
            CallI(test->entry(), std::numeric_limits<double>::signaling_NaN()));
}

ASSEMBLER_TEST_GENERATE(ConvertDoubleToUnsignedWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtwud(A0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertDoubleToUnsignedWord, test) {
  EXPECT_DISASSEMBLY(
      "c2150553 fcvt.wu.d a0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(0, CallI(test->entry(), static_cast<double>(-42)));
  EXPECT_EQ(0, CallI(test->entry(), static_cast<double>(0)));
  EXPECT_EQ(42, CallI(test->entry(), static_cast<double>(42)));
  EXPECT_EQ(sign_extend(0),
            CallI(test->entry(), static_cast<double>(kMinInt32)));
  EXPECT_EQ(sign_extend(kMaxInt32),
            CallI(test->entry(), static_cast<double>(kMaxInt32)));
  EXPECT_EQ(sign_extend(kMaxUint32),
            CallI(test->entry(), static_cast<double>(kMaxUint32)));
  EXPECT_EQ(sign_extend(0),
            CallI(test->entry(), static_cast<double>(kMinInt64)));
  EXPECT_EQ(sign_extend(kMaxUint32),
            CallI(test->entry(), static_cast<double>(kMaxInt64)));
  EXPECT_EQ(sign_extend(kMaxUint32),
            CallI(test->entry(), static_cast<double>(kMaxUint64)));
  EXPECT_EQ(sign_extend(0),
            CallI(test->entry(), -std::numeric_limits<double>::infinity()));
  EXPECT_EQ(sign_extend(kMaxUint32),
            CallI(test->entry(), std::numeric_limits<double>::infinity()));
  EXPECT_EQ(sign_extend(kMaxUint32),
            CallI(test->entry(), std::numeric_limits<double>::signaling_NaN()));
}

ASSEMBLER_TEST_GENERATE(ConvertWordToDouble, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtdw(FA0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertWordToDouble, test) {
  EXPECT_DISASSEMBLY(
      "d2050553 fcvt.d.w fa0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(-42.0, CallD(test->entry(), sign_extend(-42)));
  EXPECT_EQ(0.0, CallD(test->entry(), sign_extend(0)));
  EXPECT_EQ(42.0, CallD(test->entry(), sign_extend(42)));
  EXPECT_EQ(static_cast<double>(kMinInt32),
            CallD(test->entry(), sign_extend(kMinInt32)));
  EXPECT_EQ(static_cast<double>(kMaxInt32),
            CallD(test->entry(), sign_extend(kMaxInt32)));
  EXPECT_EQ(-1.0, CallD(test->entry(), sign_extend(kMaxUint32)));
}

ASSEMBLER_TEST_GENERATE(ConvertUnsignedWordToDouble, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtdwu(FA0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertUnsignedWordToDouble, test) {
  EXPECT_DISASSEMBLY(
      "d2150553 fcvt.d.wu fa0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(
      static_cast<double>(static_cast<uint32_t>(static_cast<int32_t>(-42))),
      CallD(test->entry(), sign_extend(-42)));
  EXPECT_EQ(0.0, CallD(test->entry(), sign_extend(0)));
  EXPECT_EQ(42.0, CallD(test->entry(), sign_extend(42)));
  EXPECT_EQ(static_cast<double>(static_cast<uint32_t>(kMinInt32)),
            CallD(test->entry(), sign_extend(kMinInt32)));
  EXPECT_EQ(static_cast<double>(kMaxInt32),
            CallD(test->entry(), sign_extend(kMaxInt32)));
  EXPECT_EQ(static_cast<double>(kMaxUint32),
            CallD(test->entry(), sign_extend(kMaxUint32)));
}

ASSEMBLER_TEST_GENERATE(DoubleMove, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmvd(FA0, FA1);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleMove, test) {
  EXPECT_DISASSEMBLY(
      "22b58553 fmv.d fa0, fa1\n"
      "00008067 ret\n");
  EXPECT_EQ(36.0, CallD(test->entry(), 42.0, 36.0));
  EXPECT_EQ(std::numeric_limits<double>::infinity(),
            CallD(test->entry(), -std::numeric_limits<double>::infinity(),
                  std::numeric_limits<double>::infinity()));
}

ASSEMBLER_TEST_GENERATE(DoubleAbsoluteValue, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fabsd(FA0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleAbsoluteValue, test) {
  EXPECT_DISASSEMBLY(
      "22a52553 fabs.d fa0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(0.0, CallD(test->entry(), 0.0));
  EXPECT_EQ(0.0, CallD(test->entry(), -0.0));
  EXPECT_EQ(42.0, CallD(test->entry(), 42.0));
  EXPECT_EQ(42.0, CallD(test->entry(), -42.0));
  EXPECT_EQ(std::numeric_limits<double>::infinity(),
            CallD(test->entry(), std::numeric_limits<double>::infinity()));
  EXPECT_EQ(std::numeric_limits<double>::infinity(),
            CallD(test->entry(), -std::numeric_limits<double>::infinity()));
}

ASSEMBLER_TEST_GENERATE(DoubleNegate, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fnegd(FA0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(DoubleNegate, test) {
  EXPECT_DISASSEMBLY(
      "22a51553 fneg.d fa0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(-0.0, CallD(test->entry(), 0.0));
  EXPECT_EQ(0.0, CallD(test->entry(), -0.0));
  EXPECT_EQ(-42.0, CallD(test->entry(), 42.0));
  EXPECT_EQ(42.0, CallD(test->entry(), -42.0));
  EXPECT_EQ(-std::numeric_limits<double>::infinity(),
            CallD(test->entry(), std::numeric_limits<double>::infinity()));
  EXPECT_EQ(std::numeric_limits<double>::infinity(),
            CallD(test->entry(), -std::numeric_limits<double>::infinity()));
}

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(ConvertDoubleToDoubleWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtld(A0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertDoubleToDoubleWord, test) {
  EXPECT_DISASSEMBLY(
      "c2250553 fcvt.l.d a0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(-42, CallI(test->entry(), static_cast<double>(-42)));
  EXPECT_EQ(0, CallI(test->entry(), static_cast<double>(0)));
  EXPECT_EQ(42, CallI(test->entry(), static_cast<double>(42)));
  EXPECT_EQ(static_cast<int64_t>(kMinInt32),
            CallI(test->entry(), static_cast<double>(kMinInt32)));
  EXPECT_EQ(static_cast<int64_t>(kMaxInt32),
            CallI(test->entry(), static_cast<double>(kMaxInt32)));
  EXPECT_EQ(static_cast<int64_t>(kMaxUint32),
            CallI(test->entry(), static_cast<double>(kMaxUint32)));
  EXPECT_EQ(kMinInt64, CallI(test->entry(), static_cast<double>(kMinInt64)));
  EXPECT_EQ(kMaxInt64, CallI(test->entry(), static_cast<double>(kMaxInt64)));
  EXPECT_EQ(kMaxInt64, CallI(test->entry(), static_cast<double>(kMaxUint64)));
  EXPECT_EQ(kMinInt64,
            CallI(test->entry(), -std::numeric_limits<double>::infinity()));
  EXPECT_EQ(kMaxInt64,
            CallI(test->entry(), std::numeric_limits<double>::infinity()));
  EXPECT_EQ(kMaxInt64,
            CallI(test->entry(), std::numeric_limits<double>::signaling_NaN()));
}

ASSEMBLER_TEST_GENERATE(ConvertDoubleToDoubleWord_RNE, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtld(A0, FA0, RNE);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertDoubleToDoubleWord_RNE, test) {
  EXPECT_DISASSEMBLY(
      "c2250553 fcvt.l.d a0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(-44, CallI(test->entry(), -43.6));
  EXPECT_EQ(-44, CallI(test->entry(), -43.5));
  EXPECT_EQ(-43, CallI(test->entry(), -43.4));
  EXPECT_EQ(-43, CallI(test->entry(), -43.0));
  EXPECT_EQ(-43, CallI(test->entry(), -42.6));
  EXPECT_EQ(-42, CallI(test->entry(), -42.5));
  EXPECT_EQ(-42, CallI(test->entry(), -42.4));
  EXPECT_EQ(-42, CallI(test->entry(), -42.0));
  EXPECT_EQ(0, CallI(test->entry(), -0.0));
  EXPECT_EQ(0, CallI(test->entry(), +0.0));
  EXPECT_EQ(42, CallI(test->entry(), 42.0));
  EXPECT_EQ(42, CallI(test->entry(), 42.4));
  EXPECT_EQ(42, CallI(test->entry(), 42.5));
  EXPECT_EQ(43, CallI(test->entry(), 42.6));
  EXPECT_EQ(43, CallI(test->entry(), 43.0));
  EXPECT_EQ(43, CallI(test->entry(), 43.4));
  EXPECT_EQ(44, CallI(test->entry(), 43.5));
  EXPECT_EQ(44, CallI(test->entry(), 43.6));
}

ASSEMBLER_TEST_GENERATE(ConvertDoubleToDoubleWord_RTZ, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtld(A0, FA0, RTZ);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertDoubleToDoubleWord_RTZ, test) {
  EXPECT_DISASSEMBLY(
      "c2251553 fcvt.l.d a0, fa0, rtz\n"
      "00008067 ret\n");
  EXPECT_EQ(-43, CallI(test->entry(), -43.6));
  EXPECT_EQ(-43, CallI(test->entry(), -43.5));
  EXPECT_EQ(-43, CallI(test->entry(), -43.4));
  EXPECT_EQ(-43, CallI(test->entry(), -43.0));
  EXPECT_EQ(-42, CallI(test->entry(), -42.6));
  EXPECT_EQ(-42, CallI(test->entry(), -42.5));
  EXPECT_EQ(-42, CallI(test->entry(), -42.4));
  EXPECT_EQ(-42, CallI(test->entry(), -42.0));
  EXPECT_EQ(0, CallI(test->entry(), -0.0));
  EXPECT_EQ(0, CallI(test->entry(), +0.0));
  EXPECT_EQ(42, CallI(test->entry(), 42.0));
  EXPECT_EQ(42, CallI(test->entry(), 42.4));
  EXPECT_EQ(42, CallI(test->entry(), 42.5));
  EXPECT_EQ(42, CallI(test->entry(), 42.6));
  EXPECT_EQ(43, CallI(test->entry(), 43.0));
  EXPECT_EQ(43, CallI(test->entry(), 43.4));
  EXPECT_EQ(43, CallI(test->entry(), 43.5));
  EXPECT_EQ(43, CallI(test->entry(), 43.6));
}

ASSEMBLER_TEST_GENERATE(ConvertDoubleToDoubleWord_RDN, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtld(A0, FA0, RDN);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertDoubleToDoubleWord_RDN, test) {
  EXPECT_DISASSEMBLY(
      "c2252553 fcvt.l.d a0, fa0, rdn\n"
      "00008067 ret\n");
  EXPECT_EQ(-44, CallI(test->entry(), -43.6));
  EXPECT_EQ(-44, CallI(test->entry(), -43.5));
  EXPECT_EQ(-44, CallI(test->entry(), -43.4));
  EXPECT_EQ(-43, CallI(test->entry(), -43.0));
  EXPECT_EQ(-43, CallI(test->entry(), -42.6));
  EXPECT_EQ(-43, CallI(test->entry(), -42.5));
  EXPECT_EQ(-43, CallI(test->entry(), -42.4));
  EXPECT_EQ(-42, CallI(test->entry(), -42.0));
  EXPECT_EQ(0, CallI(test->entry(), -0.0));
  EXPECT_EQ(0, CallI(test->entry(), +0.0));
  EXPECT_EQ(42, CallI(test->entry(), 42.0));
  EXPECT_EQ(42, CallI(test->entry(), 42.4));
  EXPECT_EQ(42, CallI(test->entry(), 42.5));
  EXPECT_EQ(42, CallI(test->entry(), 42.6));
  EXPECT_EQ(43, CallI(test->entry(), 43.0));
  EXPECT_EQ(43, CallI(test->entry(), 43.4));
  EXPECT_EQ(43, CallI(test->entry(), 43.5));
  EXPECT_EQ(43, CallI(test->entry(), 43.6));
}

ASSEMBLER_TEST_GENERATE(ConvertDoubleToDoubleWord_RUP, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtld(A0, FA0, RUP);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertDoubleToDoubleWord_RUP, test) {
  EXPECT_DISASSEMBLY(
      "c2253553 fcvt.l.d a0, fa0, rup\n"
      "00008067 ret\n");
  EXPECT_EQ(-43, CallI(test->entry(), -43.6));
  EXPECT_EQ(-43, CallI(test->entry(), -43.5));
  EXPECT_EQ(-43, CallI(test->entry(), -43.4));
  EXPECT_EQ(-43, CallI(test->entry(), -43.0));
  EXPECT_EQ(-42, CallI(test->entry(), -42.6));
  EXPECT_EQ(-42, CallI(test->entry(), -42.5));
  EXPECT_EQ(-42, CallI(test->entry(), -42.4));
  EXPECT_EQ(-42, CallI(test->entry(), -42.0));
  EXPECT_EQ(0, CallI(test->entry(), -0.0));
  EXPECT_EQ(0, CallI(test->entry(), +0.0));
  EXPECT_EQ(42, CallI(test->entry(), 42.0));
  EXPECT_EQ(43, CallI(test->entry(), 42.4));
  EXPECT_EQ(43, CallI(test->entry(), 42.5));
  EXPECT_EQ(43, CallI(test->entry(), 42.6));
  EXPECT_EQ(43, CallI(test->entry(), 43.0));
  EXPECT_EQ(44, CallI(test->entry(), 43.5));
  EXPECT_EQ(44, CallI(test->entry(), 43.5));
  EXPECT_EQ(44, CallI(test->entry(), 43.6));
}

ASSEMBLER_TEST_GENERATE(ConvertDoubleToDoubleWord_RMM, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtld(A0, FA0, RMM);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertDoubleToDoubleWord_RMM, test) {
  EXPECT_DISASSEMBLY(
      "c2254553 fcvt.l.d a0, fa0, rmm\n"
      "00008067 ret\n");
  EXPECT_EQ(-44, CallI(test->entry(), -43.6));
  EXPECT_EQ(-44, CallI(test->entry(), -43.5));
  EXPECT_EQ(-43, CallI(test->entry(), -43.4));
  EXPECT_EQ(-43, CallI(test->entry(), -43.0));
  EXPECT_EQ(-43, CallI(test->entry(), -42.6));
  EXPECT_EQ(-43, CallI(test->entry(), -42.5));
  EXPECT_EQ(-42, CallI(test->entry(), -42.4));
  EXPECT_EQ(-42, CallI(test->entry(), -42.0));
  EXPECT_EQ(0, CallI(test->entry(), -0.0));
  EXPECT_EQ(0, CallI(test->entry(), +0.0));
  EXPECT_EQ(42, CallI(test->entry(), 42.0));
  EXPECT_EQ(42, CallI(test->entry(), 42.4));
  EXPECT_EQ(43, CallI(test->entry(), 42.5));
  EXPECT_EQ(43, CallI(test->entry(), 42.6));
  EXPECT_EQ(43, CallI(test->entry(), 43.0));
  EXPECT_EQ(43, CallI(test->entry(), 43.4));
  EXPECT_EQ(44, CallI(test->entry(), 43.5));
  EXPECT_EQ(44, CallI(test->entry(), 43.6));
}

ASSEMBLER_TEST_GENERATE(ConvertDoubleToUnsignedDoubleWord, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtlud(A0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertDoubleToUnsignedDoubleWord, test) {
  EXPECT_DISASSEMBLY(
      "c2350553 fcvt.lu.d a0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(0, CallI(test->entry(), static_cast<double>(-42)));
  EXPECT_EQ(0, CallI(test->entry(), static_cast<double>(0)));
  EXPECT_EQ(42, CallI(test->entry(), static_cast<double>(42)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(0)),
            CallI(test->entry(), static_cast<double>(kMinInt32)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(kMaxInt32)),
            CallI(test->entry(), static_cast<double>(kMaxInt32)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(kMaxUint32)),
            CallI(test->entry(), static_cast<double>(kMaxUint32)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(0)),
            CallI(test->entry(), static_cast<double>(kMinInt64)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(kMaxInt64) + 1),
            CallI(test->entry(), static_cast<double>(kMaxInt64)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(kMaxUint64)),
            CallI(test->entry(), static_cast<double>(kMaxUint64)));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(0)),
            CallI(test->entry(), -std::numeric_limits<double>::infinity()));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(kMaxUint64)),
            CallI(test->entry(), std::numeric_limits<double>::infinity()));
  EXPECT_EQ(static_cast<int64_t>(static_cast<uint64_t>(kMaxUint64)),
            CallI(test->entry(), std::numeric_limits<double>::signaling_NaN()));
}

ASSEMBLER_TEST_GENERATE(BitCastDoubleToInteger, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmvxd(A0, FA0);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitCastDoubleToInteger, test) {
  EXPECT_DISASSEMBLY(
      "e2050553 fmv.x.d a0, fa0\n"
      "00008067 ret\n");
  EXPECT_EQ(bit_cast<int64_t>(0.0), CallI(test->entry(), 0.0));
  EXPECT_EQ(bit_cast<int64_t>(-0.0), CallI(test->entry(), -0.0));
  EXPECT_EQ(bit_cast<int64_t>(42.0), CallI(test->entry(), 42.0));
  EXPECT_EQ(bit_cast<int64_t>(-42.0), CallI(test->entry(), -42.0));
  EXPECT_EQ(bit_cast<int64_t>(std::numeric_limits<double>::quiet_NaN()),
            CallI(test->entry(), std::numeric_limits<double>::quiet_NaN()));
  EXPECT_EQ(bit_cast<int64_t>(std::numeric_limits<double>::signaling_NaN()),
            CallI(test->entry(), std::numeric_limits<double>::signaling_NaN()));
  EXPECT_EQ(bit_cast<int64_t>(std::numeric_limits<double>::infinity()),
            CallI(test->entry(), std::numeric_limits<double>::infinity()));
  EXPECT_EQ(bit_cast<int64_t>(-std::numeric_limits<double>::infinity()),
            CallI(test->entry(), -std::numeric_limits<double>::infinity()));
}

ASSEMBLER_TEST_GENERATE(ConvertDoubleWordToDouble, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtdl(FA0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertDoubleWordToDouble, test) {
  EXPECT_DISASSEMBLY(
      "d2250553 fcvt.d.l fa0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(0.0, CallD(test->entry(), sign_extend(0)));
  EXPECT_EQ(42.0, CallD(test->entry(), sign_extend(42)));
  EXPECT_EQ(-42.0, CallD(test->entry(), sign_extend(-42)));
  EXPECT_EQ(static_cast<double>(kMinInt32),
            CallD(test->entry(), sign_extend(kMinInt32)));
  EXPECT_EQ(static_cast<double>(kMaxInt32),
            CallD(test->entry(), sign_extend(kMaxInt32)));
  EXPECT_EQ(static_cast<double>(sign_extend(kMaxUint32)),
            CallD(test->entry(), sign_extend(kMaxUint32)));
  EXPECT_EQ(static_cast<double>(kMinInt64),
            CallD(test->entry(), sign_extend(kMinInt64)));
  EXPECT_EQ(static_cast<double>(kMaxInt64),
            CallD(test->entry(), sign_extend(kMaxInt64)));
  EXPECT_EQ(static_cast<double>(sign_extend(kMaxUint64)),
            CallD(test->entry(), sign_extend(kMaxUint64)));
}

ASSEMBLER_TEST_GENERATE(ConvertUnsignedDoubleWordToDouble, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fcvtdlu(FA0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ConvertUnsignedDoubleWordToDouble, test) {
  EXPECT_DISASSEMBLY(
      "d2350553 fcvt.d.lu fa0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(0.0, CallD(test->entry(), sign_extend(0)));
  EXPECT_EQ(42.0, CallD(test->entry(), sign_extend(42)));
  EXPECT_EQ(static_cast<double>(static_cast<uint64_t>(sign_extend(-42))),
            CallD(test->entry(), sign_extend(-42)));
  EXPECT_EQ(static_cast<double>(static_cast<uint64_t>(sign_extend(kMinInt32))),
            CallD(test->entry(), sign_extend(kMinInt32)));
  EXPECT_EQ(static_cast<double>(static_cast<uint64_t>(sign_extend(kMaxInt32))),
            CallD(test->entry(), sign_extend(kMaxInt32)));
  EXPECT_EQ(static_cast<double>(static_cast<uint64_t>(sign_extend(kMaxUint32))),
            CallD(test->entry(), sign_extend(kMaxUint32)));
  EXPECT_EQ(static_cast<double>(static_cast<uint64_t>(sign_extend(kMinInt64))),
            CallD(test->entry(), sign_extend(kMinInt64)));
  EXPECT_EQ(static_cast<double>(static_cast<uint64_t>(sign_extend(kMaxInt64))),
            CallD(test->entry(), sign_extend(kMaxInt64)));
  EXPECT_EQ(static_cast<double>(kMaxUint64),
            CallD(test->entry(), sign_extend(kMaxUint64)));
}

ASSEMBLER_TEST_GENERATE(BitCastIntegerToDouble, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  __ fmvdx(FA0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitCastIntegerToDouble, test) {
  EXPECT_DISASSEMBLY(
      "f2050553 fmv.d.x fa0, a0\n"
      "00008067 ret\n");
  EXPECT_EQ(0.0, CallD(test->entry(), bit_cast<int64_t>(0.0)));
  EXPECT_EQ(-0.0, CallD(test->entry(), bit_cast<int64_t>(-0.0)));
  EXPECT_EQ(42.0, CallD(test->entry(), bit_cast<int64_t>(42.0)));
  EXPECT_EQ(-42.0, CallD(test->entry(), bit_cast<int64_t>(-42.0)));
  EXPECT_EQ(true, isnan(CallD(test->entry(),
                              bit_cast<int64_t>(
                                  std::numeric_limits<double>::quiet_NaN()))));
  EXPECT_EQ(true,
            isnan(CallD(test->entry(),
                        bit_cast<int64_t>(
                            std::numeric_limits<double>::signaling_NaN()))));
  EXPECT_EQ(std::numeric_limits<double>::infinity(),
            CallD(test->entry(),
                  bit_cast<int64_t>(std::numeric_limits<double>::infinity())));
  EXPECT_EQ(-std::numeric_limits<double>::infinity(),
            CallD(test->entry(),
                  bit_cast<int64_t>(-std::numeric_limits<double>::infinity())));
}
#endif

ASSEMBLER_TEST_GENERATE(Fibonacci, assembler) {
  FLAG_use_compressed_instructions = false;
  __ SetExtensions(RV_G);
  Label fib, base, done;
  __ Bind(&fib);
  __ subi(SP, SP, sizeof(uintx_t) * 4);
  __ sx(RA, Address(SP, 3 * sizeof(uintx_t)));
  __ sx(A0, Address(SP, 2 * sizeof(uintx_t)));
  __ subi(A0, A0, 1);
  __ blez(A0, &base);

  __ jal(&fib);
  __ sx(A0, Address(SP, 1 * sizeof(uintx_t)));
  __ lx(A0, Address(SP, 2 * sizeof(uintx_t)));
  __ subi(A0, A0, 2);
  __ jal(&fib);
  __ lx(A1, Address(SP, 1 * sizeof(uintx_t)));
  __ add(A0, A0, A1);
  __ j(&done);

  __ Bind(&base);
  __ li(A0, 1);

  __ Bind(&done);
  __ lx(RA, Address(SP, 3 * sizeof(uintx_t)));
  __ addi(SP, SP, sizeof(uintx_t) * 4);
  __ ret();
  __ trap();
}
ASSEMBLER_TEST_RUN(Fibonacci, test) {
#if XLEN == 32
  EXPECT_DISASSEMBLY(
      "ff010113 addi sp, sp, -16\n"
      "00112623 sw ra, 12(sp)\n"
      "00a12423 sw a0, 8(sp)\n"
      "fff50513 addi a0, a0, -1\n"
      "02a05263 blez a0, +36\n"
      "fedff0ef jal -20\n"
      "00a12223 sw a0, 4(sp)\n"
      "00812503 lw a0, 8(sp)\n"
      "ffe50513 addi a0, a0, -2\n"
      "fddff0ef jal -36\n"
      "00412583 lw a1, 4(sp)\n"
      "00b50533 add a0, a0, a1\n"
      "0080006f j +8\n"
      "00100513 li a0, 1\n"
      "00c12083 lw ra, 12(sp)\n"
      "01010113 addi sp, sp, 16\n"
      "00008067 ret\n"
      "00000000 trap\n");
#elif XLEN == 64
  EXPECT_DISASSEMBLY(
      "fe010113 addi sp, sp, -32\n"
      "00113c23 sd ra, 24(sp)\n"
      "00a13823 sd a0, 16(sp)\n"
      "fff50513 addi a0, a0, -1\n"
      "02a05263 blez a0, +36\n"
      "fedff0ef jal -20\n"
      "00a13423 sd a0, 8(sp)\n"
      "01013503 ld a0, 16(sp)\n"
      "ffe50513 addi a0, a0, -2\n"
      "fddff0ef jal -36\n"
      "00813583 ld a1, 8(sp)\n"
      "00b50533 add a0, a0, a1\n"
      "0080006f j +8\n"
      "00100513 li a0, 1\n"
      "01813083 ld ra, 24(sp)\n"
      "02010113 addi sp, sp, 32\n"
      "00008067 ret\n"
      "00000000 trap\n");
#else
#error Unimplemented
#endif
  EXPECT_EQ(1, Call(test->entry(), 0));
  EXPECT_EQ(1, Call(test->entry(), 1));
  EXPECT_EQ(2, Call(test->entry(), 2));
  EXPECT_EQ(3, Call(test->entry(), 3));
  EXPECT_EQ(5, Call(test->entry(), 4));
  EXPECT_EQ(8, Call(test->entry(), 5));
  EXPECT_EQ(13, Call(test->entry(), 6));
}

ASSEMBLER_TEST_GENERATE(CompressedLoadStoreWordSP_0, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);

  __ subi(SP, SP, 256);
  __ sw(A1, Address(SP, 0));
  __ lw(A0, Address(SP, 0));
  __ addi(SP, SP, 256);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadStoreWordSP_0, test) {
  EXPECT_DISASSEMBLY(
      "    7111 addi sp, sp, -256\n"
      "    c02e sw a1, 0(sp)\n"
      "    4502 lw a0, 0(sp)\n"
      "    6111 addi sp, sp, 256\n"
      "    8082 ret\n");

  EXPECT_EQ(sign_extend(0xAB010203), Call(test->entry(), 0, 0xAB010203));
  EXPECT_EQ(sign_extend(0xCD020405), Call(test->entry(), 0, 0xCD020405));
  EXPECT_EQ(sign_extend(0xEF030607), Call(test->entry(), 0, 0xEF030607));
}
ASSEMBLER_TEST_GENERATE(CompressedLoadStoreWordSP_Pos, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);

  __ subi(SP, SP, 256);
  __ sw(A1, Address(SP, 4));
  __ lw(A0, Address(SP, 4));
  __ addi(SP, SP, 256);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadStoreWordSP_Pos, test) {
  EXPECT_DISASSEMBLY(
      "    7111 addi sp, sp, -256\n"
      "    c22e sw a1, 4(sp)\n"
      "    4512 lw a0, 4(sp)\n"
      "    6111 addi sp, sp, 256\n"
      "    8082 ret\n");

  EXPECT_EQ(sign_extend(0xAB010203), Call(test->entry(), 0, 0xAB010203));
  EXPECT_EQ(sign_extend(0xCD020405), Call(test->entry(), 0, 0xCD020405));
  EXPECT_EQ(sign_extend(0xEF030607), Call(test->entry(), 0, 0xEF030607));
}

#if XLEN == 32
ASSEMBLER_TEST_GENERATE(CompressedLoadStoreSingleFloatSP_0, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ subi(SP, SP, 256);
  __ fsw(FA1, Address(SP, 0));
  __ flw(FA0, Address(SP, 0));
  __ addi(SP, SP, 256);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadStoreSingleFloatSP_0, test) {
  EXPECT_DISASSEMBLY(
      "    7111 addi sp, sp, -256\n"
      "    e02e fsw fa1, 0(sp)\n"
      "    6502 flw fa0, 0(sp)\n"
      "    6111 addi sp, sp, 256\n"
      "    8082 ret\n");

  EXPECT_EQ(1.7f, CallF(test->entry(), 0.0f, 1.7f));
  EXPECT_EQ(2.8f, CallF(test->entry(), 0.0f, 2.8f));
  EXPECT_EQ(3.9f, CallF(test->entry(), 0.0f, 3.9f));
}

ASSEMBLER_TEST_GENERATE(CompressedLoadStoreSingleFloatSP_Pos, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ subi(SP, SP, 256);
  __ fsw(FA1, Address(SP, 4));
  __ flw(FA0, Address(SP, 4));
  __ addi(SP, SP, 256);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadStoreSingleFloatSP_Pos, test) {
  EXPECT_DISASSEMBLY(
      "    7111 addi sp, sp, -256\n"
      "    e22e fsw fa1, 4(sp)\n"
      "    6512 flw fa0, 4(sp)\n"
      "    6111 addi sp, sp, 256\n"
      "    8082 ret\n");

  EXPECT_EQ(1.7f, CallF(test->entry(), 0.0f, 1.7f));
  EXPECT_EQ(2.8f, CallF(test->entry(), 0.0f, 2.8f));
  EXPECT_EQ(3.9f, CallF(test->entry(), 0.0f, 3.9f));
}
#endif

ASSEMBLER_TEST_GENERATE(CompressedLoadStoreDoubleFloatSP_0, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ subi(SP, SP, 256);
  __ fsd(FA1, Address(SP, 0));
  __ fld(FA0, Address(SP, 0));
  __ addi(SP, SP, 256);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadStoreDoubleFloatSP_0, test) {
  EXPECT_DISASSEMBLY(
      "    7111 addi sp, sp, -256\n"
      "    a02e fsd fa1, 0(sp)\n"
      "    2502 fld fa0, 0(sp)\n"
      "    6111 addi sp, sp, 256\n"
      "    8082 ret\n");

  EXPECT_EQ(1.7, CallD(test->entry(), 0.0, 1.7));
  EXPECT_EQ(2.8, CallD(test->entry(), 0.0, 2.8));
  EXPECT_EQ(3.9, CallD(test->entry(), 0.0, 3.9));
}
ASSEMBLER_TEST_GENERATE(CompressedLoadStoreDoubleFloatSP_Pos, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ subi(SP, SP, 256);
  __ fsd(FA1, Address(SP, 8));
  __ fld(FA0, Address(SP, 8));
  __ addi(SP, SP, 256);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadStoreDoubleFloatSP_Pos, test) {
  EXPECT_DISASSEMBLY(
      "    7111 addi sp, sp, -256\n"
      "    a42e fsd fa1, 8(sp)\n"
      "    2522 fld fa0, 8(sp)\n"
      "    6111 addi sp, sp, 256\n"
      "    8082 ret\n");

  EXPECT_EQ(1.7, CallD(test->entry(), 0.0, 1.7));
  EXPECT_EQ(2.8, CallD(test->entry(), 0.0, 2.8));
  EXPECT_EQ(3.9, CallD(test->entry(), 0.0, 3.9));
}

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(CompressedLoadStoreDoubleWordSP_0, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ subi(SP, SP, 256);
  __ sd(A1, Address(SP, 0));
  __ ld(A0, Address(SP, 0));
  __ addi(SP, SP, 256);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadStoreDoubleWordSP_0, test) {
  EXPECT_DISASSEMBLY(
      "    7111 addi sp, sp, -256\n"
      "    e02e sd a1, 0(sp)\n"
      "    6502 ld a0, 0(sp)\n"
      "    6111 addi sp, sp, 256\n"
      "    8082 ret\n");

  EXPECT_EQ((intx_t)0xAB01020304050607,
            Call(test->entry(), 0, 0xAB01020304050607));
  EXPECT_EQ((intx_t)0xCD02040505060708,
            Call(test->entry(), 0, 0xCD02040505060708));
  EXPECT_EQ((intx_t)0xEF03060708090A0B,
            Call(test->entry(), 0, 0xEF03060708090A0B));
}
ASSEMBLER_TEST_GENERATE(CompressedLoadStoreDoubleWordSP_Pos, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ subi(SP, SP, 256);
  __ sd(A1, Address(SP, 8));
  __ ld(A0, Address(SP, 8));
  __ addi(SP, SP, 256);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadStoreDoubleWordSP_Pos, test) {
  EXPECT_DISASSEMBLY(
      "    7111 addi sp, sp, -256\n"
      "    e42e sd a1, 8(sp)\n"
      "    6522 ld a0, 8(sp)\n"
      "    6111 addi sp, sp, 256\n"
      "    8082 ret\n");

  EXPECT_EQ((intx_t)0xAB01020304050607,
            Call(test->entry(), 0, 0xAB01020304050607));
  EXPECT_EQ((intx_t)0xCD02040505060708,
            Call(test->entry(), 0, 0xCD02040505060708));
  EXPECT_EQ((intx_t)0xEF03060708090A0B,
            Call(test->entry(), 0, 0xEF03060708090A0B));
}
#endif

ASSEMBLER_TEST_GENERATE(CompressedLoadWord_0, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ lw(A0, Address(A0, 0));
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadWord_0, test) {
  EXPECT_DISASSEMBLY(
      "    4108 lw a0, 0(a0)\n"
      "    8082 ret\n");

  uint32_t* values = reinterpret_cast<uint32_t*>(malloc(3 * sizeof(uint32_t)));
  values[0] = 0xAB010203;
  values[1] = 0xCD020405;
  values[2] = 0xEF030607;

  EXPECT_EQ(-855505915,
            Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}
ASSEMBLER_TEST_GENERATE(CompressedLoadWord_Pos, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ lw(A0, Address(A0, 4));
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadWord_Pos, test) {
  EXPECT_DISASSEMBLY(
      "    4148 lw a0, 4(a0)\n"
      "    8082 ret\n");

  uint32_t* values = reinterpret_cast<uint32_t*>(malloc(3 * sizeof(uint32_t)));
  values[0] = 0xAB010203;
  values[1] = 0xCD020405;
  values[2] = 0xEF030607;

  EXPECT_EQ(-285014521,
            Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}

ASSEMBLER_TEST_GENERATE(CompressedStoreWord_0, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ sw(A1, Address(A0, 0));
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedStoreWord_0, test) {
  EXPECT_DISASSEMBLY(
      "    c10c sw a1, 0(a0)\n"
      "    8082 ret\n");

  uint32_t* values = reinterpret_cast<uint32_t*>(malloc(3 * sizeof(uint32_t)));
  values[0] = 0;
  values[1] = 0;
  values[2] = 0;

  Call(test->entry(), reinterpret_cast<intx_t>(&values[1]), 0xCD020405);
  EXPECT_EQ(0u, values[0]);
  EXPECT_EQ(0xCD020405, values[1]);
  EXPECT_EQ(0u, values[2]);
}
ASSEMBLER_TEST_GENERATE(CompressedStoreWord_Pos, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ sw(A1, Address(A0, 4));
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedStoreWord_Pos, test) {
  EXPECT_DISASSEMBLY(
      "    c14c sw a1, 4(a0)\n"
      "    8082 ret\n");

  uint32_t* values = reinterpret_cast<uint32_t*>(malloc(3 * sizeof(uint32_t)));
  values[0] = 0;
  values[1] = 0;
  values[2] = 0;

  Call(test->entry(), reinterpret_cast<intx_t>(&values[1]), 0xEF030607);
  EXPECT_EQ(0u, values[0]);
  EXPECT_EQ(0u, values[1]);
  EXPECT_EQ(0xEF030607, values[2]);
}

#if XLEN == 32
ASSEMBLER_TEST_GENERATE(CompressedLoadSingleFloat, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ flw(FA0, Address(A0, 1 * sizeof(float)));
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadSingleFloat, test) {
  EXPECT_DISASSEMBLY(
      "    6148 flw fa0, 4(a0)\n"
      "    8082 ret\n");

  float* data = reinterpret_cast<float*>(malloc(3 * sizeof(float)));
  data[0] = 1.7f;
  data[1] = 2.8f;
  data[2] = 3.9f;
  EXPECT_EQ(data[1], CallF(test->entry(), reinterpret_cast<intx_t>(data)));
}

ASSEMBLER_TEST_GENERATE(CompressedStoreSingleFloat, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ fsw(FA0, Address(A0, 1 * sizeof(float)));
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedStoreSingleFloat, test) {
  EXPECT_DISASSEMBLY(
      "    e148 fsw fa0, 4(a0)\n"
      "    8082 ret\n");

  float* data = reinterpret_cast<float*>(malloc(3 * sizeof(float)));
  data[0] = 1.7f;
  data[1] = 2.8f;
  data[2] = 3.9f;
  CallF(test->entry(), reinterpret_cast<intx_t>(data), 4.2f);
  EXPECT_EQ(4.2f, data[1]);
}
#endif

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(CompressedLoadDoubleWord_0, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ ld(A0, Address(A0, 0));
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadDoubleWord_0, test) {
  EXPECT_DISASSEMBLY(
      "    6108 ld a0, 0(a0)\n"
      "    8082 ret\n");

  uint64_t* values = reinterpret_cast<uint64_t*>(malloc(3 * sizeof(uint64_t)));
  values[0] = 0xAB01020304050607;
  values[1] = 0xCD02040505060708;
  values[2] = 0xEF03060708090A0B;

  EXPECT_EQ(-3674369926375274744,
            Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}
ASSEMBLER_TEST_GENERATE(CompressedLoadDoubleWord_Pos, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ ld(A0, Address(A0, 8));
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadDoubleWord_Pos, test) {
  EXPECT_DISASSEMBLY(
      "    6508 ld a0, 8(a0)\n"
      "    8082 ret\n");

  uint64_t* values = reinterpret_cast<uint64_t*>(malloc(3 * sizeof(uint64_t)));
  values[0] = 0xAB01020304050607;
  values[1] = 0xCD02040505060708;
  values[2] = 0xEF03060708090A0B;

  EXPECT_EQ(-1224128046445295093,
            Call(test->entry(), reinterpret_cast<intx_t>(&values[1])));
}

ASSEMBLER_TEST_GENERATE(CompressedStoreDoubleWord_0, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ sd(A1, Address(A0, 0));
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedStoreDoubleWord_0, test) {
  EXPECT_DISASSEMBLY(
      "    e10c sd a1, 0(a0)\n"
      "    8082 ret\n");

  uint64_t* values = reinterpret_cast<uint64_t*>(malloc(3 * sizeof(uint64_t)));
  values[0] = 0;
  values[1] = 0;
  values[2] = 0;

  Call(test->entry(), reinterpret_cast<intx_t>(&values[1]), 0xCD02040505060708);
  EXPECT_EQ(0u, values[0]);
  EXPECT_EQ(0xCD02040505060708, values[1]);
  EXPECT_EQ(0u, values[2]);
}
ASSEMBLER_TEST_GENERATE(CompressedStoreDoubleWord_Pos, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ sd(A1, Address(A0, 8));
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedStoreDoubleWord_Pos, test) {
  EXPECT_DISASSEMBLY(
      "    e50c sd a1, 8(a0)\n"
      "    8082 ret\n");

  uint64_t* values = reinterpret_cast<uint64_t*>(malloc(3 * sizeof(uint64_t)));
  values[0] = 0;
  values[1] = 0;
  values[2] = 0;

  Call(test->entry(), reinterpret_cast<intx_t>(&values[1]), 0xEF03060708090A0B);
  EXPECT_EQ(0u, values[0]);
  EXPECT_EQ(0u, values[1]);
  EXPECT_EQ(0xEF03060708090A0B, values[2]);
}

ASSEMBLER_TEST_GENERATE(CompressedLoadDoubleFloat, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ fld(FA0, Address(A0, 1 * sizeof(double)));
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadDoubleFloat, test) {
  EXPECT_DISASSEMBLY(
      "    2508 fld fa0, 8(a0)\n"
      "    8082 ret\n");

  double* data = reinterpret_cast<double*>(malloc(3 * sizeof(double)));
  data[0] = 1.7;
  data[1] = 2.8;
  data[2] = 3.9;
  EXPECT_EQ(data[1], CallD(test->entry(), reinterpret_cast<intx_t>(data)));
  free(data);
}

ASSEMBLER_TEST_GENERATE(CompressedStoreDoubleFloat, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ fsd(FA0, Address(A0, 1 * sizeof(double)));
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedStoreDoubleFloat, test) {
  EXPECT_DISASSEMBLY(
      "    a508 fsd fa0, 8(a0)\n"
      "    8082 ret\n");

  double* data = reinterpret_cast<double*>(malloc(3 * sizeof(double)));
  data[0] = 1.7;
  data[1] = 2.8;
  data[2] = 3.9;
  CallD(test->entry(), reinterpret_cast<intx_t>(data), 4.2);
  EXPECT_EQ(4.2, data[1]);
}
#endif

#if XLEN == 32
ASSEMBLER_TEST_GENERATE(CompressedJumpAndLink, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);

  Label label1, label2;
  __ mv(T3, RA);
  __ jal(&label1, Assembler::kNearJump);  // Forward.
  __ sub(A0, T0, T1);
  __ mv(RA, T3);
  __ ret();
  __ trap();

  __ Bind(&label2);
  __ mv(T5, RA);
  __ li(T1, 7);
  __ jr(T5);
  __ trap();

  __ Bind(&label1);
  __ mv(T4, RA);
  __ li(T0, 4);
  __ jal(&label2, Assembler::kNearJump);  // Backward.
  __ mv(RA, T4);
  __ jr(T4);
  __ trap();
}
ASSEMBLER_TEST_RUN(CompressedJumpAndLink, test) {
  EXPECT_DISASSEMBLY(
      "    8e06 mv t3, ra\n"
      "    2811 jal +20\n"
      "40628533 sub a0, t0, t1\n"
      "    80f2 mv ra, t3\n"
      "    8082 ret\n"
      "    0000 trap\n"
      "    8f06 mv t5, ra\n"
      "    431d li t1, 7\n"
      "    8f02 jr t5\n"
      "    0000 trap\n"
      "    8e86 mv t4, ra\n"
      "    4291 li t0, 4\n"
      "    3fd5 jal -12\n"
      "    80f6 mv ra, t4\n"
      "    8e82 jr t4\n"
      "    0000 trap\n");
  EXPECT_EQ(-3, Call(test->entry()));
}
#endif

ASSEMBLER_TEST_GENERATE(CompressedJump, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  Label label1, label2;
  __ j(&label1, Assembler::kNearJump);  // Forward.
  __ trap();
  __ Bind(&label2);
  __ li(T1, 7);
  __ sub(A0, T0, T1);
  __ ret();
  __ Bind(&label1);
  __ li(T0, 4);
  __ j(&label2, Assembler::kNearJump);  // Backward.
  __ trap();
}
ASSEMBLER_TEST_RUN(CompressedJump, test) {
  EXPECT_DISASSEMBLY(
      "    a031 j +12\n"
      "    0000 trap\n"
      "    431d li t1, 7\n"
      "40628533 sub a0, t0, t1\n"
      "    8082 ret\n"
      "    4291 li t0, 4\n"
      "    bfdd j -10\n"
      "    0000 trap\n");
  EXPECT_EQ(-3, Call(test->entry()));
}

static int CompressedJumpAndLinkRegister_label1 = 0;
static int CompressedJumpAndLinkRegister_label2 = 0;
ASSEMBLER_TEST_GENERATE(CompressedJumpAndLinkRegister, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  Label label1, label2;
  __ mv(T3, RA);
  __ jalr(A1);  // Forward.
  __ sub(A0, T0, T1);
  __ jr(T3);
  __ trap();

  __ Bind(&label2);
  __ mv(T5, RA);
  __ li(T1, 7);
  __ jr(T5);
  __ trap();

  __ Bind(&label1);
  __ mv(T4, RA);
  __ li(T0, 4);
  __ jalr(A2);  // Backward.
  __ jr(T4);
  __ trap();

  CompressedJumpAndLinkRegister_label1 = label1.Position();
  CompressedJumpAndLinkRegister_label2 = label2.Position();
}
ASSEMBLER_TEST_RUN(CompressedJumpAndLinkRegister, test) {
  EXPECT_DISASSEMBLY(
      "    8e06 mv t3, ra\n"
      "    9582 jalr a1\n"
      "40628533 sub a0, t0, t1\n"
      "    8e02 jr t3\n"
      "    0000 trap\n"
      "    8f06 mv t5, ra\n"
      "    431d li t1, 7\n"
      "    8f02 jr t5\n"
      "    0000 trap\n"
      "    8e86 mv t4, ra\n"
      "    4291 li t0, 4\n"
      "    9602 jalr a2\n"
      "    8e82 jr t4\n"
      "    0000 trap\n");
  EXPECT_EQ(-3,
            Call(test->entry(), 0,
                 static_cast<intx_t>(test->entry() +
                                     CompressedJumpAndLinkRegister_label1),
                 static_cast<intx_t>(test->entry() +
                                     CompressedJumpAndLinkRegister_label2)));
}

static int CompressedJumpRegister_label = 0;
ASSEMBLER_TEST_GENERATE(CompressedJumpRegister, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  Label label;
  __ jr(A1);
  __ trap();
  __ Bind(&label);
  __ li(A0, 42);
  __ ret();
  CompressedJumpRegister_label = label.Position();
}
ASSEMBLER_TEST_RUN(CompressedJumpRegister, test) {
  EXPECT_DISASSEMBLY(
      "    8582 jr a1\n"
      "    0000 trap\n"
      "02a00513 li a0, 42\n"
      "    8082 ret\n");
  EXPECT_EQ(42, Call(test->entry(), 0,
                     static_cast<intx_t>(test->entry() +
                                         CompressedJumpRegister_label)));
}

ASSEMBLER_TEST_GENERATE(CompressedBranchEqualZero, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  Label label;
  __ beqz(A0, &label, Assembler::kNearJump);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedBranchEqualZero, test) {
  EXPECT_DISASSEMBLY(
      "    c119 beqz a0, +6\n"
      "    450d li a0, 3\n"
      "    8082 ret\n"
      "    4511 li a0, 4\n"
      "    8082 ret\n");
  EXPECT_EQ(3, Call(test->entry(), -42));
  EXPECT_EQ(4, Call(test->entry(), 0));
  EXPECT_EQ(3, Call(test->entry(), 42));
}

ASSEMBLER_TEST_GENERATE(CompressedBranchNotEqualZero, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  Label label;
  __ bnez(A0, &label, Assembler::kNearJump);
  __ li(A0, 3);
  __ ret();
  __ Bind(&label);
  __ li(A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedBranchNotEqualZero, test) {
  EXPECT_DISASSEMBLY(
      "    e119 bnez a0, +6\n"
      "    450d li a0, 3\n"
      "    8082 ret\n"
      "    4511 li a0, 4\n"
      "    8082 ret\n");
  EXPECT_EQ(4, Call(test->entry(), -42));
  EXPECT_EQ(3, Call(test->entry(), 0));
  EXPECT_EQ(4, Call(test->entry(), 42));
}

ASSEMBLER_TEST_GENERATE(CompressedLoadImmediate, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ li(A0, -7);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadImmediate, test) {
  EXPECT_DISASSEMBLY(
      "    5565 li a0, -7\n"
      "    8082 ret\n");
  EXPECT_EQ(-7, Call(test->entry()));
}

ASSEMBLER_TEST_GENERATE(CompressedLoadUpperImmediate, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ lui(A0, 7 << 12);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedLoadUpperImmediate, test) {
  EXPECT_DISASSEMBLY(
      "    651d lui a0, 28672\n"
      "    8082 ret\n");
  EXPECT_EQ(7 << 12, Call(test->entry()));
}

ASSEMBLER_TEST_GENERATE(CompressedAddImmediate, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ addi(A0, A0, 19);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedAddImmediate, test) {
  EXPECT_DISASSEMBLY(
      "    054d addi a0, a0, 19\n"
      "    8082 ret\n");
  EXPECT_EQ(42, Call(test->entry(), 23));
}

#if XLEN == 64
ASSEMBLER_TEST_GENERATE(CompressedAddImmediateWord, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ addiw(A0, A0, 19);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedAddImmediateWord, test) {
  EXPECT_DISASSEMBLY(
      "    254d addiw a0, a0, 19\n"
      "    8082 ret\n");
  EXPECT_EQ(19, Call(test->entry(), 0xFFFFFFFF00000000));
  EXPECT_EQ(-237, Call(test->entry(), 0x00000000FFFFFF00));
}
#endif

ASSEMBLER_TEST_GENERATE(CompressedAddImmediateSP16, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ addi(SP, SP, -128);
  __ addi(SP, SP, +128);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedAddImmediateSP16, test) {
  EXPECT_DISASSEMBLY(
      "    7119 addi sp, sp, -128\n"
      "    6109 addi sp, sp, 128\n"
      "    8082 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 0));
}

ASSEMBLER_TEST_GENERATE(CompressedAddImmediateSP4N, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ addi(A1, SP, 36);
  __ sub(A0, A1, SP);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedAddImmediateSP4N, test) {
  EXPECT_DISASSEMBLY(
      "    104c addi a1, sp, 36\n"
      "40258533 sub a0, a1, sp\n"
      "    8082 ret\n");
  EXPECT_EQ(36, Call(test->entry()));
}

ASSEMBLER_TEST_GENERATE(CompressedShiftLeftLogicalImmediate, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ slli(A0, A0, 3);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedShiftLeftLogicalImmediate, test) {
  EXPECT_DISASSEMBLY(
      "    050e slli a0, a0, 3\n"
      "    8082 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(336, Call(test->entry(), 42));
  EXPECT_EQ(15872, Call(test->entry(), 1984));
  EXPECT_EQ(-336, Call(test->entry(), -42));
  EXPECT_EQ(-15872, Call(test->entry(), -1984));
}

ASSEMBLER_TEST_GENERATE(CompressedShiftRightLogicalImmediate, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ srli(A0, A0, 3);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedShiftRightLogicalImmediate, test) {
  EXPECT_DISASSEMBLY(
      "    810d srli a0, a0, 3\n"
      "    8082 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(5, Call(test->entry(), 42));
  EXPECT_EQ(248, Call(test->entry(), 1984));
  EXPECT_EQ(static_cast<intx_t>(static_cast<uintx_t>(-42) >> 3),
            Call(test->entry(), -42));
  EXPECT_EQ(static_cast<intx_t>(static_cast<uintx_t>(-1984) >> 3),
            Call(test->entry(), -1984));
}

ASSEMBLER_TEST_GENERATE(CompressedShiftRightArithmeticImmediate, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ srai(A0, A0, 3);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedShiftRightArithmeticImmediate, test) {
  EXPECT_DISASSEMBLY(
      "    850d srai a0, a0, 3\n"
      "    8082 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(5, Call(test->entry(), 42));
  EXPECT_EQ(248, Call(test->entry(), 1984));
  EXPECT_EQ(-6, Call(test->entry(), -42));
  EXPECT_EQ(-248, Call(test->entry(), -1984));
}

ASSEMBLER_TEST_GENERATE(CompressedAndImmediate, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ andi(A0, A0, 6);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedAndImmediate, test) {
  EXPECT_DISASSEMBLY(
      "    8919 andi a0, a0, 6\n"
      "    8082 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(2, Call(test->entry(), 43));
  EXPECT_EQ(0, Call(test->entry(), 1984));
  EXPECT_EQ(6, Call(test->entry(), -42));
  EXPECT_EQ(0, Call(test->entry(), -1984));
}

ASSEMBLER_TEST_GENERATE(CompressedAndImmediate2, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ andi(A0, A0, -6);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedAndImmediate2, test) {
  EXPECT_DISASSEMBLY(
      "    9969 andi a0, a0, -6\n"
      "    8082 ret\n");
  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(42, Call(test->entry(), 43));
  EXPECT_EQ(1984, Call(test->entry(), 1984));
  EXPECT_EQ(-46, Call(test->entry(), -42));
  EXPECT_EQ(-1984, Call(test->entry(), -1984));
}

ASSEMBLER_TEST_GENERATE(CompressedMove, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ mv(A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedMove, test) {
  EXPECT_DISASSEMBLY(
      "    852e mv a0, a1\n"
      "    8082 ret\n");
  EXPECT_EQ(42, Call(test->entry(), 0, 42));
}

ASSEMBLER_TEST_GENERATE(CompressedAdd, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ add(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedAdd, test) {
  EXPECT_DISASSEMBLY(
      "    952e add a0, a0, a1\n"
      "    8082 ret\n");
  EXPECT_EQ(24, Call(test->entry(), 7, 17));
  EXPECT_EQ(-10, Call(test->entry(), 7, -17));
  EXPECT_EQ(10, Call(test->entry(), -7, 17));
  EXPECT_EQ(-24, Call(test->entry(), -7, -17));
  EXPECT_EQ(24, Call(test->entry(), 17, 7));
  EXPECT_EQ(10, Call(test->entry(), 17, -7));
  EXPECT_EQ(-10, Call(test->entry(), -17, 7));
  EXPECT_EQ(-24, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(CompressedAnd, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ and_(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedAnd, test) {
  EXPECT_DISASSEMBLY(
      "    8d6d and a0, a0, a1\n"
      "    8082 ret\n");
  EXPECT_EQ(1, Call(test->entry(), 7, 17));
  EXPECT_EQ(7, Call(test->entry(), 7, -17));
  EXPECT_EQ(17, Call(test->entry(), -7, 17));
  EXPECT_EQ(-23, Call(test->entry(), -7, -17));
  EXPECT_EQ(1, Call(test->entry(), 17, 7));
  EXPECT_EQ(17, Call(test->entry(), 17, -7));
  EXPECT_EQ(7, Call(test->entry(), -17, 7));
  EXPECT_EQ(-23, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(CompressedOr, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ or_(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedOr, test) {
  EXPECT_DISASSEMBLY(
      "    8d4d or a0, a0, a1\n"
      "    8082 ret\n");
  EXPECT_EQ(23, Call(test->entry(), 7, 17));
  EXPECT_EQ(-17, Call(test->entry(), 7, -17));
  EXPECT_EQ(-7, Call(test->entry(), -7, 17));
  EXPECT_EQ(-1, Call(test->entry(), -7, -17));
  EXPECT_EQ(23, Call(test->entry(), 17, 7));
  EXPECT_EQ(-7, Call(test->entry(), 17, -7));
  EXPECT_EQ(-17, Call(test->entry(), -17, 7));
  EXPECT_EQ(-1, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(CompressedXor, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ xor_(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedXor, test) {
  EXPECT_DISASSEMBLY(
      "    8d2d xor a0, a0, a1\n"
      "    8082 ret\n");
  EXPECT_EQ(22, Call(test->entry(), 7, 17));
  EXPECT_EQ(-24, Call(test->entry(), 7, -17));
  EXPECT_EQ(-24, Call(test->entry(), -7, 17));
  EXPECT_EQ(22, Call(test->entry(), -7, -17));
  EXPECT_EQ(22, Call(test->entry(), 17, 7));
  EXPECT_EQ(-24, Call(test->entry(), 17, -7));
  EXPECT_EQ(-24, Call(test->entry(), -17, 7));
  EXPECT_EQ(22, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(CompressedSubtract, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ sub(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedSubtract, test) {
  EXPECT_DISASSEMBLY(
      "    8d0d sub a0, a0, a1\n"
      "    8082 ret\n");
  EXPECT_EQ(-10, Call(test->entry(), 7, 17));
  EXPECT_EQ(24, Call(test->entry(), 7, -17));
  EXPECT_EQ(-24, Call(test->entry(), -7, 17));
  EXPECT_EQ(10, Call(test->entry(), -7, -17));
  EXPECT_EQ(10, Call(test->entry(), 17, 7));
  EXPECT_EQ(24, Call(test->entry(), 17, -7));
  EXPECT_EQ(-24, Call(test->entry(), -17, 7));
  EXPECT_EQ(-10, Call(test->entry(), -17, -7));
}

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(CompressedAddWord, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ addw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedAddWord, test) {
  EXPECT_DISASSEMBLY(
      "    9d2d addw a0, a0, a1\n"
      "    8082 ret\n");
  EXPECT_EQ(24, Call(test->entry(), 7, 17));
  EXPECT_EQ(-10, Call(test->entry(), 7, -17));
  EXPECT_EQ(10, Call(test->entry(), -7, 17));
  EXPECT_EQ(-24, Call(test->entry(), -7, -17));
  EXPECT_EQ(24, Call(test->entry(), 17, 7));
  EXPECT_EQ(10, Call(test->entry(), 17, -7));
  EXPECT_EQ(-10, Call(test->entry(), -17, 7));
  EXPECT_EQ(-24, Call(test->entry(), -17, -7));
  EXPECT_EQ(3, Call(test->entry(), 0x200000002, 0x100000001));
}

ASSEMBLER_TEST_GENERATE(CompressedSubtractWord, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ subw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedSubtractWord, test) {
  EXPECT_DISASSEMBLY(
      "    9d0d subw a0, a0, a1\n"
      "    8082 ret\n");
  EXPECT_EQ(-10, Call(test->entry(), 7, 17));
  EXPECT_EQ(24, Call(test->entry(), 7, -17));
  EXPECT_EQ(-24, Call(test->entry(), -7, 17));
  EXPECT_EQ(10, Call(test->entry(), -7, -17));
  EXPECT_EQ(10, Call(test->entry(), 17, 7));
  EXPECT_EQ(24, Call(test->entry(), 17, -7));
  EXPECT_EQ(-24, Call(test->entry(), -17, 7));
  EXPECT_EQ(-10, Call(test->entry(), -17, -7));
  EXPECT_EQ(1, Call(test->entry(), 0x200000002, 0x100000001));
}
#endif

ASSEMBLER_TEST_GENERATE(CompressedNop, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ nop();
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedNop, test) {
  EXPECT_DISASSEMBLY(
      "    0001 nop\n"
      "    8082 ret\n");
  EXPECT_EQ(123, Call(test->entry(), 123));
}

ASSEMBLER_TEST_GENERATE(CompressedEnvironmentBreak, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ ebreak();
  __ ret();
}
ASSEMBLER_TEST_RUN(CompressedEnvironmentBreak, test) {
  EXPECT_DISASSEMBLY(
      "    9002 ebreak\n"
      "    8082 ret\n");

  // Not running: would trap.
}

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(AddUnsignedWord, assembler) {
  __ SetExtensions(RV_GCB);
  __ adduw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(AddUnsignedWord, test) {
  EXPECT_DISASSEMBLY(
      "08b5053b add.uw a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(0x200000001, Call(test->entry(), 0x1, 0x200000000));
  EXPECT_EQ(0x200000001, Call(test->entry(), 0x100000001, 0x200000000));
  EXPECT_EQ(0x2FFFFFFFF, Call(test->entry(), -0x1, 0x200000000));
}
#endif

ASSEMBLER_TEST_GENERATE(Shift1Add, assembler) {
  __ SetExtensions(RV_GCB);
  __ sh1add(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Shift1Add, test) {
  EXPECT_DISASSEMBLY(
      "20b52533 sh1add a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(1002, Call(test->entry(), 1, 1000));
  EXPECT_EQ(1000, Call(test->entry(), 0, 1000));
  EXPECT_EQ(998, Call(test->entry(), -1, 1000));
}

ASSEMBLER_TEST_GENERATE(Shift2Add, assembler) {
  __ SetExtensions(RV_GCB);
  __ sh2add(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Shift2Add, test) {
  EXPECT_DISASSEMBLY(
      "20b54533 sh2add a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(1004, Call(test->entry(), 1, 1000));
  EXPECT_EQ(1000, Call(test->entry(), 0, 1000));
  EXPECT_EQ(996, Call(test->entry(), -1, 1000));
}

ASSEMBLER_TEST_GENERATE(Shift3Add, assembler) {
  __ SetExtensions(RV_GCB);
  __ sh3add(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Shift3Add, test) {
  EXPECT_DISASSEMBLY(
      "20b56533 sh3add a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(1008, Call(test->entry(), 1, 1000));
  EXPECT_EQ(1000, Call(test->entry(), 0, 1000));
  EXPECT_EQ(992, Call(test->entry(), -1, 1000));
}

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(Shift1AddUnsignedWord, assembler) {
  __ SetExtensions(RV_GCB);
  __ sh1adduw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Shift1AddUnsignedWord, test) {
  EXPECT_DISASSEMBLY(
      "20b5253b sh1add.uw a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(1002, Call(test->entry(), 1, 1000));
  EXPECT_EQ(1002, Call(test->entry(), 0x100000001, 1000));
  EXPECT_EQ(1000, Call(test->entry(), 0, 1000));
  EXPECT_EQ(8589935590, Call(test->entry(), -1, 1000));
}

ASSEMBLER_TEST_GENERATE(Shift2AddUnsignedWord, assembler) {
  __ SetExtensions(RV_GCB);
  __ sh2adduw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Shift2AddUnsignedWord, test) {
  EXPECT_DISASSEMBLY(
      "20b5453b sh2add.uw a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(1004, Call(test->entry(), 1, 1000));
  EXPECT_EQ(1004, Call(test->entry(), 0x100000001, 1000));
  EXPECT_EQ(1000, Call(test->entry(), 0, 1000));
  EXPECT_EQ(17179870180, Call(test->entry(), -1, 1000));
}

ASSEMBLER_TEST_GENERATE(Shift3AddUnsignedWord, assembler) {
  __ SetExtensions(RV_GCB);
  __ sh3adduw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Shift3AddUnsignedWord, test) {
  EXPECT_DISASSEMBLY(
      "20b5653b sh3add.uw a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(1008, Call(test->entry(), 1, 1000));
  EXPECT_EQ(1008, Call(test->entry(), 0x100000001, 1000));
  EXPECT_EQ(1000, Call(test->entry(), 0, 1000));
  EXPECT_EQ(34359739360, Call(test->entry(), -1, 1000));
}

ASSEMBLER_TEST_GENERATE(ShiftLeftLogicalImmediateUnsignedWord, assembler) {
  __ SetExtensions(RV_GCB);
  __ slliuw(A0, A0, 8);
  __ ret();
}
ASSEMBLER_TEST_RUN(ShiftLeftLogicalImmediateUnsignedWord, test) {
  EXPECT_DISASSEMBLY(
      "0885151b slli.uw a0, a0, 0x8\n"
      "    8082 ret\n");

  EXPECT_EQ(0x100, Call(test->entry(), 0x1));
  EXPECT_EQ(0x1000000000, Call(test->entry(), 0x10000000));
  EXPECT_EQ(0, Call(test->entry(), 0x100000000));
  EXPECT_EQ(0x100, Call(test->entry(), 0x100000001));
}
#endif

ASSEMBLER_TEST_GENERATE(AndNot, assembler) {
  __ SetExtensions(RV_GCB);
  __ andn(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(AndNot, test) {
  EXPECT_DISASSEMBLY(
      "40b57533 andn a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(6, Call(test->entry(), 7, 17));
  EXPECT_EQ(0, Call(test->entry(), 7, -17));
  EXPECT_EQ(-24, Call(test->entry(), -7, 17));
  EXPECT_EQ(16, Call(test->entry(), -7, -17));
  EXPECT_EQ(16, Call(test->entry(), 17, 7));
  EXPECT_EQ(0, Call(test->entry(), 17, -7));
  EXPECT_EQ(-24, Call(test->entry(), -17, 7));
  EXPECT_EQ(6, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(OrNot, assembler) {
  __ SetExtensions(RV_GCB);
  __ orn(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(OrNot, test) {
  EXPECT_DISASSEMBLY(
      "40b56533 orn a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(-17, Call(test->entry(), 7, 17));
  EXPECT_EQ(23, Call(test->entry(), 7, -17));
  EXPECT_EQ(-1, Call(test->entry(), -7, 17));
  EXPECT_EQ(-7, Call(test->entry(), -7, -17));
  EXPECT_EQ(-7, Call(test->entry(), 17, 7));
  EXPECT_EQ(23, Call(test->entry(), 17, -7));
  EXPECT_EQ(-1, Call(test->entry(), -17, 7));
  EXPECT_EQ(-17, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(XorNot, assembler) {
  __ SetExtensions(RV_GCB);
  __ xnor(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(XorNot, test) {
  EXPECT_DISASSEMBLY(
      "40b54533 xnor a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(-23, Call(test->entry(), 7, 17));
  EXPECT_EQ(23, Call(test->entry(), 7, -17));
  EXPECT_EQ(23, Call(test->entry(), -7, 17));
  EXPECT_EQ(-23, Call(test->entry(), -7, -17));
  EXPECT_EQ(-23, Call(test->entry(), 17, 7));
  EXPECT_EQ(23, Call(test->entry(), 17, -7));
  EXPECT_EQ(23, Call(test->entry(), -17, 7));
  EXPECT_EQ(-23, Call(test->entry(), -17, -7));
}

ASSEMBLER_TEST_GENERATE(CountLeadingZeroes, assembler) {
  __ SetExtensions(RV_GCB);
  __ clz(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(CountLeadingZeroes, test) {
  EXPECT_DISASSEMBLY(
      "60051513 clz a0, a0\n"
      "    8082 ret\n");

  EXPECT_EQ(XLEN, Call(test->entry(), 0));
  EXPECT_EQ(XLEN - 1, Call(test->entry(), 1));
  EXPECT_EQ(XLEN - 2, Call(test->entry(), 2));
  EXPECT_EQ(XLEN - 3, Call(test->entry(), 4));
  EXPECT_EQ(XLEN - 8, Call(test->entry(), 240));
  EXPECT_EQ(0, Call(test->entry(), -1));
  EXPECT_EQ(0, Call(test->entry(), -2));
  EXPECT_EQ(0, Call(test->entry(), -4));
  EXPECT_EQ(0, Call(test->entry(), -240));
}

ASSEMBLER_TEST_GENERATE(CountTrailingZeroes, assembler) {
  __ SetExtensions(RV_GCB);
  __ ctz(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(CountTrailingZeroes, test) {
  EXPECT_DISASSEMBLY(
      "60151513 ctz a0, a0\n"
      "    8082 ret\n");

  EXPECT_EQ(XLEN, Call(test->entry(), 0));
  EXPECT_EQ(0, Call(test->entry(), 1));
  EXPECT_EQ(1, Call(test->entry(), 2));
  EXPECT_EQ(2, Call(test->entry(), 4));
  EXPECT_EQ(4, Call(test->entry(), 240));
  EXPECT_EQ(0, Call(test->entry(), -1));
  EXPECT_EQ(1, Call(test->entry(), -2));
  EXPECT_EQ(2, Call(test->entry(), -4));
  EXPECT_EQ(4, Call(test->entry(), -240));
}

ASSEMBLER_TEST_GENERATE(CountPopulation, assembler) {
  __ SetExtensions(RV_GCB);
  __ cpop(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(CountPopulation, test) {
  EXPECT_DISASSEMBLY(
      "60251513 cpop a0, a0\n"
      "    8082 ret\n");

  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(1, Call(test->entry(), 1));
  EXPECT_EQ(3, Call(test->entry(), 7));
  EXPECT_EQ(4, Call(test->entry(), 30));
  EXPECT_EQ(XLEN, Call(test->entry(), -1));
  EXPECT_EQ(XLEN - 2, Call(test->entry(), -7));
  EXPECT_EQ(XLEN - 4, Call(test->entry(), -30));
}

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(CountLeadingZeroesWord, assembler) {
  __ SetExtensions(RV_GCB);
  __ clzw(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(CountLeadingZeroesWord, test) {
  EXPECT_DISASSEMBLY(
      "6005151b clzw a0, a0\n"
      "    8082 ret\n");

  EXPECT_EQ(32, Call(test->entry(), 0));
  EXPECT_EQ(31, Call(test->entry(), 1));
  EXPECT_EQ(30, Call(test->entry(), 2));
  EXPECT_EQ(29, Call(test->entry(), 4));
  EXPECT_EQ(24, Call(test->entry(), 240));
  EXPECT_EQ(0, Call(test->entry(), -1));
  EXPECT_EQ(0, Call(test->entry(), -2));
  EXPECT_EQ(0, Call(test->entry(), -4));
  EXPECT_EQ(0, Call(test->entry(), -240));
}

ASSEMBLER_TEST_GENERATE(CountTrailingZeroesWord, assembler) {
  __ SetExtensions(RV_GCB);
  __ ctzw(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(CountTrailingZeroesWord, test) {
  EXPECT_DISASSEMBLY(
      "6015151b ctzw a0, a0\n"
      "    8082 ret\n");

  EXPECT_EQ(32, Call(test->entry(), 0));
  EXPECT_EQ(0, Call(test->entry(), 1));
  EXPECT_EQ(1, Call(test->entry(), 2));
  EXPECT_EQ(2, Call(test->entry(), 4));
  EXPECT_EQ(4, Call(test->entry(), 240));
  EXPECT_EQ(0, Call(test->entry(), -1));
  EXPECT_EQ(1, Call(test->entry(), -2));
  EXPECT_EQ(2, Call(test->entry(), -4));
  EXPECT_EQ(4, Call(test->entry(), -240));
}

ASSEMBLER_TEST_GENERATE(CountPopulationWord, assembler) {
  __ SetExtensions(RV_GCB);
  __ cpopw(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(CountPopulationWord, test) {
  EXPECT_DISASSEMBLY(
      "6025151b cpopw a0, a0\n"
      "    8082 ret\n");

  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(1, Call(test->entry(), 1));
  EXPECT_EQ(3, Call(test->entry(), 7));
  EXPECT_EQ(4, Call(test->entry(), 30));
  EXPECT_EQ(32, Call(test->entry(), -1));
  EXPECT_EQ(30, Call(test->entry(), -7));
  EXPECT_EQ(28, Call(test->entry(), -30));
  EXPECT_EQ(0, Call(test->entry(), 0x7FFFFFFF00000000));
}
#endif

ASSEMBLER_TEST_GENERATE(Max, assembler) {
  __ SetExtensions(RV_GCB);
  __ max(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Max, test) {
  EXPECT_DISASSEMBLY(
      "0ab56533 max a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(17, Call(test->entry(), 7, 17));
  EXPECT_EQ(17, Call(test->entry(), -7, 17));
  EXPECT_EQ(7, Call(test->entry(), 7, -17));
  EXPECT_EQ(-7, Call(test->entry(), -7, -17));
}

ASSEMBLER_TEST_GENERATE(MaxUnsigned, assembler) {
  __ SetExtensions(RV_GCB);
  __ maxu(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(MaxUnsigned, test) {
  EXPECT_DISASSEMBLY(
      "0ab57533 maxu a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(17, Call(test->entry(), 7, 17));
  EXPECT_EQ(-7, Call(test->entry(), -7, 17));
  EXPECT_EQ(-17, Call(test->entry(), 7, -17));
  EXPECT_EQ(-7, Call(test->entry(), -7, -17));
}

ASSEMBLER_TEST_GENERATE(Min, assembler) {
  __ SetExtensions(RV_GCB);
  __ min(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(Min, test) {
  EXPECT_DISASSEMBLY(
      "0ab54533 min a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(7, Call(test->entry(), 7, 17));
  EXPECT_EQ(-7, Call(test->entry(), -7, 17));
  EXPECT_EQ(-17, Call(test->entry(), 7, -17));
  EXPECT_EQ(-17, Call(test->entry(), -7, -17));
}

ASSEMBLER_TEST_GENERATE(MinUnsigned, assembler) {
  __ SetExtensions(RV_GCB);
  __ minu(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(MinUnsigned, test) {
  EXPECT_DISASSEMBLY(
      "0ab55533 minu a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(7, Call(test->entry(), 7, 17));
  EXPECT_EQ(17, Call(test->entry(), -7, 17));
  EXPECT_EQ(7, Call(test->entry(), 7, -17));
  EXPECT_EQ(-17, Call(test->entry(), -7, -17));
}

ASSEMBLER_TEST_GENERATE(SignExtendByte, assembler) {
  __ SetExtensions(RV_GCB);
  __ sextb(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SignExtendByte, test) {
  EXPECT_DISASSEMBLY(
      "60451513 sext.b a0, a0\n"
      "    8082 ret\n");

  EXPECT_EQ(1, Call(test->entry(), 1));
  EXPECT_EQ(127, Call(test->entry(), 127));
  EXPECT_EQ(-128, Call(test->entry(), 128));
}

ASSEMBLER_TEST_GENERATE(SignExtendHalfWord, assembler) {
  __ SetExtensions(RV_GCB);
  __ sexth(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SignExtendHalfWord, test) {
  EXPECT_DISASSEMBLY(
      "60551513 sext.h a0, a0\n"
      "    8082 ret\n");

  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(0x7BCD, Call(test->entry(), 0x12347BCD));
  EXPECT_EQ(-1, Call(test->entry(), 0xFFFF));
  EXPECT_EQ(-1, Call(test->entry(), -1));
}

ASSEMBLER_TEST_GENERATE(ZeroExtendHalfWord, assembler) {
  __ SetExtensions(RV_GCB);
  __ zexth(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ZeroExtendHalfWord, test) {
#if XLEN == 32
  EXPECT_DISASSEMBLY(
      "08054533 zext.h a0, a0\n"
      "    8082 ret\n");
#else
  EXPECT_DISASSEMBLY(
      "0805453b zext.h a0, a0\n"
      "    8082 ret\n");
#endif

  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(0xABCD, Call(test->entry(), 0x1234ABCD));
  EXPECT_EQ(0xFFFF, Call(test->entry(), 0xFFFF));
  EXPECT_EQ(0xFFFF, Call(test->entry(), -1));
}

ASSEMBLER_TEST_GENERATE(RotateRight, assembler) {
  __ SetExtensions(RV_GCB);
  __ ror(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(RotateRight, test) {
  EXPECT_DISASSEMBLY(
      "60b55533 ror a0, a0, a1\n"
      "    8082 ret\n");

#if XLEN == 32
  EXPECT_EQ(static_cast<intx_t>(0x12345678),
            Call(test->entry(), 0x12345678, 0));
  EXPECT_EQ(static_cast<intx_t>(0x81234567),
            Call(test->entry(), 0x12345678, 4));
  EXPECT_EQ(static_cast<intx_t>(0x23456781),
            Call(test->entry(), 0x12345678, 28));
  EXPECT_EQ(static_cast<intx_t>(0x81234567),
            Call(test->entry(), 0x12345678, 36));
#else
  EXPECT_EQ(static_cast<intx_t>(0x0123456789ABCDEF),
            Call(test->entry(), 0x0123456789ABCDEF, 0));
  EXPECT_EQ(static_cast<intx_t>(0xF0123456789ABCDE),
            Call(test->entry(), 0x0123456789ABCDEF, 4));
  EXPECT_EQ(static_cast<intx_t>(0x123456789ABCDEF0),
            Call(test->entry(), 0x0123456789ABCDEF, 60));
  EXPECT_EQ(static_cast<intx_t>(0xF0123456789ABCDE),
            Call(test->entry(), 0x0123456789ABCDEF, 68));
#endif
}

ASSEMBLER_TEST_GENERATE(RotateLeft, assembler) {
  __ SetExtensions(RV_GCB);
  __ rol(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(RotateLeft, test) {
  EXPECT_DISASSEMBLY(
      "60b51533 rol a0, a0, a1\n"
      "    8082 ret\n");

#if XLEN == 32
  EXPECT_EQ(static_cast<intx_t>(0x12345678),
            Call(test->entry(), 0x12345678, 0));
  EXPECT_EQ(static_cast<intx_t>(0x23456781),
            Call(test->entry(), 0x12345678, 4));
  EXPECT_EQ(static_cast<intx_t>(0x81234567),
            Call(test->entry(), 0x12345678, 28));
  EXPECT_EQ(static_cast<intx_t>(0x23456781),
            Call(test->entry(), 0x12345678, 36));
#else
  EXPECT_EQ(static_cast<intx_t>(0x0123456789ABCDEF),
            Call(test->entry(), 0x0123456789ABCDEF, 0));
  EXPECT_EQ(static_cast<intx_t>(0x123456789ABCDEF0),
            Call(test->entry(), 0x0123456789ABCDEF, 4));
  EXPECT_EQ(static_cast<intx_t>(0xF0123456789ABCDE),
            Call(test->entry(), 0x0123456789ABCDEF, 60));
  EXPECT_EQ(static_cast<intx_t>(0x123456789ABCDEF0),
            Call(test->entry(), 0x0123456789ABCDEF, 68));
#endif
}

ASSEMBLER_TEST_GENERATE(RotateRightImmediate, assembler) {
  __ SetExtensions(RV_GCB);
  __ rori(A0, A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(RotateRightImmediate, test) {
  EXPECT_DISASSEMBLY(
      "60455513 rori a0, a0, 0x4\n"
      "    8082 ret\n");

#if XLEN == 32
  EXPECT_EQ(static_cast<intx_t>(0x81234567), Call(test->entry(), 0x12345678));
#else
  EXPECT_EQ(static_cast<intx_t>(0xF0123456789ABCDE),
            Call(test->entry(), 0x0123456789ABCDEF));
#endif
}

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(RotateRightWord, assembler) {
  __ SetExtensions(RV_GCB);
  __ rorw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(RotateRightWord, test) {
  EXPECT_DISASSEMBLY(
      "60b5553b rorw a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(sign_extend(0x12345678), Call(test->entry(), 0x12345678, 0));
  EXPECT_EQ(sign_extend(0x81234567), Call(test->entry(), 0x12345678, 4));
  EXPECT_EQ(sign_extend(0x23456781), Call(test->entry(), 0x12345678, 28));
  EXPECT_EQ(sign_extend(0x81234567), Call(test->entry(), 0x12345678, 36));
}

ASSEMBLER_TEST_GENERATE(RotateLeftWord, assembler) {
  __ SetExtensions(RV_GCB);
  __ rolw(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(RotateLeftWord, test) {
  EXPECT_DISASSEMBLY(
      "60b5153b rolw a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(sign_extend(0x12345678), Call(test->entry(), 0x12345678, 0));
  EXPECT_EQ(sign_extend(0x23456781), Call(test->entry(), 0x12345678, 4));
  EXPECT_EQ(sign_extend(0x81234567), Call(test->entry(), 0x12345678, 28));
  EXPECT_EQ(sign_extend(0x23456781), Call(test->entry(), 0x12345678, 36));
}

ASSEMBLER_TEST_GENERATE(RotateRightImmediateWord, assembler) {
  __ SetExtensions(RV_GCB);
  __ roriw(A0, A0, 4);
  __ ret();
}
ASSEMBLER_TEST_RUN(RotateRightImmediateWord, test) {
  EXPECT_DISASSEMBLY(
      "6045551b roriw a0, a0, 0x4\n"
      "    8082 ret\n");

  EXPECT_EQ(sign_extend(0x81234567), Call(test->entry(), 0x12345678));
}
#endif

ASSEMBLER_TEST_GENERATE(OrCombineBytes, assembler) {
  __ SetExtensions(RV_GCB);
  __ orcb(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(OrCombineBytes, test) {
  EXPECT_DISASSEMBLY(
      "28755513 orc.b a0, a0\n"
      "    8082 ret\n");

  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(-1, Call(test->entry(), -1));
  EXPECT_EQ(0x00FF00FF, Call(test->entry(), 0x00010001));
#if XLEN >= 64
  EXPECT_EQ(0x00FF00FF00FF00FF, Call(test->entry(), 0x0001000100010001));
#endif
}

ASSEMBLER_TEST_GENERATE(ByteReverse, assembler) {
  __ SetExtensions(RV_GCB);
  __ rev8(A0, A0);
  __ ret();
}
ASSEMBLER_TEST_RUN(ByteReverse, test) {
#if XLEN == 32
  EXPECT_DISASSEMBLY(
      "69855513 rev8 a0, a0\n"
      "    8082 ret\n");
#else
  EXPECT_DISASSEMBLY(
      "6b855513 rev8 a0, a0\n"
      "    8082 ret\n");
#endif

  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(-1, Call(test->entry(), -1));
#if XLEN == 32
  EXPECT_EQ(0x11223344, Call(test->entry(), 0x44332211));
#elif XLEN == 64
  EXPECT_EQ(0x1122334455667788, Call(test->entry(), 0x8877665544332211));
#endif
}

ASSEMBLER_TEST_GENERATE(CarrylessMultiply, assembler) {
  __ SetExtensions(RV_GCB);
  __ clmul(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(CarrylessMultiply, test) {
  EXPECT_DISASSEMBLY(
      "0ab51533 clmul a0, a0, a1\n"
      "    8082 ret\n");

#if XLEN == 32
  EXPECT_EQ(0x55555555, Call(test->entry(), -1, -1));
#else
  EXPECT_EQ(0x5555555555555555, Call(test->entry(), -1, -1));
#endif
  EXPECT_EQ(0, Call(test->entry(), -1, 0));
  EXPECT_EQ(-1, Call(test->entry(), -1, 1));
  EXPECT_EQ(0, Call(test->entry(), 0, -1));
  EXPECT_EQ(0, Call(test->entry(), 0, 0));
  EXPECT_EQ(0, Call(test->entry(), 0, 1));
  EXPECT_EQ(-1, Call(test->entry(), 1, -1));
  EXPECT_EQ(0, Call(test->entry(), 1, 0));
  EXPECT_EQ(1, Call(test->entry(), 1, 1));

  EXPECT_EQ(4, Call(test->entry(), 2, 2));
  EXPECT_EQ(5, Call(test->entry(), 3, 3));
  EXPECT_EQ(16, Call(test->entry(), 4, 4));
  EXPECT_EQ(20, Call(test->entry(), 6, 6));
}

ASSEMBLER_TEST_GENERATE(CarrylessMultiplyHigh, assembler) {
  __ SetExtensions(RV_GCB);
  __ clmulh(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(CarrylessMultiplyHigh, test) {
  EXPECT_DISASSEMBLY(
      "0ab53533 clmulh a0, a0, a1\n"
      "    8082 ret\n");

#if XLEN == 32
  EXPECT_EQ(0x55555555, Call(test->entry(), -1, -1));
#else
  EXPECT_EQ(0x5555555555555555, Call(test->entry(), -1, -1));
#endif
  EXPECT_EQ(0, Call(test->entry(), -1, 0));
  EXPECT_EQ(0, Call(test->entry(), -1, 1));
  EXPECT_EQ(0, Call(test->entry(), 0, -1));
  EXPECT_EQ(0, Call(test->entry(), 0, 0));
  EXPECT_EQ(0, Call(test->entry(), 0, 1));
  EXPECT_EQ(0, Call(test->entry(), 1, -1));
  EXPECT_EQ(0, Call(test->entry(), 1, 0));
  EXPECT_EQ(0, Call(test->entry(), 1, 1));

  EXPECT_EQ(0, Call(test->entry(), 2, 2));
  EXPECT_EQ(0, Call(test->entry(), 3, 3));
  EXPECT_EQ(0, Call(test->entry(), 4, 4));
  EXPECT_EQ(0, Call(test->entry(), 6, 6));
}

ASSEMBLER_TEST_GENERATE(CarrylessMultiplyReversed, assembler) {
  __ SetExtensions(RV_GCB);
  __ clmulr(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(CarrylessMultiplyReversed, test) {
  EXPECT_DISASSEMBLY(
      "0ab52533 clmulr a0, a0, a1\n"
      "    8082 ret\n");

#if XLEN == 32
  EXPECT_EQ(-0x55555556, Call(test->entry(), -1, -1));
#else
  EXPECT_EQ(-0x5555555555555556, Call(test->entry(), -1, -1));
#endif
  EXPECT_EQ(0, Call(test->entry(), -1, 0));
  EXPECT_EQ(1, Call(test->entry(), -1, 1));
  EXPECT_EQ(0, Call(test->entry(), 0, -1));
  EXPECT_EQ(0, Call(test->entry(), 0, 0));
  EXPECT_EQ(0, Call(test->entry(), 0, 1));
  EXPECT_EQ(1, Call(test->entry(), 1, -1));
  EXPECT_EQ(0, Call(test->entry(), 1, 0));
  EXPECT_EQ(0, Call(test->entry(), 1, 1));

  EXPECT_EQ(0, Call(test->entry(), 2, 2));
  EXPECT_EQ(0, Call(test->entry(), 3, 3));
  EXPECT_EQ(0, Call(test->entry(), 4, 4));
  EXPECT_EQ(0, Call(test->entry(), 6, 6));
}

ASSEMBLER_TEST_GENERATE(BitClear, assembler) {
  __ SetExtensions(RV_GCB);
  __ bclr(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitClear, test) {
  EXPECT_DISASSEMBLY(
      "48b51533 bclr a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(42, Call(test->entry(), 42, 0));
  EXPECT_EQ(40, Call(test->entry(), 42, 1));
  EXPECT_EQ(42, Call(test->entry(), 42, 2));
  EXPECT_EQ(34, Call(test->entry(), 42, 3));
  EXPECT_EQ(42, Call(test->entry(), 42, 4));
  EXPECT_EQ(10, Call(test->entry(), 42, 5));
  EXPECT_EQ(42, Call(test->entry(), 42, 6));
  EXPECT_EQ(42, Call(test->entry(), 42, 7));
  EXPECT_EQ(42, Call(test->entry(), 42, 8));

  EXPECT_EQ(42, Call(test->entry(), 42, 64));
  EXPECT_EQ(40, Call(test->entry(), 42, 65));
}

ASSEMBLER_TEST_GENERATE(BitClearImmediate, assembler) {
  __ SetExtensions(RV_GCB);
  __ bclri(A0, A0, 3);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitClearImmediate, test) {
  EXPECT_DISASSEMBLY(
      "48351513 bclri a0, a0, 0x3\n"
      "    8082 ret\n");

  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(7, Call(test->entry(), 7));
  EXPECT_EQ(0, Call(test->entry(), 8));
  EXPECT_EQ(1, Call(test->entry(), 9));
  EXPECT_EQ(-15, Call(test->entry(), -7));
  EXPECT_EQ(-16, Call(test->entry(), -8));
  EXPECT_EQ(-9, Call(test->entry(), -9));
}

ASSEMBLER_TEST_GENERATE(BitClearImmediate2, assembler) {
  __ SetExtensions(RV_GCB);
  __ bclri(A0, A0, XLEN - 1);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitClearImmediate2, test) {
#if XLEN == 32
  EXPECT_DISASSEMBLY(
      "49f51513 bclri a0, a0, 0x1f\n"
      "    8082 ret\n");
#elif XLEN == 64
  EXPECT_DISASSEMBLY(
      "4bf51513 bclri a0, a0, 0x3f\n"
      "    8082 ret\n");
#endif

  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(1, Call(test->entry(), 1));
  EXPECT_EQ(kMaxIntX, Call(test->entry(), -1));
}

ASSEMBLER_TEST_GENERATE(BitExtract, assembler) {
  __ SetExtensions(RV_GCB);
  __ bext(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitExtract, test) {
  EXPECT_DISASSEMBLY(
      "48b55533 bext a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(0, Call(test->entry(), 42, 0));
  EXPECT_EQ(1, Call(test->entry(), 42, 1));
  EXPECT_EQ(0, Call(test->entry(), 42, 2));
  EXPECT_EQ(1, Call(test->entry(), 42, 3));
  EXPECT_EQ(0, Call(test->entry(), 42, 4));
  EXPECT_EQ(1, Call(test->entry(), 42, 5));
  EXPECT_EQ(0, Call(test->entry(), 42, 6));
  EXPECT_EQ(0, Call(test->entry(), 42, 7));
  EXPECT_EQ(0, Call(test->entry(), 42, 8));

  EXPECT_EQ(0, Call(test->entry(), 42, 64));
  EXPECT_EQ(1, Call(test->entry(), 42, 65));
}

ASSEMBLER_TEST_GENERATE(BitExtractImmediate, assembler) {
  __ SetExtensions(RV_GCB);
  __ bexti(A0, A0, 3);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitExtractImmediate, test) {
  EXPECT_DISASSEMBLY(
      "48355513 bexti a0, a0, 0x3\n"
      "    8082 ret\n");

  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(0, Call(test->entry(), 7));
  EXPECT_EQ(1, Call(test->entry(), 8));
  EXPECT_EQ(1, Call(test->entry(), 9));
  EXPECT_EQ(1, Call(test->entry(), -7));
  EXPECT_EQ(1, Call(test->entry(), -8));
  EXPECT_EQ(0, Call(test->entry(), -9));
}

ASSEMBLER_TEST_GENERATE(BitExtractImmediate2, assembler) {
  __ SetExtensions(RV_GCB);
  __ bexti(A0, A0, XLEN - 1);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitExtractImmediate2, test) {
#if XLEN == 32
  EXPECT_DISASSEMBLY(
      "49f55513 bexti a0, a0, 0x1f\n"
      "    8082 ret\n");
#elif XLEN == 64
  EXPECT_DISASSEMBLY(
      "4bf55513 bexti a0, a0, 0x3f\n"
      "    8082 ret\n");
#endif

  EXPECT_EQ(0, Call(test->entry(), 0));
  EXPECT_EQ(0, Call(test->entry(), 1));
  EXPECT_EQ(1, Call(test->entry(), -1));
}

ASSEMBLER_TEST_GENERATE(BitInvert, assembler) {
  __ SetExtensions(RV_GCB);
  __ binv(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitInvert, test) {
  EXPECT_DISASSEMBLY(
      "68b51533 binv a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(43, Call(test->entry(), 42, 0));
  EXPECT_EQ(40, Call(test->entry(), 42, 1));
  EXPECT_EQ(46, Call(test->entry(), 42, 2));
  EXPECT_EQ(34, Call(test->entry(), 42, 3));
  EXPECT_EQ(58, Call(test->entry(), 42, 4));
  EXPECT_EQ(10, Call(test->entry(), 42, 5));
  EXPECT_EQ(106, Call(test->entry(), 42, 6));
  EXPECT_EQ(170, Call(test->entry(), 42, 7));
  EXPECT_EQ(298, Call(test->entry(), 42, 8));

  EXPECT_EQ(43, Call(test->entry(), 42, 64));
  EXPECT_EQ(40, Call(test->entry(), 42, 65));
}

ASSEMBLER_TEST_GENERATE(BitInvertImmediate, assembler) {
  __ SetExtensions(RV_GCB);
  __ binvi(A0, A0, 3);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitInvertImmediate, test) {
  EXPECT_DISASSEMBLY(
      "68351513 binvi a0, a0, 0x3\n"
      "    8082 ret\n");

  EXPECT_EQ(8, Call(test->entry(), 0));
  EXPECT_EQ(15, Call(test->entry(), 7));
  EXPECT_EQ(0, Call(test->entry(), 8));
  EXPECT_EQ(1, Call(test->entry(), 9));
  EXPECT_EQ(-15, Call(test->entry(), -7));
  EXPECT_EQ(-16, Call(test->entry(), -8));
  EXPECT_EQ(-1, Call(test->entry(), -9));
}

ASSEMBLER_TEST_GENERATE(BitInvertImmediate2, assembler) {
  __ SetExtensions(RV_GCB);
  __ binvi(A0, A0, XLEN - 1);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitInvertImmediate2, test) {
#if XLEN == 32
  EXPECT_DISASSEMBLY(
      "69f51513 binvi a0, a0, 0x1f\n"
      "    8082 ret\n");
#elif XLEN == 64
  EXPECT_DISASSEMBLY(
      "6bf51513 binvi a0, a0, 0x3f\n"
      "    8082 ret\n");
#endif

  EXPECT_EQ(kMinIntX, Call(test->entry(), 0));
  EXPECT_EQ(kMinIntX + 1, Call(test->entry(), 1));
  EXPECT_EQ(kMaxIntX, Call(test->entry(), -1));
}

ASSEMBLER_TEST_GENERATE(BitSet, assembler) {
  __ SetExtensions(RV_GCB);
  __ bset(A0, A0, A1);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitSet, test) {
  EXPECT_DISASSEMBLY(
      "28b51533 bset a0, a0, a1\n"
      "    8082 ret\n");

  EXPECT_EQ(43, Call(test->entry(), 42, 0));
  EXPECT_EQ(42, Call(test->entry(), 42, 1));
  EXPECT_EQ(46, Call(test->entry(), 42, 2));
  EXPECT_EQ(42, Call(test->entry(), 42, 3));
  EXPECT_EQ(58, Call(test->entry(), 42, 4));
  EXPECT_EQ(42, Call(test->entry(), 42, 5));
  EXPECT_EQ(106, Call(test->entry(), 42, 6));
  EXPECT_EQ(170, Call(test->entry(), 42, 7));
  EXPECT_EQ(298, Call(test->entry(), 42, 8));

  EXPECT_EQ(43, Call(test->entry(), 42, 64));
  EXPECT_EQ(42, Call(test->entry(), 42, 65));
}

ASSEMBLER_TEST_GENERATE(BitSetImmediate, assembler) {
  __ SetExtensions(RV_GCB);
  __ bseti(A0, A0, 3);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitSetImmediate, test) {
  EXPECT_DISASSEMBLY(
      "28351513 bseti a0, a0, 0x3\n"
      "    8082 ret\n");

  EXPECT_EQ(8, Call(test->entry(), 0));
  EXPECT_EQ(15, Call(test->entry(), 7));
  EXPECT_EQ(8, Call(test->entry(), 8));
  EXPECT_EQ(9, Call(test->entry(), 9));
  EXPECT_EQ(-7, Call(test->entry(), -7));
  EXPECT_EQ(-8, Call(test->entry(), -8));
  EXPECT_EQ(-1, Call(test->entry(), -9));
}

ASSEMBLER_TEST_GENERATE(BitSetImmediate2, assembler) {
  __ SetExtensions(RV_GCB);
  __ bseti(A0, A0, XLEN - 1);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitSetImmediate2, test) {
#if XLEN == 32
  EXPECT_DISASSEMBLY(
      "29f51513 bseti a0, a0, 0x1f\n"
      "    8082 ret\n");
#elif XLEN == 64
  EXPECT_DISASSEMBLY(
      "2bf51513 bseti a0, a0, 0x3f\n"
      "    8082 ret\n");
#endif

  EXPECT_EQ(kMinIntX, Call(test->entry(), 0));
  EXPECT_EQ(kMinIntX + 1, Call(test->entry(), 1));
  EXPECT_EQ(-1, Call(test->entry(), -1));
}

ASSEMBLER_TEST_GENERATE(LoadImmediate_MaxInt32, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ LoadImmediate(A0, kMaxInt32);
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadImmediate_MaxInt32, test) {
#if XLEN == 32
  EXPECT_DISASSEMBLY(
      "80000537 lui a0, -2147483648\n"
      "    157d addi a0, a0, -1\n"
      "    8082 ret\n");
#elif XLEN == 64
  EXPECT_DISASSEMBLY(
      "80000537 lui a0, -2147483648\n"
      "    357d addiw a0, a0, -1\n"
      "    8082 ret\n");
#endif
  EXPECT_EQ(kMaxInt32, Call(test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediate_MinInt32, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ LoadImmediate(A0, kMinInt32);
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadImmediate_MinInt32, test) {
  EXPECT_DISASSEMBLY(
      "80000537 lui a0, -2147483648\n"
      "    8082 ret\n");
  EXPECT_EQ(kMinInt32, Call(test->entry()));
}

#if XLEN >= 64
ASSEMBLER_TEST_GENERATE(LoadImmediate_MinInt64, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ LoadImmediate(A0, kMinInt64);
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadImmediate_MinInt64, test) {
  EXPECT_DISASSEMBLY(
      "    557d li a0, -1\n"
      "03f51513 slli a0, a0, 0x3f\n"
      "    8082 ret\n");
  EXPECT_EQ(kMinInt64, Call(test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediate_Full, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ LoadImmediate(A0, 0xABCDABCDABCDABCD);
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadImmediate_Full, test) {
  EXPECT_DISASSEMBLY(
      "feaf3537 lui a0, -22073344\n"
      "6af5051b addiw a0, a0, 1711\n"
      "    0532 slli a0, a0, 12\n"
      "36b50513 addi a0, a0, 875\n"
      "    053a slli a0, a0, 14\n"
      "cdb50513 addi a0, a0, -805\n"
      "    0532 slli a0, a0, 12\n"
      "bcd50513 addi a0, a0, -1075\n"
      "    8082 ret\n");
  EXPECT_EQ(static_cast<int64_t>(0xABCDABCDABCDABCD), Call(test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediate_LuiAddiwSlli, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ LoadImmediate(A0, 0x7BCDABCD00000);
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadImmediate_LuiAddiwSlli, test) {
  EXPECT_DISASSEMBLY(
      "7bcdb537 lui a0, 2077077504\n"
      "bcd5051b addiw a0, a0, -1075\n"
      "    0552 slli a0, a0, 20\n"
      "    8082 ret\n");
  EXPECT_EQ(static_cast<int64_t>(0x7BCDABCD00000), Call(test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediate_LuiSlli, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ LoadImmediate(A0, 0xABCDE00000000000);
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadImmediate_LuiSlli, test) {
  EXPECT_DISASSEMBLY(
      "d5e6f537 lui a0, -706285568\n"
      "02151513 slli a0, a0, 0x21\n"
      "    8082 ret\n");
  EXPECT_EQ(static_cast<int64_t>(0xABCDE00000000000), Call(test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediate_LiSlli, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ LoadImmediate(A0, 0xABC00000000000);
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadImmediate_LiSlli, test) {
  EXPECT_DISASSEMBLY(
      "2af00513 li a0, 687\n"
      "02e51513 slli a0, a0, 0x2e\n"
      "    8082 ret\n");
  EXPECT_EQ(static_cast<int64_t>(0xABC00000000000), Call(test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediate_LiSlliAddi, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ LoadImmediate(A0, 0xFF000000000000FF);
  __ ret();
}
ASSEMBLER_TEST_RUN(LoadImmediate_LiSlliAddi, test) {
  EXPECT_DISASSEMBLY(
      "    557d li a0, -1\n"
      "03851513 slli a0, a0, 0x38\n"
      "0ff50513 addi a0, a0, 255\n"
      "    8082 ret\n");
  EXPECT_EQ(static_cast<int64_t>(0xFF000000000000FF), Call(test->entry()));
}
#endif

ASSEMBLER_TEST_GENERATE(BitwiseImmediates_GC, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  __ AndImmediate(A0, A1, ~0x10000000);
  __ OrImmediate(A0, A1, 0x10000000);
  __ XorImmediate(A0, A1, 0x10000000);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitwiseImmediates_GC, test) {
#if XLEN == 32
  EXPECT_DISASSEMBLY(
      "f0000737 lui tmp2, -268435456\n"
      "    177d addi tmp2, tmp2, -1\n"
      "00e5f533 and a0, a1, tmp2\n"
      "10000737 lui tmp2, 268435456\n"
      "00e5e533 or a0, a1, tmp2\n"
      "10000737 lui tmp2, 268435456\n"
      "00e5c533 xor a0, a1, tmp2\n"
      "    8082 ret\n");
#else
  EXPECT_DISASSEMBLY(
      "f0000737 lui tmp2, -268435456\n"
      "    377d addiw tmp2, tmp2, -1\n"
      "00e5f533 and a0, a1, tmp2\n"
      "10000737 lui tmp2, 268435456\n"
      "00e5e533 or a0, a1, tmp2\n"
      "10000737 lui tmp2, 268435456\n"
      "00e5c533 xor a0, a1, tmp2\n"
      "    8082 ret\n");
#endif
}

ASSEMBLER_TEST_GENERATE(BitwiseImmediates_GCB, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GCB);
  __ AndImmediate(A0, A1, ~0x10000000);
  __ OrImmediate(A0, A1, 0x10000000);
  __ XorImmediate(A0, A1, 0x10000000);
  __ ret();
}
ASSEMBLER_TEST_RUN(BitwiseImmediates_GCB, test) {
  EXPECT_DISASSEMBLY(
      "49c59513 bclri a0, a1, 0x1c\n"
      "29c59513 bseti a0, a1, 0x1c\n"
      "69c59513 binvi a0, a1, 0x1c\n"
      "    8082 ret\n");
}

ASSEMBLER_TEST_GENERATE(AddImmediateBranchOverflow, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  Label overflow;

  __ AddImmediateBranchOverflow(A0, A0, 2, &overflow);
  __ ret();
  __ Bind(&overflow);
  __ li(A0, 0);
  __ ret();
}
ASSEMBLER_TEST_RUN(AddImmediateBranchOverflow, test) {
  EXPECT_DISASSEMBLY(
      "    872a mv tmp2, a0\n"
      "    0509 addi a0, a0, 2\n"
      "00e54363 blt a0, tmp2, +6\n"
      "    8082 ret\n"
      "    4501 li a0, 0\n"
      "    8082 ret\n");
  EXPECT_EQ(kMaxIntX - 1, Call(test->entry(), kMaxIntX - 3));
  EXPECT_EQ(kMaxIntX, Call(test->entry(), kMaxIntX - 2));
  EXPECT_EQ(0, Call(test->entry(), kMaxIntX - 1));
  EXPECT_EQ(0, Call(test->entry(), kMaxIntX));
}

ASSEMBLER_TEST_GENERATE(AddBranchOverflow_NonDestructive, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  Label overflow;

  __ AddBranchOverflow(A0, A1, A2, &overflow);
  __ ret();
  __ Bind(&overflow);
  __ li(A0, 0);
  __ ret();
}
ASSEMBLER_TEST_RUN(AddBranchOverflow_NonDestructive, test) {
  EXPECT_DISASSEMBLY(
      "00c58533 add a0, a1, a2\n"
      "00062693 slti tmp, a2, 0\n"
      "00b52733 slt tmp2, a0, a1\n"
      "00e69363 bne tmp, tmp2, +6\n"
      "    8082 ret\n"
      "    4501 li a0, 0\n"
      "    8082 ret\n");
  EXPECT_EQ(kMaxIntX - 1, Call(test->entry(), 42, kMaxIntX, -1));
  EXPECT_EQ(kMaxIntX, Call(test->entry(), 42, kMaxIntX, 0));
  EXPECT_EQ(0, Call(test->entry(), 42, kMaxIntX, 1));

  EXPECT_EQ(0, Call(test->entry(), 42, kMinIntX, -1));
  EXPECT_EQ(kMinIntX + 1, Call(test->entry(), 42, kMinIntX, 1));
  EXPECT_EQ(kMinIntX, Call(test->entry(), 42, kMinIntX, 0));
}

ASSEMBLER_TEST_GENERATE(AddBranchOverflow_Destructive, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  Label overflow;

  __ AddBranchOverflow(A0, A1, A0, &overflow);
  __ ret();
  __ Bind(&overflow);
  __ li(A0, 0);
  __ ret();
}
ASSEMBLER_TEST_RUN(AddBranchOverflow_Destructive, test) {
  EXPECT_DISASSEMBLY(
      "00052693 slti tmp, a0, 0\n"
      "    952e add a0, a0, a1\n"
      "00b52733 slt tmp2, a0, a1\n"
      "00e69363 bne tmp, tmp2, +6\n"
      "    8082 ret\n"
      "    4501 li a0, 0\n"
      "    8082 ret\n");
  EXPECT_EQ(kMaxIntX - 1, Call(test->entry(), kMaxIntX, -1));
  EXPECT_EQ(kMaxIntX, Call(test->entry(), kMaxIntX, 0));
  EXPECT_EQ(0, Call(test->entry(), kMaxIntX, 1));

  EXPECT_EQ(0, Call(test->entry(), kMinIntX, -1));
  EXPECT_EQ(kMinIntX + 1, Call(test->entry(), kMinIntX, 1));
  EXPECT_EQ(kMinIntX, Call(test->entry(), kMinIntX, 0));
}

ASSEMBLER_TEST_GENERATE(SubtractImmediateBranchOverflow, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  Label overflow;

  __ SubtractImmediateBranchOverflow(A0, A0, 2, &overflow);
  __ ret();
  __ Bind(&overflow);
  __ li(A0, 0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SubtractImmediateBranchOverflow, test) {
  EXPECT_DISASSEMBLY(
      "    872a mv tmp2, a0\n"
      "    1579 addi a0, a0, -2\n"
      "00a74363 blt tmp2, a0, +6\n"
      "    8082 ret\n"
      "    4501 li a0, 0\n"
      "    8082 ret\n");
  EXPECT_EQ(kMinIntX + 1, Call(test->entry(), kMinIntX + 3));
  EXPECT_EQ(kMinIntX, Call(test->entry(), kMinIntX + 2));
  EXPECT_EQ(0, Call(test->entry(), kMinIntX + 1));
  EXPECT_EQ(0, Call(test->entry(), kMinIntX));
}

ASSEMBLER_TEST_GENERATE(SubtractBranchOverflow_NonDestructive, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);

  Label overflow;
  __ SubtractBranchOverflow(A0, A1, A2, &overflow);
  __ ret();
  __ Bind(&overflow);
  __ li(A0, 0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SubtractBranchOverflow_NonDestructive, test) {
  EXPECT_DISASSEMBLY(
      "40c58533 sub a0, a1, a2\n"
      "00062693 slti tmp, a2, 0\n"
      "00a5a733 slt tmp2, a1, a0\n"
      "00e69363 bne tmp, tmp2, +6\n"
      "    8082 ret\n"
      "    4501 li a0, 0\n"
      "    8082 ret\n");
  EXPECT_EQ(kMaxIntX - 1, Call(test->entry(), 42, kMaxIntX, 1));
  EXPECT_EQ(kMaxIntX, Call(test->entry(), 42, kMaxIntX, 0));
  EXPECT_EQ(0, Call(test->entry(), 42, kMaxIntX, -1));

  EXPECT_EQ(0, Call(test->entry(), 42, kMinIntX, 1));
  EXPECT_EQ(kMinIntX + 1, Call(test->entry(), 42, kMinIntX, -1));
  EXPECT_EQ(kMinIntX, Call(test->entry(), 42, kMinIntX, 0));
}

ASSEMBLER_TEST_GENERATE(SubtractBranchOverflow_Destructive, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);

  Label overflow;
  __ SubtractBranchOverflow(A0, A0, A1, &overflow);
  __ ret();
  __ Bind(&overflow);
  __ li(A0, 0);
  __ ret();
}
ASSEMBLER_TEST_RUN(SubtractBranchOverflow_Destructive, test) {
  EXPECT_DISASSEMBLY(
      "00052693 slti tmp, a0, 0\n"
      "    8d0d sub a0, a0, a1\n"
      "00b52733 slt tmp2, a0, a1\n"
      "00e69363 bne tmp, tmp2, +6\n"
      "    8082 ret\n"
      "    4501 li a0, 0\n"
      "    8082 ret\n");
  EXPECT_EQ(kMaxIntX - 1, Call(test->entry(), kMaxIntX, 1));
  EXPECT_EQ(kMaxIntX, Call(test->entry(), kMaxIntX, 0));
  EXPECT_EQ(0, Call(test->entry(), kMaxIntX, -1));

  EXPECT_EQ(0, Call(test->entry(), kMinIntX, 1));
  EXPECT_EQ(kMinIntX + 1, Call(test->entry(), kMinIntX, -1));
  EXPECT_EQ(kMinIntX, Call(test->entry(), kMinIntX, 0));
}

ASSEMBLER_TEST_GENERATE(MultiplyImmediateBranchOverflow, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);
  Label overflow;

  __ MultiplyImmediateBranchOverflow(A0, A0, 2, &overflow);
  __ ret();
  __ Bind(&overflow);
  __ li(A0, 0);
  __ ret();
}
ASSEMBLER_TEST_RUN(MultiplyImmediateBranchOverflow, test) {
#if XLEN == 64
  EXPECT_DISASSEMBLY(
      "    4709 li tmp2, 2\n"
      "02e516b3 mulh tmp, a0, tmp2\n"
      "02e50533 mul a0, a0, tmp2\n"
      "43f55713 srai tmp2, a0, 0x3f\n"
      "00e69363 bne tmp, tmp2, +6\n"
      "    8082 ret\n"
      "    4501 li a0, 0\n"
      "    8082 ret\n");
#elif XLEN == 32
  EXPECT_DISASSEMBLY(
      "    4709 li tmp2, 2\n"
      "02e516b3 mulh tmp, a0, tmp2\n"
      "02e50533 mul a0, a0, tmp2\n"
      "41f55713 srai tmp2, a0, 0x1f\n"
      "00e69363 bne tmp, tmp2, +6\n"
      "    8082 ret\n"
      "    4501 li a0, 0\n"
      "    8082 ret\n");
#endif
  EXPECT_EQ(0, Call(test->entry(), kMinIntX));
  EXPECT_EQ(0, Call(test->entry(), kMaxIntX));
  EXPECT_EQ(-2, Call(test->entry(), -1));
  EXPECT_EQ(2, Call(test->entry(), 1));
  EXPECT_EQ(kMinIntX, Call(test->entry(), kMinIntX / 2));
  EXPECT_EQ(kMaxIntX - 1, Call(test->entry(), (kMaxIntX - 1) / 2));
}

ASSEMBLER_TEST_GENERATE(MultiplyBranchOverflow_NonDestructive, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);

  Label overflow;
  __ MultiplyBranchOverflow(A0, A1, A2, &overflow);
  __ ret();
  __ Bind(&overflow);
  __ li(A0, 42);
  __ ret();
}
ASSEMBLER_TEST_RUN(MultiplyBranchOverflow_NonDestructive, test) {
#if XLEN == 64
  EXPECT_DISASSEMBLY(
      "02c596b3 mulh tmp, a1, a2\n"
      "02c58533 mul a0, a1, a2\n"
      "43f55713 srai tmp2, a0, 0x3f\n"
      "00e69363 bne tmp, tmp2, +6\n"
      "    8082 ret\n"
      "02a00513 li a0, 42\n"
      "    8082 ret\n");
#elif XLEN == 32
  EXPECT_DISASSEMBLY(
      "02c596b3 mulh tmp, a1, a2\n"
      "02c58533 mul a0, a1, a2\n"
      "41f55713 srai tmp2, a0, 0x1f\n"
      "00e69363 bne tmp, tmp2, +6\n"
      "    8082 ret\n"
      "02a00513 li a0, 42\n"
      "    8082 ret\n");
#endif
  EXPECT_EQ(42, Call(test->entry(), 42, kMaxIntX, -2));
  EXPECT_EQ(-kMaxIntX, Call(test->entry(), 42, kMaxIntX, -1));
  EXPECT_EQ(0, Call(test->entry(), 42, kMaxIntX, 0));
  EXPECT_EQ(kMaxIntX, Call(test->entry(), 42, kMaxIntX, 1));
  EXPECT_EQ(42, Call(test->entry(), 42, kMaxIntX, 2));

  EXPECT_EQ(42, Call(test->entry(), 42, kMinIntX, -2));
  EXPECT_EQ(42, Call(test->entry(), 42, kMinIntX, -1));
  EXPECT_EQ(0, Call(test->entry(), 42, kMinIntX, 0));
  EXPECT_EQ(kMinIntX, Call(test->entry(), 42, kMinIntX, 1));
  EXPECT_EQ(42, Call(test->entry(), 42, kMinIntX, 2));
}

ASSEMBLER_TEST_GENERATE(MultiplyBranchOverflow_Destructive, assembler) {
  FLAG_use_compressed_instructions = true;
  __ SetExtensions(RV_GC);

  Label overflow;
  __ MultiplyBranchOverflow(A0, A0, A1, &overflow);
  __ ret();
  __ Bind(&overflow);
  __ li(A0, 42);
  __ ret();
}
ASSEMBLER_TEST_RUN(MultiplyBranchOverflow_Destructive, test) {
#if XLEN == 64
  EXPECT_DISASSEMBLY(
      "02b516b3 mulh tmp, a0, a1\n"
      "02b50533 mul a0, a0, a1\n"
      "43f55713 srai tmp2, a0, 0x3f\n"
      "00e69363 bne tmp, tmp2, +6\n"
      "    8082 ret\n"
      "02a00513 li a0, 42\n"
      "    8082 ret\n");
#elif XLEN == 32
  EXPECT_DISASSEMBLY(
      "02b516b3 mulh tmp, a0, a1\n"
      "02b50533 mul a0, a0, a1\n"
      "41f55713 srai tmp2, a0, 0x1f\n"
      "00e69363 bne tmp, tmp2, +6\n"
      "    8082 ret\n"
      "02a00513 li a0, 42\n"
      "    8082 ret\n");
#endif
  EXPECT_EQ(42, Call(test->entry(), kMaxIntX, -2));
  EXPECT_EQ(-kMaxIntX, Call(test->entry(), kMaxIntX, -1));
  EXPECT_EQ(0, Call(test->entry(), kMaxIntX, 0));
  EXPECT_EQ(kMaxIntX, Call(test->entry(), kMaxIntX, 1));
  EXPECT_EQ(42, Call(test->entry(), kMaxIntX, 2));

  EXPECT_EQ(42, Call(test->entry(), kMinIntX, -2));
  EXPECT_EQ(42, Call(test->entry(), kMinIntX, -1));
  EXPECT_EQ(0, Call(test->entry(), kMinIntX, 0));
  EXPECT_EQ(kMinIntX, Call(test->entry(), kMinIntX, 1));
  EXPECT_EQ(42, Call(test->entry(), kMinIntX, 2));
}

#define TEST_ENCODING(type, name)                                              \
  VM_UNIT_TEST_CASE(Encoding##name) {                                          \
    for (intptr_t v = -(1 << 21); v <= (1 << 21); v++) {                       \
      type value = static_cast<type>(v);                                       \
      if (!Is##name(value)) continue;                                          \
      int32_t encoded = Encode##name(value);                                   \
      type decoded = Decode##name(encoded);                                    \
      EXPECT_EQ(value, decoded);                                               \
    }                                                                          \
  }

TEST_ENCODING(Register, Rd)
TEST_ENCODING(Register, Rs1)
TEST_ENCODING(Register, Rs2)
TEST_ENCODING(FRegister, FRd)
TEST_ENCODING(FRegister, FRs1)
TEST_ENCODING(FRegister, FRs2)
TEST_ENCODING(FRegister, FRs3)
TEST_ENCODING(Funct2, Funct2)
TEST_ENCODING(Funct3, Funct3)
TEST_ENCODING(Funct5, Funct5)
TEST_ENCODING(Funct7, Funct7)
TEST_ENCODING(Funct12, Funct12)
TEST_ENCODING(RoundingMode, RoundingMode)
TEST_ENCODING(intptr_t, BTypeImm)
TEST_ENCODING(intptr_t, JTypeImm)
TEST_ENCODING(intptr_t, ITypeImm)
TEST_ENCODING(intptr_t, STypeImm)
TEST_ENCODING(intptr_t, UTypeImm)

TEST_ENCODING(Register, CRd)
TEST_ENCODING(Register, CRs1)
TEST_ENCODING(Register, CRs2)
TEST_ENCODING(Register, CRdp)
TEST_ENCODING(Register, CRs1p)
TEST_ENCODING(Register, CRs2p)
TEST_ENCODING(FRegister, CFRd)
TEST_ENCODING(FRegister, CFRs1)
TEST_ENCODING(FRegister, CFRs2)
TEST_ENCODING(FRegister, CFRdp)
TEST_ENCODING(FRegister, CFRs1p)
TEST_ENCODING(FRegister, CFRs2p)
TEST_ENCODING(intptr_t, CSPLoad4Imm)
TEST_ENCODING(intptr_t, CSPLoad8Imm)
TEST_ENCODING(intptr_t, CSPStore4Imm)
TEST_ENCODING(intptr_t, CSPStore8Imm)
TEST_ENCODING(intptr_t, CMem4Imm)
TEST_ENCODING(intptr_t, CMem8Imm)
TEST_ENCODING(intptr_t, CJImm)
TEST_ENCODING(intptr_t, CBImm)
TEST_ENCODING(intptr_t, CIImm)
TEST_ENCODING(intptr_t, CUImm)
TEST_ENCODING(intptr_t, CI16Imm)
TEST_ENCODING(intptr_t, CI4SPNImm)

#undef TEST_ENCODING

static void RangeCheck(Assembler* assembler, Register value, Register temp) {
  const Register return_reg = CallingConventions::kReturnReg;
  Label in_range;
  __ RangeCheck(value, temp, kFirstErrorCid, kLastErrorCid,
                AssemblerBase::kIfInRange, &in_range);
  __ LoadImmediate(return_reg, 0);
  __ Ret();
  __ Bind(&in_range);
  __ LoadImmediate(return_reg, 1);
  __ Ret();
}

ASSEMBLER_TEST_GENERATE(RangeCheckNoTemp, assembler) {
  const Register value = CallingConventions::ArgumentRegisters[0];
  const Register temp = kNoRegister;
  RangeCheck(assembler, value, temp);
}

ASSEMBLER_TEST_RUN(RangeCheckNoTemp, test) {
  intptr_t result;
  result = test->Invoke<intptr_t, intptr_t>(kErrorCid);
  EXPECT_EQ(1, result);
  result = test->Invoke<intptr_t, intptr_t>(kUnwindErrorCid);
  EXPECT_EQ(1, result);
  result = test->Invoke<intptr_t, intptr_t>(kFunctionCid);
  EXPECT_EQ(0, result);
  result = test->Invoke<intptr_t, intptr_t>(kMintCid);
  EXPECT_EQ(0, result);
}

ASSEMBLER_TEST_GENERATE(RangeCheckWithTemp, assembler) {
  const Register value = CallingConventions::ArgumentRegisters[0];
  const Register temp = CallingConventions::ArgumentRegisters[1];
  RangeCheck(assembler, value, temp);
}

ASSEMBLER_TEST_RUN(RangeCheckWithTemp, test) {
  intptr_t result;
  result = test->Invoke<intptr_t, intptr_t>(kErrorCid);
  EXPECT_EQ(1, result);
  result = test->Invoke<intptr_t, intptr_t>(kUnwindErrorCid);
  EXPECT_EQ(1, result);
  result = test->Invoke<intptr_t, intptr_t>(kFunctionCid);
  EXPECT_EQ(0, result);
  result = test->Invoke<intptr_t, intptr_t>(kMintCid);
  EXPECT_EQ(0, result);
}

ASSEMBLER_TEST_GENERATE(RangeCheckWithTempReturnValue, assembler) {
  const Register value = CallingConventions::ArgumentRegisters[0];
  const Register temp = CallingConventions::ArgumentRegisters[1];
  const Register return_reg = CallingConventions::kReturnReg;
  Label in_range;
  __ RangeCheck(value, temp, kFirstErrorCid, kLastErrorCid,
                AssemblerBase::kIfInRange, &in_range);
  __ Bind(&in_range);
  __ MoveRegister(return_reg, value);
  __ Ret();
}

ASSEMBLER_TEST_RUN(RangeCheckWithTempReturnValue, test) {
  intptr_t result;
  result = test->Invoke<intptr_t, intptr_t>(kErrorCid);
  EXPECT_EQ(kErrorCid, result);
  result = test->Invoke<intptr_t, intptr_t>(kUnwindErrorCid);
  EXPECT_EQ(kUnwindErrorCid, result);
  result = test->Invoke<intptr_t, intptr_t>(kFunctionCid);
  EXPECT_EQ(kFunctionCid, result);
  result = test->Invoke<intptr_t, intptr_t>(kMintCid);
  EXPECT_EQ(kMintCid, result);
}

static void EnterTestFrame(Assembler* assembler) {
  __ EnterFrame(0);
  __ PushRegister(CODE_REG);
  __ PushRegister(THR);
  __ PushRegister(PP);
  __ MoveRegister(CODE_REG, A0);
  __ MoveRegister(THR, A1);
  __ LoadPoolPointer(PP);
}

static void LeaveTestFrame(Assembler* assembler) {
  __ PopRegister(PP);
  __ PopRegister(THR);
  __ PopRegister(CODE_REG);

  __ LeaveFrame();
}

#define LOAD_FROM_BOX_TEST(VALUE, SAME_REGISTER)                               \
  ASSEMBLER_TEST_GENERATE(LoadWordFromBoxOrSmi##VALUE##SAME_REGISTER,          \
                          assembler) {                                         \
    const bool same_register = SAME_REGISTER;                                  \
    const Register src = CallingConventions::ArgumentRegisters[0];             \
    const Register dst =                                                       \
        same_register ? src : CallingConventions::ArgumentRegisters[1];        \
    const intptr_t value = VALUE;                                              \
                                                                               \
    EnterTestFrame(assembler);                                                 \
                                                                               \
    __ LoadObject(src, Integer::ZoneHandle(Integer::New(value, Heap::kOld)));  \
    __ LoadWordFromBoxOrSmi(dst, src);                                         \
    __ MoveRegister(CallingConventions::kReturnReg, dst);                      \
                                                                               \
    LeaveTestFrame(assembler);                                                 \
                                                                               \
    __ Ret();                                                                  \
  }                                                                            \
                                                                               \
  ASSEMBLER_TEST_RUN(LoadWordFromBoxOrSmi##VALUE##SAME_REGISTER, test) {       \
    const int64_t res = test->InvokeWithCodeAndThread<int64_t>();              \
    EXPECT_EQ(static_cast<intptr_t>(VALUE), static_cast<intptr_t>(res));       \
  }

LOAD_FROM_BOX_TEST(0, true)
LOAD_FROM_BOX_TEST(0, false)
LOAD_FROM_BOX_TEST(1, true)
LOAD_FROM_BOX_TEST(1, false)
#if defined(TARGET_ARCH_RISCV32)
LOAD_FROM_BOX_TEST(0x7FFFFFFF, true)
LOAD_FROM_BOX_TEST(0x7FFFFFFF, false)
LOAD_FROM_BOX_TEST(0x80000000, true)
LOAD_FROM_BOX_TEST(0x80000000, false)
LOAD_FROM_BOX_TEST(0xFFFFFFFF, true)
LOAD_FROM_BOX_TEST(0xFFFFFFFF, false)
#else
LOAD_FROM_BOX_TEST(0x7FFFFFFFFFFFFFFF, true)
LOAD_FROM_BOX_TEST(0x7FFFFFFFFFFFFFFF, false)
LOAD_FROM_BOX_TEST(0x8000000000000000, true)
LOAD_FROM_BOX_TEST(0x8000000000000000, false)
LOAD_FROM_BOX_TEST(0xFFFFFFFFFFFFFFFF, true)
LOAD_FROM_BOX_TEST(0xFFFFFFFFFFFFFFFF, false)
#endif

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_RISCV)
