// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/assembler.h"
#include "vm/cpu.h"
#include "vm/os.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

#define __ assembler->


ASSEMBLER_TEST_GENERATE(Simple, assembler) {
  __ mov(R0, Operand(42));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Simple, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(MoveNegated, assembler) {
  __ mvn(R0, Operand(42));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(MoveNegated, test) {
  EXPECT(test != NULL);
  typedef int (*MoveNegated)() DART_UNUSED;
  EXPECT_EQ(~42, EXECUTE_TEST_CODE_INT32(MoveNegated, test->entry()));
}


ASSEMBLER_TEST_GENERATE(MoveRotImm, assembler) {
  Operand o;
  EXPECT(Operand::CanHold(0x00550000, &o));
  __ mov(R0, o);
  EXPECT(Operand::CanHold(0x30000003, &o));
  __ add(R0, R0, o);
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(MoveRotImm, test) {
  EXPECT(test != NULL);
  typedef int (*MoveRotImm)() DART_UNUSED;
  EXPECT_EQ(0x30550003, EXECUTE_TEST_CODE_INT32(MoveRotImm, test->entry()));
}


ASSEMBLER_TEST_GENERATE(MovImm16, assembler) {
#if defined(USING_SIMULATOR)
  // ARMv7 is the default.
  HostCPUFeatures::set_arm_version(ARMv6);
  __ LoadDecodableImmediate(R0, 0x12345678 << 1);
  HostCPUFeatures::set_arm_version(ARMv7);
  __ LoadDecodableImmediate(R1, 0x12345678);
  __ sub(R0, R0, Operand(R1));
  __ bx(LR);
#else
  __ LoadDecodableImmediate(R0, 0x12345678);
  __ bx(LR);
#endif
}


ASSEMBLER_TEST_RUN(MovImm16, test) {
  EXPECT(test != NULL);
  typedef int (*MovImm16)() DART_UNUSED;
  EXPECT_EQ(0x12345678, EXECUTE_TEST_CODE_INT32(MovImm16, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadImmediate, assembler) {
  __ mov(R0, Operand(0));
  __ cmp(R0, Operand(0));
  __ LoadImmediate(R0, 0x12345678, EQ);
  __ LoadImmediate(R0, 0x87654321, NE);
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(LoadImmediate, test) {
  EXPECT(test != NULL);
  typedef int (*LoadImmediate)() DART_UNUSED;
  EXPECT_EQ(0x12345678, EXECUTE_TEST_CODE_INT32(LoadImmediate, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vmov, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ mov(R3, Operand(43));
    __ mov(R1, Operand(41));
    __ vmovsrr(S1, R1, R3);  // S1:S2 = 41:43
    __ vmovs(S0, S2);  // S0 = S2, S0:S1 == 43:41
    __ vmovd(D2, D0);  // D2 = D0, S4:S5 == 43:41
    __ vmovrs(R3, S5);  // R3 = S5, R3 == 41
    __ vmovrrs(R1, R2, S4);  // R1:R2 = S4:S5, R1:R2 == 43:41
    __ vmovdrr(D3, R3, R2);  // D3 = R3:R2, S6:S7 == 41:41
    __ vmovdr(D3, 1, R1);  // D3[1] == S7 = R1, S6:S7 == 41:43
    __ vmovrrd(R0, R1, D3);  // R0:R1 = D3, R0:R1 == 41:43
    __ sub(R0, R1, Operand(R0));  // 43-41
  } else {
    __ LoadImmediate(R0, 2);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Vmov, test) {
  EXPECT(test != NULL);
  typedef int (*Vmov)() DART_UNUSED;
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INT32(Vmov, test->entry()));
}


ASSEMBLER_TEST_GENERATE(SingleVLoadStore, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ LoadImmediate(R0, bit_cast<int32_t, float>(12.3f));
    __ mov(R2, Operand(SP));
    __ str(R0, Address(SP, (-kWordSize * 30), Address::PreIndex));
    __ vldrs(S0, Address(R2, (-kWordSize * 30)));
    __ vadds(S0, S0, S0);
    __ vstrs(S0, Address(R2, (-kWordSize * 30)));
    __ ldr(R0, Address(SP, (kWordSize * 30), Address::PostIndex));
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(SingleVLoadStore, test) {
  EXPECT(test != NULL);
  if (TargetCPUFeatures::vfp_supported()) {
    typedef float (*SingleVLoadStore)() DART_UNUSED;
    float res = EXECUTE_TEST_CODE_FLOAT(SingleVLoadStore, test->entry());
    EXPECT_FLOAT_EQ(2*12.3f, res, 0.001f);
  } else {
    typedef int (*SingleVLoadStore)() DART_UNUSED;
    EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SingleVLoadStore, test->entry()));
  }
}


ASSEMBLER_TEST_GENERATE(SingleVShiftLoadStore, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ LoadImmediate(R0, bit_cast<int32_t, float>(12.3f));
    __ mov(R2, Operand(SP));
    // Expressing __str(R0, Address(SP, (-kWordSize * 32), Address::PreIndex));
    // as:
    __ mov(R1, Operand(kWordSize));
    __ str(R0, Address(SP, R1, LSL, 5, Address::NegPreIndex));
    __ vldrs(S0, Address(R2, (-kWordSize * 32)));
    __ vadds(S0, S0, S0);
    __ vstrs(S0, Address(R2, (-kWordSize * 32)));
    // Expressing __ldr(R0, Address(SP, (kWordSize * 32), Address::PostIndex));
    // as:
    __ ldr(R0, Address(SP, R1, LSL, 5, Address::PostIndex));
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(SingleVShiftLoadStore, test) {
  EXPECT(test != NULL);
  if (TargetCPUFeatures::vfp_supported()) {
    typedef float (*SingleVLoadStore)() DART_UNUSED;
    float res = EXECUTE_TEST_CODE_FLOAT(SingleVLoadStore, test->entry());
    EXPECT_FLOAT_EQ(2*12.3f, res, 0.001f);
  } else {
    typedef int (*SingleVLoadStore)() DART_UNUSED;
    EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SingleVLoadStore, test->entry()));
  }
}


ASSEMBLER_TEST_GENERATE(DoubleVLoadStore, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    int64_t value = bit_cast<int64_t, double>(12.3);
    __ LoadImmediate(R0, Utils::Low32Bits(value));
    __ LoadImmediate(R1, Utils::High32Bits(value));
    __ mov(R2, Operand(SP));
    __ str(R0, Address(SP, (-kWordSize * 30), Address::PreIndex));
    __ str(R1, Address(R2, (-kWordSize * 29)));
    __ vldrd(D0, Address(R2, (-kWordSize * 30)));
    __ vaddd(D0, D0, D0);
    __ vstrd(D0, Address(R2, (-kWordSize * 30)));
    __ ldr(R1, Address(R2, (-kWordSize * 29)));
    __ ldr(R0, Address(SP, (kWordSize * 30), Address::PostIndex));
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(DoubleVLoadStore, test) {
  EXPECT(test != NULL);
  if (TargetCPUFeatures::vfp_supported()) {
    typedef double (*DoubleVLoadStore)() DART_UNUSED;
    float res = EXECUTE_TEST_CODE_DOUBLE(DoubleVLoadStore, test->entry());
    EXPECT_FLOAT_EQ(2*12.3f, res, 0.001f);
  } else {
    typedef int (*DoubleVLoadStore)() DART_UNUSED;
    EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(DoubleVLoadStore, test->entry()));
  }
}


ASSEMBLER_TEST_GENERATE(SingleFPOperations, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ LoadSImmediate(S0, 12.3f);
    __ LoadSImmediate(S1, 3.4f);
    __ vnegs(S0, S0);  // -12.3f
    __ vabss(S0, S0);  // 12.3f
    __ vadds(S0, S0, S1);  // 15.7f
    __ vmuls(S0, S0, S1);  // 53.38f
    __ vsubs(S0, S0, S1);  // 49.98f
    __ vdivs(S0, S0, S1);  // 14.7f
    __ vsqrts(S0, S0);  // 3.8340579f
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(SingleFPOperations, test) {
  EXPECT(test != NULL);
  if (TargetCPUFeatures::vfp_supported()) {
    typedef float (*SingleFPOperations)() DART_UNUSED;
    float res = EXECUTE_TEST_CODE_FLOAT(SingleFPOperations, test->entry());
    EXPECT_FLOAT_EQ(3.8340579f, res, 0.001f);
  } else {
    typedef int (*SingleFPOperations)() DART_UNUSED;
    EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SingleFPOperations, test->entry()));
  }
}


ASSEMBLER_TEST_GENERATE(DoubleFPOperations, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ LoadDImmediate(D0, 12.3, R0);
    __ LoadDImmediate(D1, 3.4, R0);
    __ vnegd(D0, D0);  // -12.3
    __ vabsd(D0, D0);  // 12.3
    __ vaddd(D0, D0, D1);  // 15.7
    __ vmuld(D0, D0, D1);  // 53.38
    __ vsubd(D0, D0, D1);  // 49.98
    __ vdivd(D0, D0, D1);  // 14.7
    __ vsqrtd(D0, D0);  // 3.8340579
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(DoubleFPOperations, test) {
  EXPECT(test != NULL);
  if (TargetCPUFeatures::vfp_supported()) {
    typedef double (*DoubleFPOperations)() DART_UNUSED;
    double res = EXECUTE_TEST_CODE_DOUBLE(DoubleFPOperations, test->entry());
    EXPECT_FLOAT_EQ(3.8340579, res, 0.001);
  } else {
    typedef int (*DoubleFPOperations)() DART_UNUSED;
    EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(DoubleFPOperations, test->entry()));
  }
}


ASSEMBLER_TEST_GENERATE(DoubleSqrtNeg, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    // Check that sqrt of a negative double gives NaN.
    __ LoadDImmediate(D1, -1.0, R0);
    __ vsqrtd(D0, D1);
    __ vcmpd(D0, D0);
    __ vmstat();
    __ mov(R0, Operand(1), VS);
    __ mov(R0, Operand(0), VC);
  } else {
    __ LoadImmediate(R0, 1);
  }
  __ Ret();
}


ASSEMBLER_TEST_RUN(DoubleSqrtNeg, test) {
  EXPECT(test != NULL);
  typedef int (*DoubleSqrtNeg)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(DoubleSqrtNeg, test->entry()));
}


ASSEMBLER_TEST_GENERATE(IntToDoubleConversion, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ mov(R3, Operand(6));
    __ vmovsr(S3, R3);
    __ vcvtdi(D0, S3);
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(IntToDoubleConversion, test) {
  EXPECT(test != NULL);
  if (TargetCPUFeatures::vfp_supported()) {
    typedef double (*IntToDoubleConversionCode)() DART_UNUSED;
    double res = EXECUTE_TEST_CODE_DOUBLE(IntToDoubleConversionCode,
                                          test->entry());
    EXPECT_FLOAT_EQ(6.0, res, 0.001);
  } else {
    typedef int (*IntToDoubleConversionCode)() DART_UNUSED;
    EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(IntToDoubleConversionCode,
                                         test->entry()));
  }
}


ASSEMBLER_TEST_GENERATE(LongToDoubleConversion, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    int64_t value = 60000000000LL;
    __ LoadImmediate(R0, Utils::Low32Bits(value));
    __ LoadImmediate(R1, Utils::High32Bits(value));
    __ vmovsr(S0, R0);
    __ vmovsr(S2, R1);
    __ vcvtdu(D0, S0);
    __ vcvtdi(D1, S2);
    __ LoadDImmediate(D2, 1.0 * (1LL << 32), R0);
    __ vmlad(D0, D1, D2);
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(LongToDoubleConversion, test) {
  EXPECT(test != NULL);
  if (TargetCPUFeatures::vfp_supported()) {
    typedef double (*LongToDoubleConversionCode)() DART_UNUSED;
    double res = EXECUTE_TEST_CODE_DOUBLE(LongToDoubleConversionCode,
                                          test->entry());
    EXPECT_FLOAT_EQ(60000000000.0, res, 0.001);
  } else {
    typedef int (*LongToDoubleConversionCode)() DART_UNUSED;
    EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(LongToDoubleConversionCode,
                                         test->entry()));
  }
}


ASSEMBLER_TEST_GENERATE(IntToFloatConversion, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ mov(R3, Operand(6));
    __ vmovsr(S3, R3);
    __ vcvtsi(S0, S3);
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(IntToFloatConversion, test) {
  EXPECT(test != NULL);
  if (TargetCPUFeatures::vfp_supported()) {
    typedef float (*IntToFloatConversionCode)() DART_UNUSED;
    float res = EXECUTE_TEST_CODE_FLOAT(IntToFloatConversionCode,
                                        test->entry());
    EXPECT_FLOAT_EQ(6.0, res, 0.001);
  } else {
    typedef int (*IntToFloatConversionCode)() DART_UNUSED;
    EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(IntToFloatConversionCode,
                                         test->entry()));
  }
}


ASSEMBLER_TEST_GENERATE(FloatToIntConversion, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ vcvtis(S1, S0);
    __ vmovrs(R0, S1);
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(FloatToIntConversion, test) {
  EXPECT(test != NULL);
  if (TargetCPUFeatures::vfp_supported()) {
    typedef int (*FloatToIntConversion)(float arg) DART_UNUSED;
    EXPECT_EQ(12,
              EXECUTE_TEST_CODE_INT32_F(FloatToIntConversion, test->entry(),
                                        12.8f));
    EXPECT_EQ(INT_MIN,
              EXECUTE_TEST_CODE_INT32_F(FloatToIntConversion, test->entry(),
                                        -FLT_MAX));
    EXPECT_EQ(INT_MAX,
              EXECUTE_TEST_CODE_INT32_F(FloatToIntConversion, test->entry(),
                                        FLT_MAX));
  } else {
    typedef int (*FloatToIntConversion)() DART_UNUSED;
    EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(FloatToIntConversion, test->entry()));
  }
}


ASSEMBLER_TEST_GENERATE(DoubleToIntConversion, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ vcvtid(S0, D0);
    __ vmovrs(R0, S0);
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(DoubleToIntConversion, test) {
  if (TargetCPUFeatures::vfp_supported()) {
    typedef int (*DoubleToIntConversion)(double arg) DART_UNUSED;
    EXPECT(test != NULL);
    EXPECT_EQ(12,
              EXECUTE_TEST_CODE_INT32_D(DoubleToIntConversion, test->entry(),
                                        12.8));
    EXPECT_EQ(INT_MIN,
              EXECUTE_TEST_CODE_INT32_D(DoubleToIntConversion, test->entry(),
                                        -DBL_MAX));
    EXPECT_EQ(INT_MAX,
              EXECUTE_TEST_CODE_INT32_D(DoubleToIntConversion, test->entry(),
                                        DBL_MAX));
  } else {
    typedef int (*DoubleToIntConversion)() DART_UNUSED;
    EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(DoubleToIntConversion, test->entry()));
  }
}


ASSEMBLER_TEST_GENERATE(FloatToDoubleConversion, assembler) {
  __ LoadSImmediate(S2, 12.8f);
  __ vcvtds(D0, S2);
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(FloatToDoubleConversion, test) {
  typedef double (*FloatToDoubleConversionCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(FloatToDoubleConversionCode,
                                        test->entry());
  EXPECT_FLOAT_EQ(12.8, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(DoubleToFloatConversion, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ LoadDImmediate(D1, 12.8, R0);
    __ vcvtsd(S0, D1);
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(DoubleToFloatConversion, test) {
  EXPECT(test != NULL);
  if (TargetCPUFeatures::vfp_supported()) {
    typedef float (*DoubleToFloatConversionCode)() DART_UNUSED;
    float res = EXECUTE_TEST_CODE_FLOAT(DoubleToFloatConversionCode,
                                        test->entry());
    EXPECT_FLOAT_EQ(12.8, res, 0.001);
  } else {
    typedef int (*DoubleToFloatConversionCode)() DART_UNUSED;
    EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(DoubleToFloatConversionCode,
                                         test->entry()));
  }
}


ASSEMBLER_TEST_GENERATE(FloatCompare, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    // Test 12.3f vs 12.5f.
    __ LoadSImmediate(S0, 12.3f);
    __ LoadSImmediate(S1, 12.5f);

    // Count errors in R0. R0 is zero if no errors found.
    __ mov(R0, Operand(0));
    __ vcmps(S0, S1);
    __ vmstat();
    __ add(R0, R0, Operand(1), VS);  // Error if unordered (Nan).
    __ add(R0, R0, Operand(2), GT);  // Error if greater.
    __ add(R0, R0, Operand(4), EQ);  // Error if equal.
    __ add(R0, R0, Operand(8), PL);  // Error if not less.

    // Test NaN.
    // Create NaN by dividing 0.0f/0.0f.
    __ LoadSImmediate(S1, 0.0f);
    __ vdivs(S1, S1, S1);
    __ vcmps(S1, S1);
    __ vmstat();
    // Error if not unordered (not Nan).
    __ add(R0, R0, Operand(16), VC);
  } else {
    __ LoadImmediate(R0, 0);
  }
  // R0 is 0 if all tests passed.
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(FloatCompare, test) {
  EXPECT(test != NULL);
  typedef int (*FloatCompare)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(FloatCompare, test->entry()));
}


ASSEMBLER_TEST_GENERATE(DoubleCompare, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    // Test 12.3 vs 12.5.
    __ LoadDImmediate(D0, 12.3, R1);
    __ LoadDImmediate(D1, 12.5, R1);

    // Count errors in R0. R0 is zero if no errors found.
    __ mov(R0, Operand(0));
    __ vcmpd(D0, D1);
    __ vmstat();
    __ add(R0, R0, Operand(1), VS);  // Error if unordered (Nan).
    __ add(R0, R0, Operand(2), GT);  // Error if greater.
    __ add(R0, R0, Operand(4), EQ);  // Error if equal.
    __ add(R0, R0, Operand(8), PL);  // Error if not less.

    // Test NaN.
    // Create NaN by dividing 0.0/0.0.
    __ LoadDImmediate(D1, 0.0, R1);
    __ vdivd(D1, D1, D1);
    __ vcmpd(D1, D1);
    __ vmstat();
    // Error if not unordered (not Nan).
    __ add(R0, R0, Operand(16), VC);
  } else {
    __ LoadImmediate(R0, 0);
  }
  // R0 is 0 if all tests passed.
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(DoubleCompare, test) {
  EXPECT(test != NULL);
  typedef int (*DoubleCompare)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(DoubleCompare, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Loop, assembler) {
  Label loop_entry;
  __ mov(R0, Operand(1));
  __ mov(R1, Operand(2));
  __ Bind(&loop_entry);
  __ mov(R0, Operand(R0, LSL, 1));
  __ movs(R1, Operand(R1, LSR, 1));
  __ b(&loop_entry, NE);
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Loop, test) {
  EXPECT(test != NULL);
  typedef int (*Loop)() DART_UNUSED;
  EXPECT_EQ(4, EXECUTE_TEST_CODE_INT32(Loop, test->entry()));
}


ASSEMBLER_TEST_GENERATE(ForwardBranch, assembler) {
  Label skip;
  __ mov(R0, Operand(42));
  __ b(&skip);
  __ mov(R0, Operand(11));
  __ Bind(&skip);
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(ForwardBranch, test) {
  EXPECT(test != NULL);
  typedef int (*ForwardBranch)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(ForwardBranch, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Loop2, assembler) {
  Label loop_entry;
  __ set_use_far_branches(true);
  __ mov(R0, Operand(1));
  __ mov(R1, Operand(2));
  __ Bind(&loop_entry);
  __ mov(R0, Operand(R0, LSL, 1));
  __ movs(R1, Operand(R1, LSR, 1));
  __ b(&loop_entry, NE);
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Loop2, test) {
  EXPECT(test != NULL);
  typedef int (*Loop)() DART_UNUSED;
  EXPECT_EQ(4, EXECUTE_TEST_CODE_INT32(Loop, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Loop3, assembler) {
  Label loop_entry;
  __ set_use_far_branches(true);
  __ mov(R0, Operand(1));
  __ mov(R1, Operand(2));
  __ Bind(&loop_entry);
  for (int i = 0; i < (1 << 22); i++) {
    __ nop();
  }
  __ mov(R0, Operand(R0, LSL, 1));
  __ movs(R1, Operand(R1, LSR, 1));
  __ b(&loop_entry, NE);
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Loop3, test) {
  EXPECT(test != NULL);
  typedef int (*Loop)() DART_UNUSED;
  EXPECT_EQ(4, EXECUTE_TEST_CODE_INT32(Loop, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadStore, assembler) {
  __ mov(R1, Operand(123));
  __ Push(R1);
  __ Pop(R0);
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(LoadStore, test) {
  EXPECT(test != NULL);
  typedef int (*LoadStore)() DART_UNUSED;
  EXPECT_EQ(123, EXECUTE_TEST_CODE_INT32(LoadStore, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Semaphore, assembler) {
  if (TargetCPUFeatures::arm_version() == ARMv5TE) {
    __ mov(R0, Operand(42));
    __ bx(LR);
  } else {
    __ mov(R0, Operand(40));
    __ mov(R1, Operand(42));
    __ Push(R0);
    Label retry;
    __ Bind(&retry);
    __ ldrex(R0, SP);
    __ strex(IP, R1, SP);  // IP == 0, success
    __ tst(IP, Operand(0));
    __ b(&retry, NE);  // NE if context switch occurred between ldrex and strex.
    __ Pop(R0);  // 42
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Semaphore, test) {
  EXPECT(test != NULL);
  typedef int (*Semaphore)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Semaphore, test->entry()));
}


ASSEMBLER_TEST_GENERATE(FailedSemaphore, assembler) {
  if (TargetCPUFeatures::arm_version() == ARMv5TE) {
    __ mov(R0, Operand(41));
    __ bx(LR);
  } else {
    __ mov(R0, Operand(40));
    __ mov(R1, Operand(42));
    __ Push(R0);
    __ ldrex(R0, SP);
    __ clrex();  // Simulate a context switch.
    __ strex(IP, R1, SP);  // IP == 1, failure
    __ Pop(R0);  // 40
    __ add(R0, R0, Operand(IP));
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(FailedSemaphore, test) {
  EXPECT(test != NULL);
  typedef int (*FailedSemaphore)() DART_UNUSED;
  EXPECT_EQ(41, EXECUTE_TEST_CODE_INT32(FailedSemaphore, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddSub, assembler) {
  __ mov(R1, Operand(40));
  __ sub(R1, R1, Operand(2));
  __ add(R0, R1, Operand(4));
  __ rsbs(R0, R0, Operand(100));
  __ rsc(R0, R0, Operand(100));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(AddSub, test) {
  EXPECT(test != NULL);
  typedef int (*AddSub)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(AddSub, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddCarry, assembler) {
  __ LoadImmediate(R2, 0xFFFFFFFF);
  __ mov(R1, Operand(1));
  __ mov(R0, Operand(0));
  __ adds(R2, R2, Operand(R1));
  __ adcs(R0, R0, Operand(R0));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(AddCarry, test) {
  EXPECT(test != NULL);
  typedef int (*AddCarry)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(AddCarry, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddCarryInOut, assembler) {
  __ LoadImmediate(R2, 0xFFFFFFFF);
  __ mov(R1, Operand(1));
  __ mov(R0, Operand(0));
  __ adds(IP, R2, Operand(R1));  // c_out = 1.
  __ adcs(IP, R2, Operand(R0));  // c_in = 1, c_out = 1.
  __ adc(R0, R0, Operand(R0));  // c_in = 1.
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(AddCarryInOut, test) {
  EXPECT(test != NULL);
  typedef int (*AddCarryInOut)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(AddCarryInOut, test->entry()));
}


ASSEMBLER_TEST_GENERATE(SubCarry, assembler) {
  __ LoadImmediate(R2, 0x0);
  __ mov(R1, Operand(1));
  __ mov(R0, Operand(0));
  __ subs(R2, R2, Operand(R1));
  __ sbcs(R0, R0, Operand(R0));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(SubCarry, test) {
  EXPECT(test != NULL);
  typedef int (*SubCarry)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SubCarry, test->entry()));
}


ASSEMBLER_TEST_GENERATE(SubCarryInOut, assembler) {
  __ mov(R1, Operand(1));
  __ mov(R0, Operand(0));
  __ subs(IP, R0, Operand(R1));  // c_out = 1.
  __ sbcs(IP, R0, Operand(R0));  // c_in = 1, c_out = 1.
  __ sbc(R0, R0, Operand(R0));  // c_in = 1.
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(SubCarryInOut, test) {
  EXPECT(test != NULL);
  typedef int (*SubCarryInOut)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SubCarryInOut, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Overflow, assembler) {
  __ LoadImmediate(R0, 0xFFFFFFFF);
  __ LoadImmediate(R1, 0x7FFFFFFF);
  __ adds(IP, R0, Operand(1));  // c_out = 1.
  __ adcs(IP, R1, Operand(0));  // c_in = 1, c_out = 1, v = 1.
  __ mov(R0, Operand(1), VS);
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Overflow, test) {
  EXPECT(test != NULL);
  typedef int (*Overflow)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(Overflow, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AndOrr, assembler) {
  __ mov(R1, Operand(40));
  __ mov(R2, Operand(0));
  __ and_(R1, R2, Operand(R1));
  __ mov(R3, Operand(42));
  __ orr(R0, R1, Operand(R3));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(AndOrr, test) {
  EXPECT(test != NULL);
  typedef int (*AndOrr)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(AndOrr, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Orrs, assembler) {
  __ mov(R0, Operand(0));
  __ tst(R0, Operand(R1));  // Set zero-flag.
  __ orrs(R0, R0, Operand(1));  // Clear zero-flag.
  __ bx(LR, EQ);
  __ mov(R0, Operand(42));
  __ bx(LR, NE);  // Only this return should fire.
  __ mov(R0, Operand(2));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Orrs, test) {
  EXPECT(test != NULL);
  typedef int (*Orrs)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Orrs, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Multiply, assembler) {
  __ mov(R1, Operand(20));
  __ mov(R2, Operand(40));
  __ mul(R3, R2, R1);
  __ mov(R0, Operand(R3));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Multiply, test) {
  EXPECT(test != NULL);
  typedef int (*Multiply)() DART_UNUSED;
  EXPECT_EQ(800, EXECUTE_TEST_CODE_INT32(Multiply, test->entry()));
}


ASSEMBLER_TEST_GENERATE(QuotientRemainder, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ vmovsr(S2, R0);
    __ vmovsr(S4, R2);
    __ vcvtdi(D1, S2);
    __ vcvtdi(D2, S4);
    __ vdivd(D0, D1, D2);
    __ vcvtid(S0, D0);
    __ vmovrs(R1, S0);  // r1 = r0/r2
    __ mls(R0, R1, R2, R0);  // r0 = r0 - r1*r2
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(QuotientRemainder, test) {
  EXPECT(test != NULL);
  if (TargetCPUFeatures::vfp_supported()) {
    typedef int64_t (*QuotientRemainder)
        (int64_t dividend, int64_t divisor) DART_UNUSED;
    EXPECT_EQ(0x1000400000da8LL,
              EXECUTE_TEST_CODE_INT64_LL(QuotientRemainder, test->entry(),
                                         0x12345678, 0x1234));
  } else {
    typedef int (*QuotientRemainder)() DART_UNUSED;
    EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(QuotientRemainder, test->entry()));
  }
}


ASSEMBLER_TEST_GENERATE(Multiply64To64, assembler) {
#if defined(USING_SIMULATOR)
  const ARMVersion version = TargetCPUFeatures::arm_version();
  HostCPUFeatures::set_arm_version(ARMv7);
#endif
  if (TargetCPUFeatures::arm_version() == ARMv7) {
    __ Push(R4);
    __ mov(IP, Operand(R0));
    __ mul(R4, R2, R1);
    __ umull(R0, R1, R2, IP);
    __ mla(R2, IP, R3, R4);
    __ add(R1, R2, Operand(R1));
    __ Pop(R4);
  } else {
    __ LoadImmediate(R0, 6);
  }
  __ bx(LR);
#if defined(USING_SIMULATOR)
  HostCPUFeatures::set_arm_version(version);
#endif
}


ASSEMBLER_TEST_RUN(Multiply64To64, test) {
  EXPECT(test != NULL);
  typedef int64_t (*Multiply64To64)
      (int64_t operand0, int64_t operand1) DART_UNUSED;
  EXPECT_EQ(6,
            EXECUTE_TEST_CODE_INT64_LL(Multiply64To64, test->entry(), -3, -2));
}


ASSEMBLER_TEST_GENERATE(Multiply32To64, assembler) {
#if defined(USING_SIMULATOR)
  const ARMVersion version = TargetCPUFeatures::arm_version();
  HostCPUFeatures::set_arm_version(ARMv7);
#endif
  if (TargetCPUFeatures::arm_version() == ARMv7) {
    __ smull(R0, R1, R0, R2);
  } else {
    __ LoadImmediate(R0, 6);
  }
  __ bx(LR);
#if defined(USING_SIMULATOR)
  HostCPUFeatures::set_arm_version(version);
#endif
}


ASSEMBLER_TEST_RUN(Multiply32To64, test) {
  EXPECT(test != NULL);
  typedef int64_t (*Multiply32To64)
      (int64_t operand0, int64_t operand1) DART_UNUSED;
  EXPECT_EQ(6,
            EXECUTE_TEST_CODE_INT64_LL(Multiply32To64, test->entry(), -3, -2));
}


ASSEMBLER_TEST_GENERATE(MultiplyAccum32To64, assembler) {
#if defined(USING_SIMULATOR)
  const ARMVersion version = TargetCPUFeatures::arm_version();
  HostCPUFeatures::set_arm_version(ARMv7);
#endif
  if (TargetCPUFeatures::arm_version() == ARMv7) {
    __ smlal(R0, R1, R0, R2);
  } else {
    __ LoadImmediate(R0, 3);
  }
  __ bx(LR);
#if defined(USING_SIMULATOR)
  HostCPUFeatures::set_arm_version(version);
#endif
}


ASSEMBLER_TEST_RUN(MultiplyAccum32To64, test) {
  EXPECT(test != NULL);
  typedef int64_t (*Multiply32To64)
      (int64_t operand0, int64_t operand1) DART_UNUSED;
  EXPECT_EQ(3,
            EXECUTE_TEST_CODE_INT64_LL(Multiply32To64, test->entry(), -3, -2));
}


ASSEMBLER_TEST_GENERATE(Clz, assembler) {
  Label error;

  __ mov(R0, Operand(0));
  __ clz(R1, R0);
  __ cmp(R1, Operand(32));
  __ b(&error, NE);
  __ mov(R2, Operand(42));
  __ clz(R2, R2);
  __ cmp(R2, Operand(26));
  __ b(&error, NE);
  __ mvn(R0, Operand(0));
  __ clz(R1, R0);
  __ cmp(R1, Operand(0));
  __ b(&error, NE);
  __ Lsr(R0, R0, Operand(3));
  __ clz(R1, R0);
  __ cmp(R1, Operand(3));
  __ b(&error, NE);
  __ mov(R0, Operand(0));
  __ bx(LR);
  __ Bind(&error);
  __ mov(R0, Operand(1));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Clz, test) {
  EXPECT(test != NULL);
  typedef int (*Clz)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(Clz, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Tst, assembler) {
  Label skip;

  __ mov(R0, Operand(42));
  __ mov(R1, Operand(40));
  __ tst(R1, Operand(0));
  __ b(&skip, NE);
  __ mov(R0, Operand(0));
  __ Bind(&skip);
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Tst, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lsl, assembler) {
  Label skip;

  __ mov(R0, Operand(1));
  __ mov(R0, Operand(R0, LSL, 1));
  __ mov(R1, Operand(1));
  __ mov(R0, Operand(R0, LSL, R1));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Lsl, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(4, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lsr, assembler) {
  Label skip;

  __ mov(R0, Operand(4));
  __ mov(R0, Operand(R0, LSR, 1));
  __ mov(R1, Operand(1));
  __ mov(R0, Operand(R0, LSR, R1));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Lsr, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lsr1, assembler) {
  Label skip;

  __ mov(R0, Operand(1));
  __ Lsl(R0, R0, Operand(31));
  __ Lsr(R0, R0, Operand(31));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Lsr1, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Asr1, assembler) {
  Label skip;

  __ mov(R0, Operand(1));
  __ Lsl(R0, R0, Operand(31));
  __ Asr(R0, R0, Operand(31));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Asr1, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Rsb, assembler) {
  __ mov(R3, Operand(10));
  __ rsb(R0, R3, Operand(42));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Rsb, test) {
  EXPECT(test != NULL);
  typedef int (*Rsb)() DART_UNUSED;
  EXPECT_EQ(32, EXECUTE_TEST_CODE_INT32(Rsb, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Ldrh, assembler) {
  Label Test1, Test2, Test3, Done;

  __ mov(R1, Operand(0x11));
  __ mov(R2, Operand(SP));
  __ str(R1, Address(SP, (-kWordSize * 30), Address::PreIndex));
  __ ldrh(R0, Address(R2, (-kWordSize * 30)));
  __ cmp(R0, Operand(0x11));
  __ b(&Test1, EQ);
  __ mov(R0, Operand(1));
  __ b(&Done);
  __ Bind(&Test1);

  __ mov(R0, Operand(0x22));
  __ strh(R0, Address(R2, (-kWordSize * 30)));
  __ ldrh(R1, Address(R2, (-kWordSize * 30)));
  __ cmp(R1, Operand(0x22));
  __ b(&Test2, EQ);
  __ mov(R0, Operand(1));
  __ b(&Done);
  __ Bind(&Test2);

  __ mov(R0, Operand(0));
  __ AddImmediate(R2, (-kWordSize * 30));
  __ strh(R0, Address(R2));
  __ ldrh(R1, Address(R2));
  __ cmp(R1, Operand(0));
  __ b(&Test3, EQ);
  __ mov(R0, Operand(1));
  __ b(&Done);
  __ Bind(&Test3);

  __ mov(R0, Operand(0));
  __ Bind(&Done);
  __ ldr(R1, Address(SP, (kWordSize * 30), Address::PostIndex));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Ldrh, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Ldrsb, assembler) {
  __ mov(R1, Operand(0xFF));
  __ mov(R2, Operand(SP));
  __ str(R1, Address(SP, (-kWordSize * 30), Address::PreIndex));
  __ ldrsb(R0, Address(R2, (-kWordSize * 30)));
  __ ldr(R1, Address(SP, (kWordSize * 30), Address::PostIndex));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Ldrsb, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Ldrb, assembler) {
  __ mov(R1, Operand(0xFF));
  __ mov(R2, Operand(SP));
  __ str(R1, Address(SP, (-kWordSize * 30), Address::PreIndex));
  __ ldrb(R0, Address(R2, (-kWordSize * 30)));
  __ ldr(R1, Address(SP, (kWordSize * 30), Address::PostIndex));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Ldrb, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(0xff, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Ldrsh, assembler) {
  __ mov(R1, Operand(0xFF));
  __ mov(R2, Operand(SP));
  __ str(R1, Address(SP, (-kWordSize * 30), Address::PreIndex));
  __ ldrsh(R0, Address(R2, (-kWordSize * 30)));
  __ ldr(R1, Address(SP, (kWordSize * 30), Address::PostIndex));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Ldrsh, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(0xff, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Ldrh1, assembler) {
  __ mov(R1, Operand(0xFF));
  __ mov(R2, Operand(SP));
  __ str(R1, Address(SP, (-kWordSize * 30), Address::PreIndex));
  __ ldrh(R0, Address(R2, (-kWordSize * 30)));
  __ ldr(R1, Address(SP, (kWordSize * 30), Address::PostIndex));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Ldrh1, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(0xff, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Ldrd, assembler) {
  __ mov(IP, Operand(SP));
  __ strd(R2, Address(SP, (-kWordSize * 30), Address::PreIndex));
  __ strd(R0, Address(IP, (-kWordSize * 28)));
  __ ldrd(R2, Address(IP, (-kWordSize * 28)));
  __ ldrd(R0, Address(SP, (kWordSize * 30), Address::PostIndex));
  __ sub(R0, R0, Operand(R2));
  __ add(R1, R1, Operand(R3));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Ldrd, test) {
  EXPECT(test != NULL);
  typedef int64_t (*Tst)(int64_t r0r1, int64_t r2r3) DART_UNUSED;
  EXPECT_EQ(0x0000444400002222LL, EXECUTE_TEST_CODE_INT64_LL(
      Tst, test->entry(), 0x0000111100000000LL, 0x0000333300002222LL));
}


ASSEMBLER_TEST_GENERATE(Ldm_stm_da, assembler) {
  __ mov(R0, Operand(1));
  __ mov(R1, Operand(7));
  __ mov(R2, Operand(11));
  __ mov(R3, Operand(31));
  __ Push(R5);  // We use R5 as accumulator.
  __ Push(R5);
  __ Push(R5);
  __ Push(R5);
  __ Push(R5);
  __ Push(R0);  // Make room, so we can decrement after.
  __ stm(DA_W, SP, (1 << R0 | 1 << R1 | 1 << R2 | 1 << R3));
  __ str(R2, Address(SP));                 // Should be a free slot.
  __ ldr(R5, Address(SP, 1 * kWordSize));  // R0.  R5 = +1.
  __ ldr(IP, Address(SP, 2 * kWordSize));  // R1.
  __ sub(R5, R5, Operand(IP));      // -R1. R5 = -6.
  __ ldr(IP, Address(SP, 3 * kWordSize));  // R2.
  __ add(R5, R5, Operand(IP));      // +R2. R5 = +5.
  __ ldr(IP, Address(SP, 4 * kWordSize));  // R3.
  __ sub(R5, R5, Operand(IP));      // -R3. R5 = -26.
  __ ldm(IB_W, SP, (1 << R0 | 1 << R1 | 1 << R2 | 1 << R3));
  // Same operations again. But this time from the restore registers.
  __ add(R5, R5, Operand(R0));
  __ sub(R5, R5, Operand(R1));
  __ add(R5, R5, Operand(R2));
  __ sub(R0, R5, Operand(R3));  // R0 = result = -52.
  __ Pop(R1);  // Remove storage slot.
  __ Pop(R5);  // Restore R5.
  __ Pop(R5);  // Restore R5.
  __ Pop(R5);  // Restore R5.
  __ Pop(R5);  // Restore R5.
  __ Pop(R5);  // Restore R5.
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Ldm_stm_da, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-52, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddressShiftStrLSL1NegOffset, assembler) {
  __ mov(R2, Operand(42));
  __ mov(R1, Operand(kWordSize));
  __ str(R2, Address(SP, R1, LSL, 1, Address::NegOffset));
  __ ldr(R0, Address(SP, (-kWordSize * 2), Address::Offset));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(AddressShiftStrLSL1NegOffset, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddressShiftLdrLSL5NegOffset, assembler) {
  __ mov(R2, Operand(42));
  __ mov(R1, Operand(kWordSize));
  __ str(R2, Address(SP, (-kWordSize * 32), Address::Offset));
  __ ldr(R0, Address(SP, R1, LSL, 5, Address::NegOffset));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(AddressShiftLdrLSL5NegOffset, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddressShiftStrLRS1NegOffset, assembler) {
  __ mov(R2, Operand(42));
  __ mov(R1, Operand(kWordSize * 2));
  __ str(R2, Address(SP, R1, LSR, 1, Address::NegOffset));
  __ ldr(R0, Address(SP, -kWordSize, Address::Offset));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(AddressShiftStrLRS1NegOffset, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddressShiftLdrLRS1NegOffset, assembler) {
  __ mov(R2, Operand(42));
  __ mov(R1, Operand(kWordSize * 2));
  __ str(R2, Address(SP, -kWordSize, Address::Offset));
  __ ldr(R0, Address(SP, R1, LSR, 1, Address::NegOffset));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(AddressShiftLdrLRS1NegOffset, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddressShiftStrLSLNegPreIndex, assembler) {
  __ mov(R2, Operand(42));
  __ mov(R1, Operand(kWordSize));
  __ mov(R3, Operand(SP));
  __ str(R2, Address(SP, R1, LSL, 5, Address::NegPreIndex));
  __ ldr(R0, Address(R3, (-kWordSize * 32), Address::Offset));
  __ mov(SP, Operand(R3));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(AddressShiftStrLSLNegPreIndex, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddressShiftLdrLSLNegPreIndex, assembler) {
  __ mov(R2, Operand(42));
  __ mov(R1, Operand(kWordSize));
  __ str(R2, Address(SP, (-kWordSize * 32), Address::PreIndex));
  __ ldr(R0, Address(SP, R1, LSL, 5, Address::PostIndex));
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(AddressShiftLdrLSLNegPreIndex, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


// Make sure we can store and reload the D registers using vstmd and vldmd
ASSEMBLER_TEST_GENERATE(VstmdVldmd, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ LoadDImmediate(D0, 0.0, R0);
    __ LoadDImmediate(D1, 1.0, R0);
    __ LoadDImmediate(D2, 2.0, R0);
    __ LoadDImmediate(D3, 3.0, R0);
    __ LoadDImmediate(D4, 4.0, R0);
    __ vstmd(DB_W, SP, D0, 5);  // Push D0 - D4 onto the stack, dec SP
    __ LoadDImmediate(D0, 0.0, R0);
    __ LoadDImmediate(D1, 0.0, R0);
    __ LoadDImmediate(D2, 0.0, R0);
    __ LoadDImmediate(D3, 0.0, R0);
    __ LoadDImmediate(D4, 0.0, R0);
    __ vldmd(IA_W, SP, D0, 5);  // Pop stack into D0 - D4, inc SP

    // Load success value into R0
    __ mov(R0, Operand(42));

    // Check that 4.0 is back in D4
    __ LoadDImmediate(D5, 4.0, R1);
    __ vcmpd(D4, D5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure into R0 if NE

    // Check that 3.0 is back in D3
    __ LoadDImmediate(D5, 3.0, R1);
    __ vcmpd(D3, D5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure into R0 if NE


    // Check that 2.0 is back in D2
    __ LoadDImmediate(D5, 2.0, R1);
    __ vcmpd(D2, D5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure into R0 if NE

    // Check that 1.0 is back in D1
    __ LoadDImmediate(D5, 1.0, R1);
    __ vcmpd(D1, D5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure into R0 if NE
  } else {
    __ LoadImmediate(R0, 42);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(VstmdVldmd, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


// Make sure we can store and reload the S registers using vstms and vldms
ASSEMBLER_TEST_GENERATE(VstmsVldms, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ LoadSImmediate(S0, 0.0);
    __ LoadSImmediate(S1, 1.0);
    __ LoadSImmediate(S2, 2.0);
    __ LoadSImmediate(S3, 3.0);
    __ LoadSImmediate(S4, 4.0);
    __ vstms(DB_W, SP, S0, S4);  // Push S0 - S4 onto the stack, dec SP
    __ LoadSImmediate(S0, 0.0);
    __ LoadSImmediate(S1, 0.0);
    __ LoadSImmediate(S2, 0.0);
    __ LoadSImmediate(S3, 0.0);
    __ LoadSImmediate(S4, 0.0);
    __ vldms(IA_W, SP, S0, S4);  // Pop stack into S0 - S4, inc SP

    // Load success value into R0
    __ mov(R0, Operand(42));

    // Check that 4.0 is back in S4
    __ LoadSImmediate(S5, 4.0);
    __ vcmps(S4, S5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure value into R0 if NE

    // Check that 3.0 is back in S3
    __ LoadSImmediate(S5, 3.0);
    __ vcmps(S3, S5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure value into R0 if NE

    // Check that 2.0 is back in S2
    __ LoadSImmediate(S5, 2.0);
    __ vcmps(S2, S5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure value into R0 if NE

    // Check that 1.0 is back in S1
    __ LoadSImmediate(S5, 1.0);
    __ vcmps(S1, S5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure value into R0 if NE
  } else {
    __ LoadImmediate(R0, 42);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(VstmsVldms, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


// Make sure we can start somewhere other than D0
ASSEMBLER_TEST_GENERATE(VstmdVldmd1, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ LoadDImmediate(D1, 1.0, R0);
    __ LoadDImmediate(D2, 2.0, R0);
    __ LoadDImmediate(D3, 3.0, R0);
    __ LoadDImmediate(D4, 4.0, R0);
    __ vstmd(DB_W, SP, D1, 4);  // Push D1 - D4 onto the stack, dec SP
    __ LoadDImmediate(D1, 0.0, R0);
    __ LoadDImmediate(D2, 0.0, R0);
    __ LoadDImmediate(D3, 0.0, R0);
    __ LoadDImmediate(D4, 0.0, R0);
    __ vldmd(IA_W, SP, D1, 4);  // Pop stack into D1 - D4, inc SP

    // Load success value into R0
    __ mov(R0, Operand(42));

    // Check that 4.0 is back in D4
    __ LoadDImmediate(D5, 4.0, R1);
    __ vcmpd(D4, D5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure into R0 if NE

    // Check that 3.0 is back in D3
    __ LoadDImmediate(D5, 3.0, R1);
    __ vcmpd(D3, D5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure into R0 if NE


    // Check that 2.0 is back in D2
    __ LoadDImmediate(D5, 2.0, R1);
    __ vcmpd(D2, D5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure into R0 if NE

    // Check that 1.0 is back in D1
    __ LoadDImmediate(D5, 1.0, R1);
    __ vcmpd(D1, D5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure into R0 if NE
  } else {
    __ LoadImmediate(R0, 42);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(VstmdVldmd1, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


// Make sure we can start somewhere other than S0
ASSEMBLER_TEST_GENERATE(VstmsVldms1, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ LoadSImmediate(S1, 1.0);
    __ LoadSImmediate(S2, 2.0);
    __ LoadSImmediate(S3, 3.0);
    __ LoadSImmediate(S4, 4.0);
    __ vstms(DB_W, SP, S1, S4);  // Push S0 - S4 onto the stack, dec SP
    __ LoadSImmediate(S1, 0.0);
    __ LoadSImmediate(S2, 0.0);
    __ LoadSImmediate(S3, 0.0);
    __ LoadSImmediate(S4, 0.0);
    __ vldms(IA_W, SP, S1, S4);  // Pop stack into S0 - S4, inc SP

    // Load success value into R0
    __ mov(R0, Operand(42));

    // Check that 4.0 is back in S4
    __ LoadSImmediate(S5, 4.0);
    __ vcmps(S4, S5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure value into R0 if NE

    // Check that 3.0 is back in S3
    __ LoadSImmediate(S5, 3.0);
    __ vcmps(S3, S5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure value into R0 if NE

    // Check that 2.0 is back in S2
    __ LoadSImmediate(S5, 2.0);
    __ vcmps(S2, S5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure value into R0 if NE

    // Check that 1.0 is back in S1
    __ LoadSImmediate(S5, 1.0);
    __ vcmps(S1, S5);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure value into R0 if NE
  } else {
    __ LoadImmediate(R0, 42);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(VstmsVldms1, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


// Make sure we can store the D registers using vstmd and
// load them into a different set using vldmd
ASSEMBLER_TEST_GENERATE(VstmdVldmd_off, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    // Save used callee-saved FPU registers.
    __ vstmd(DB_W, SP, D8, 3);
    __ LoadDImmediate(D0, 0.0, R0);
    __ LoadDImmediate(D1, 1.0, R0);
    __ LoadDImmediate(D2, 2.0, R0);
    __ LoadDImmediate(D3, 3.0, R0);
    __ LoadDImmediate(D4, 4.0, R0);
    __ LoadDImmediate(D5, 5.0, R0);
    __ vstmd(DB_W, SP, D0, 5);  // Push D0 - D4 onto the stack, dec SP
    __ vldmd(IA_W, SP, D5, 5);  // Pop stack into D5 - D9, inc SP

    // Load success value into R0
    __ mov(R0, Operand(42));

    // Check that 4.0 is in D9
    __ LoadDImmediate(D10, 4.0, R1);
    __ vcmpd(D9, D10);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure into R0 if NE

    // Check that 3.0 is in D8
    __ LoadDImmediate(D10, 3.0, R1);
    __ vcmpd(D8, D10);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure into R0 if NE


    // Check that 2.0 is in D7
    __ LoadDImmediate(D10, 2.0, R1);
    __ vcmpd(D7, D10);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure into R0 if NE

    // Check that 1.0 is in D6
    __ LoadDImmediate(D10, 1.0, R1);
    __ vcmpd(D6, D10);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure into R0 if NE

    // Check that 0.0 is in D5
    __ LoadDImmediate(D10, 0.0, R1);
    __ vcmpd(D5, D10);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure into R0 if NE

    // Restore used callee-saved FPU registers.
    __ vldmd(IA_W, SP, D8, 3);
  } else {
    __ LoadImmediate(R0, 42);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(VstmdVldmd_off, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


// Make sure we can start somewhere other than S0
ASSEMBLER_TEST_GENERATE(VstmsVldms_off, assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ LoadSImmediate(S0, 0.0);
    __ LoadSImmediate(S1, 1.0);
    __ LoadSImmediate(S2, 2.0);
    __ LoadSImmediate(S3, 3.0);
    __ LoadSImmediate(S4, 4.0);
    __ LoadSImmediate(S5, 5.0);
    __ vstms(DB_W, SP, S0, S4);  // Push S0 - S4 onto the stack, dec SP
    __ vldms(IA_W, SP, S5, S9);  // Pop stack into S5 - S9, inc SP

    // Load success value into R0
    __ mov(R0, Operand(42));

    // Check that 4.0 is in S9
    __ LoadSImmediate(S10, 4.0);
    __ vcmps(S9, S10);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure value into R0 if NE

    // Check that 3.0 is in S8
    __ LoadSImmediate(S10, 3.0);
    __ vcmps(S8, S10);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure value into R0 if NE

    // Check that 2.0 is in S7
    __ LoadSImmediate(S10, 2.0);
    __ vcmps(S7, S10);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure value into R0 if NE

    // Check that 1.0 is back in S6
    __ LoadSImmediate(S10, 1.0);
    __ vcmps(S6, S10);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure value into R0 if NE

    // Check that 0.0 is back in S5
    __ LoadSImmediate(S10, 0.0);
    __ vcmps(S5, S10);
    __ vmstat();
    __ mov(R0, Operand(0), NE);  // Put failure value into R0 if NE
  } else {
    __ LoadImmediate(R0, 42);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(VstmsVldms_off, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Udiv, assembler) {
  if (TargetCPUFeatures::integer_division_supported()) {
    __ mov(R0, Operand(27));
    __ mov(R1, Operand(9));
    __ udiv(R2, R0, R1);
    __ mov(R0, Operand(R2));
  } else {
    __ mov(R0, Operand(3));
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Udiv, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(3, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Sdiv, assembler) {
  if (TargetCPUFeatures::integer_division_supported()) {
    __ mov(R0, Operand(27));
    __ LoadImmediate(R1, -9);
    __ sdiv(R2, R0, R1);
    __ mov(R0, Operand(R2));
  } else {
    __ LoadImmediate(R0, -3);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Sdiv, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-3, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Udiv_zero, assembler) {
  if (TargetCPUFeatures::integer_division_supported()) {
    __ mov(R0, Operand(27));
    __ mov(R1, Operand(0));
    __ udiv(R2, R0, R1);
    __ mov(R0, Operand(R2));
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Udiv_zero, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Sdiv_zero, assembler) {
  if (TargetCPUFeatures::integer_division_supported()) {
    __ mov(R0, Operand(27));
    __ mov(R1, Operand(0));
    __ sdiv(R2, R0, R1);
    __ mov(R0, Operand(R2));
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Sdiv_zero, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Udiv_corner, assembler) {
  if (TargetCPUFeatures::integer_division_supported()) {
    __ LoadImmediate(R0, 0x80000000);
    __ LoadImmediate(R1, 0xffffffff);
    __ udiv(R2, R0, R1);
    __ mov(R0, Operand(R2));
  } else {
    __ LoadImmediate(R0, 0);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Udiv_corner, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Sdiv_corner, assembler) {
  if (TargetCPUFeatures::integer_division_supported()) {
    __ LoadImmediate(R0, 0x80000000);
    __ LoadImmediate(R1, 0xffffffff);
    __ sdiv(R2, R0, R1);
    __ mov(R0, Operand(R2));
  } else {
    __ LoadImmediate(R0, 0x80000000);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Sdiv_corner, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(static_cast<int32_t>(0x80000000),
            EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(IntDiv_supported, assembler) {
#if defined(USING_SIMULATOR)
  bool orig = TargetCPUFeatures::integer_division_supported();
  HostCPUFeatures::set_integer_division_supported(true);
  __ mov(R0, Operand(27));
  __ mov(R1, Operand(9));
  __ IntegerDivide(R0, R0, R1, D0, D1);
  HostCPUFeatures::set_integer_division_supported(orig);
  __ bx(LR);
#else
  __ mov(R0, Operand(27));
  __ mov(R1, Operand(9));
  __ IntegerDivide(R0, R0, R1, D0, D1);
  __ bx(LR);
#endif
}


ASSEMBLER_TEST_RUN(IntDiv_supported, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(3, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(IntDiv_unsupported, assembler) {
#if defined(USING_SIMULATOR)
  bool orig = TargetCPUFeatures::integer_division_supported();
  HostCPUFeatures::set_integer_division_supported(false);
  __ mov(R0, Operand(27));
  __ mov(R1, Operand(9));
  __ IntegerDivide(R0, R0, R1, D0, D1);
  HostCPUFeatures::set_integer_division_supported(orig);
  __ bx(LR);
#else
  __ mov(R0, Operand(27));
  __ mov(R1, Operand(9));
  __ IntegerDivide(R0, R0, R1, D0, D1);
  __ bx(LR);
#endif
}


ASSEMBLER_TEST_RUN(IntDiv_unsupported, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(3, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Muls, assembler) {
  __ mov(R0, Operand(3));
  __ LoadImmediate(R1, -9);
  __ muls(R2, R0, R1);
  __ mov(R0, Operand(42), MI);
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Muls, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vaddqi8, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ mov(R0, Operand(5));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(6));
    __ vmovsr(S5, R0);
    __ mov(R0, Operand(7));
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(8));
    __ vmovsr(S7, R0);

    __ vaddqi(kByte, Q2, Q0, Q1);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 36);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vaddqi8, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(36, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vaddqi16, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ mov(R0, Operand(5));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(6));
    __ vmovsr(S5, R0);
    __ mov(R0, Operand(7));
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(8));
    __ vmovsr(S7, R0);

    __ vaddqi(kHalfword, Q2, Q0, Q1);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 36);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vaddqi16, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(36, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vaddqi32, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ mov(R0, Operand(5));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(6));
    __ vmovsr(S5, R0);
    __ mov(R0, Operand(7));
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(8));
    __ vmovsr(S7, R0);

    __ vaddqi(kWord, Q2, Q0, Q1);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 36);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vaddqi32, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(36, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vaddqi64, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S6, R0);

    __ vaddqi(kWordPair, Q2, Q0, Q1);

    __ vmovrs(R0, S8);
    __ vmovrs(R2, S10);

    __ add(R0, R0, Operand(R2));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 10);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vaddqi64, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(10, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vshlqu64, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    Label fail;
    __ LoadImmediate(R1, 21);
    __ LoadImmediate(R0, 1);
    __ vmovsr(S0, R1);
    __ vmovsr(S2, R1);
    __ vmovsr(S4, R0);
    __ vmovsr(S6, R0);

    __ vshlqu(kWordPair, Q2, Q0, Q1);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S10);
    __ CompareImmediate(R0, 42);
    __ LoadImmediate(R0, 0);
    __ b(&fail, NE);
    __ CompareImmediate(R1, 42);
    __ LoadImmediate(R0, 0);
    __ b(&fail, NE);

    __ LoadImmediate(R0, 1);
    __ Bind(&fail);
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 1);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vshlqu64, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vshlqi64, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    Label fail;
    __ LoadImmediate(R1, -84);
    __ LoadImmediate(R0, -1);
    __ vmovdrr(D0, R1, R0);
    __ vmovdrr(D1, R1, R0);
    __ vmovsr(S4, R0);
    __ vmovsr(S6, R0);

    __ vshlqi(kWordPair, Q2, Q0, Q1);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S10);
    __ CompareImmediate(R0, -42);
    __ LoadImmediate(R0, 0);
    __ b(&fail, NE);
    __ CompareImmediate(R1, -42);
    __ LoadImmediate(R0, 0);
    __ b(&fail, NE);

    __ LoadImmediate(R0, 1);
    __ Bind(&fail);
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 1);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vshlqi64, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Mint_shl_ok, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    const QRegister value = Q0;
    const QRegister temp = Q1;
    const QRegister out = Q2;
    const Register shift = R1;
    const DRegister dtemp0 = EvenDRegisterOf(temp);
    const SRegister stemp0 = EvenSRegisterOf(dtemp0);
    const DRegister dout0 = EvenDRegisterOf(out);
    const SRegister sout0 = EvenSRegisterOf(dout0);
    const SRegister sout1 = OddSRegisterOf(dout0);
    Label fail;

    // Initialize.
    __ veorq(value, value, value);
    __ veorq(temp, temp, temp);
    __ veorq(out, out, out);
    __ LoadImmediate(shift, 32);
    __ LoadImmediate(R2, 1 << 7);
    __ vmovsr(S0, R2);

    __ vmovsr(stemp0, shift);  // Move the shift into the low S register.
    __ vshlqu(kWordPair, out, value, temp);

    // check for overflow by shifting back and comparing.
    __ rsb(shift, shift, Operand(0));
    __ vmovsr(stemp0, shift);
    __ vshlqi(kWordPair, temp, out, temp);
    __ vceqqi(kWord, out, temp, value);
    // Low 64 bits of temp should be all 1's, otherwise temp != value and
    // we deopt.
    __ vmovrs(shift, sout0);
    __ CompareImmediate(shift, -1);
    __ b(&fail, NE);
    __ vmovrs(shift, sout1);
    __ CompareImmediate(shift, -1);
    __ b(&fail, NE);

    __ LoadImmediate(R0, 1);
    __ bx(LR);

    __ Bind(&fail);
    __ LoadImmediate(R0, 0);
  } else {
    __ LoadImmediate(R0, 1);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Mint_shl_ok, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Mint_shl_overflow, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    const QRegister value = Q0;
    const QRegister temp = Q1;
    const QRegister out = Q2;
    const Register shift = R1;
    const DRegister dtemp0 = EvenDRegisterOf(temp);
    const SRegister stemp0 = EvenSRegisterOf(dtemp0);
    const DRegister dout0 = EvenDRegisterOf(out);
    const SRegister sout0 = EvenSRegisterOf(dout0);
    const SRegister sout1 = OddSRegisterOf(dout0);
    Label fail;

    // Initialize.
    __ veorq(value, value, value);
    __ veorq(temp, temp, temp);
    __ veorq(out, out, out);
    __ LoadImmediate(shift, 60);
    __ LoadImmediate(R2, 1 << 7);
    __ vmovsr(S0, R2);

    __ vmovsr(stemp0, shift);  // Move the shift into the low S register.
    __ vshlqu(kWordPair, out, value, temp);

    // check for overflow by shifting back and comparing.
    __ rsb(shift, shift, Operand(0));
    __ vmovsr(stemp0, shift);
    __ vshlqi(kWordPair, temp, out, temp);
    __ vceqqi(kWord, out, temp, value);
    // Low 64 bits of temp should be all 1's, otherwise temp != value and
    // we deopt.
    __ vmovrs(shift, sout0);
    __ CompareImmediate(shift, -1);
    __ b(&fail, NE);
    __ vmovrs(shift, sout1);
    __ CompareImmediate(shift, -1);
    __ b(&fail, NE);

    __ LoadImmediate(R0, 0);
    __ bx(LR);

    __ Bind(&fail);
    __ LoadImmediate(R0, 1);
  } else {
    __ LoadImmediate(R0, 1);
  }
  __ bx(LR);
}


ASSEMBLER_TEST_RUN(Mint_shl_overflow, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vsubqi8, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S5, R0);
    __ mov(R0, Operand(6));
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(8));
    __ vmovsr(S7, R0);

    __ vsubqi(kByte, Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 10);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vsubqi8, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(10, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vsubqi16, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S5, R0);
    __ mov(R0, Operand(6));
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(8));
    __ vmovsr(S7, R0);

    __ vsubqi(kHalfword, Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 10);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vsubqi16, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(10, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vsubqi32, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S5, R0);
    __ mov(R0, Operand(6));
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(8));
    __ vmovsr(S7, R0);

    __ vsubqi(kWord, Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 10);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vsubqi32, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(10, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vsubqi64, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S6, R0);

    __ vsubqi(kWordPair, Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R2, S10);

    __ add(R0, R0, Operand(R2));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 3);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vsubqi64, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(3, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vmulqi8, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ mov(R0, Operand(5));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(6));
    __ vmovsr(S5, R0);
    __ mov(R0, Operand(7));
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(8));
    __ vmovsr(S7, R0);

    __ vmulqi(kByte, Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 70);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vmulqi8, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(70, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vmulqi16, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ mov(R0, Operand(5));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(6));
    __ vmovsr(S5, R0);
    __ mov(R0, Operand(7));
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(8));
    __ vmovsr(S7, R0);

    __ vmulqi(kHalfword, Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 70);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vmulqi16, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(70, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vmulqi32, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ mov(R0, Operand(5));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(6));
    __ vmovsr(S5, R0);
    __ mov(R0, Operand(7));
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(8));
    __ vmovsr(S7, R0);

    __ vmulqi(kWord, Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 70);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vmulqi32, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(70, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vaddqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S0, 1.0);
    __ LoadSImmediate(S1, 2.0);
    __ LoadSImmediate(S2, 3.0);
    __ LoadSImmediate(S3, 4.0);
    __ LoadSImmediate(S4, 5.0);
    __ LoadSImmediate(S5, 6.0);
    __ LoadSImmediate(S6, 7.0);
    __ LoadSImmediate(S7, 8.0);

    __ vaddqs(Q2, Q0, Q1);

    __ vadds(S8, S8, S9);
    __ vadds(S8, S8, S10);
    __ vadds(S8, S8, S11);

    __ vcvtis(S0, S8);
    __ vmovrs(R0, S0);

    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 36);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vaddqs, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(36, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vsubqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S0, 1.0);
    __ LoadSImmediate(S1, 2.0);
    __ LoadSImmediate(S2, 3.0);
    __ LoadSImmediate(S3, 4.0);
    __ LoadSImmediate(S4, 2.0);
    __ LoadSImmediate(S5, 4.0);
    __ LoadSImmediate(S6, 6.0);
    __ LoadSImmediate(S7, 8.0);

    __ vsubqs(Q2, Q1, Q0);

    __ vadds(S8, S8, S9);
    __ vadds(S8, S8, S10);
    __ vadds(S8, S8, S11);

    __ vcvtis(S0, S8);
    __ vmovrs(R0, S0);

    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 10);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vsubqs, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(10, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vmulqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S0, 1.0);
    __ LoadSImmediate(S1, 2.0);
    __ LoadSImmediate(S2, 3.0);
    __ LoadSImmediate(S3, 4.0);
    __ LoadSImmediate(S4, 5.0);
    __ LoadSImmediate(S5, 6.0);
    __ LoadSImmediate(S6, 7.0);
    __ LoadSImmediate(S7, 8.0);

    __ vmulqs(Q2, Q1, Q0);

    __ vadds(S8, S8, S9);
    __ vadds(S8, S8, S10);
    __ vadds(S8, S8, S11);

    __ vcvtis(S0, S8);
    __ vmovrs(R0, S0);

    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 70);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vmulqs, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(70, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(VtblX, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    // Index.
    __ LoadImmediate(R0, 0x03020100);
    __ vmovsr(S0, R0);
    __ vmovsr(S1, R0);

    // Table.
    __ LoadSImmediate(S2, 1.0);
    __ LoadSImmediate(S3, 2.0);
    __ LoadSImmediate(S4, 3.0);
    __ LoadSImmediate(S5, 4.0);

    // Select.
    __ vtbl(D3, D1, 2, D0);

    // Check that S6, S7 are both 1.0
    __ vcvtis(S0, S6);
    __ vcvtis(S1, S7);
    __ vmovrs(R2, S0);
    __ vmovrs(R3, S1);

    __ LoadImmediate(R0, 0);
    __ CompareImmediate(R2, 1);
    __ bx(LR, NE);
    __ CompareImmediate(R3, 1);
    __ bx(LR, NE);
    __ LoadImmediate(R0, 42);
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 42);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(VtblX, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(VtblY, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    // Index.
    __ LoadImmediate(R0, 0x07060504);
    __ vmovsr(S0, R0);
    __ vmovsr(S1, R0);

    // Table.
    __ LoadSImmediate(S2, 2.0);
    __ LoadSImmediate(S3, 1.0);
    __ LoadSImmediate(S4, 3.0);
    __ LoadSImmediate(S5, 4.0);

    // Select.
    __ vtbl(D3, D1, 2, D0);

    // Check that S6, S7 are both 1.0
    __ vcvtis(S0, S6);
    __ vcvtis(S1, S7);
    __ vmovrs(R2, S0);
    __ vmovrs(R3, S1);

    __ LoadImmediate(R0, 0);
    __ CompareImmediate(R2, 1);
    __ bx(LR, NE);
    __ CompareImmediate(R3, 1);
    __ bx(LR, NE);
    __ LoadImmediate(R0, 42);
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 42);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(VtblY, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(VtblZ, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    // Index.
    __ LoadImmediate(R0, 0x0b0a0908);
    __ vmovsr(S0, R0);
    __ vmovsr(S1, R0);

    // Table.
    __ LoadSImmediate(S2, 2.0);
    __ LoadSImmediate(S3, 3.0);
    __ LoadSImmediate(S4, 1.0);
    __ LoadSImmediate(S5, 4.0);

    // Select.
    __ vtbl(D3, D1, 2, D0);

    // Check that S6, S7 are both 1.0
    __ vcvtis(S0, S6);
    __ vcvtis(S1, S7);
    __ vmovrs(R2, S0);
    __ vmovrs(R3, S1);

    __ LoadImmediate(R0, 0);
    __ CompareImmediate(R2, 1);
    __ bx(LR, NE);
    __ CompareImmediate(R3, 1);
    __ bx(LR, NE);
    __ LoadImmediate(R0, 42);
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 42);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(VtblZ, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(VtblW, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    // Index.
    __ LoadImmediate(R0, 0x0f0e0d0c);
    __ vmovsr(S0, R0);
    __ vmovsr(S1, R0);

    // Table.
    __ LoadSImmediate(S2, 2.0);
    __ LoadSImmediate(S3, 3.0);
    __ LoadSImmediate(S4, 4.0);
    __ LoadSImmediate(S5, 1.0);

    // Select.
    __ vtbl(D3, D1, 2, D0);

    // Check that S6, S7 are both 1.0
    __ vcvtis(S0, S6);
    __ vcvtis(S1, S7);
    __ vmovrs(R2, S0);
    __ vmovrs(R3, S1);

    __ LoadImmediate(R0, 0);
    __ CompareImmediate(R2, 1);
    __ bx(LR, NE);
    __ CompareImmediate(R3, 1);
    __ bx(LR, NE);
    __ LoadImmediate(R0, 42);
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 42);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(VtblW, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Veorq, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    // Q0
    __ LoadImmediate(R0, 0xaaaaaaab);
    __ vmovsr(S0, R0);
    __ vmovsr(S1, R0);
    __ vmovsr(S2, R0);
    __ vmovsr(S3, R0);

    // Q1
    __ LoadImmediate(R0, 0x55555555);
    __ vmovsr(S4, R0);
    __ vmovsr(S5, R0);
    __ vmovsr(S6, R0);
    __ vmovsr(S7, R0);

    // Q2 = -2 -2 -2 -2
    __ veorq(Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, -8);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Veorq, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-8, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vornq, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    // Q0
    __ LoadImmediate(R0, 0xfffffff0);
    __ vmovsr(S0, R0);
    __ vmovsr(S1, R0);
    __ vmovsr(S2, R0);
    __ vmovsr(S3, R0);

    // Q1
    __ LoadImmediate(R0, 0);
    __ vmovsr(S4, R0);
    __ vmovsr(S5, R0);
    __ vmovsr(S6, R0);
    __ vmovsr(S7, R0);

    // Q2 = 15 15 15 15
    __ vornq(Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 60);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vornq, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(60, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vorrq, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    // Q0
    __ LoadImmediate(R0, 0xaaaaaaaa);
    __ vmovsr(S0, R0);
    __ vmovsr(S1, R0);
    __ vmovsr(S2, R0);
    __ vmovsr(S3, R0);

    // Q1
    __ LoadImmediate(R0, 0x55555555);
    __ vmovsr(S4, R0);
    __ vmovsr(S5, R0);
    __ vmovsr(S6, R0);
    __ vmovsr(S7, R0);

    // Q2 = -1 -1 -1 -1
    __ vorrq(Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, -4);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vorrq, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-4, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vandq, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    // Q0
    __ LoadImmediate(R0, 0xaaaaaaab);
    __ vmovsr(S0, R0);
    __ vmovsr(S1, R0);
    __ vmovsr(S2, R0);
    __ vmovsr(S3, R0);

    // Q1
    __ LoadImmediate(R0, 0x55555555);
    __ vmovsr(S4, R0);
    __ vmovsr(S5, R0);
    __ vmovsr(S6, R0);
    __ vmovsr(S7, R0);

    // Q2 = 1 1 1 1
    __ vandq(Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 4);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vandq, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(4, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vmovq, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    // Q0
    __ LoadSImmediate(S0, 1.0);
    __ vmovs(S1, S0);
    __ vmovs(S2, S0);
    __ vmovs(S3, S0);

    // Q0
    __ LoadSImmediate(S4, -1.0);
    __ vmovs(S5, S0);
    __ vmovs(S6, S0);
    __ vmovs(S7, S0);

    // Q1 = Q2
    __ vmovq(Q1, Q0);

    __ vadds(S4, S4, S5);
    __ vadds(S4, S4, S6);
    __ vadds(S4, S4, S7);
    __ vcvtis(S0, S4);
    __ vmovrs(R0, S0);

    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 4);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vmovq, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(4, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vmvnq, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadImmediate(R1, 42);  // R1 <- 42.
    __ vmovsr(S2, R1);  // S2 <- R1.
    __ vmvnq(Q1, Q0);  // Q1 <- ~Q0.
    __ vmvnq(Q2, Q1);  // Q2 <- ~Q1.
    __ vmovrs(R0, S10);  // Now R0 should be 42 again.
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 42);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vmvnq, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vdupb, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadImmediate(R0, 0x00000000);
    __ LoadImmediate(R1, 0x00ff0000);
    __ vmovsr(S4, R0);
    __ vmovsr(S5, R1);

    // Should copy 0xff to each byte of Q0.
    __ vdup(kByte, Q0, D2, 6);

    __ vmovrs(R0, S0);
    __ vmovrs(R1, S1);
    __ vmovrs(R2, S2);
    __ vmovrs(R3, S3);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, -4);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vdupb, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-4, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vduph, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadImmediate(R0, 0xffff0000);
    __ LoadImmediate(R1, 0x00000000);
    __ vmovsr(S4, R0);
    __ vmovsr(S5, R1);

    // Should copy 0xff to each byte of Q0.
    __ vdup(kHalfword, Q0, D2, 1);

    __ vmovrs(R0, S0);
    __ vmovrs(R1, S1);
    __ vmovrs(R2, S2);
    __ vmovrs(R3, S3);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, -4);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vduph, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-4, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vdupw, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadImmediate(R0, 0x00000000);
    __ LoadImmediate(R1, 0xffffffff);
    __ vmovsr(S4, R0);
    __ vmovsr(S5, R1);

    // Should copy 0xff to each byte of Q0.
    __ vdup(kWord, Q0, D2, 1);

    __ vmovrs(R0, S0);
    __ vmovrs(R1, S1);
    __ vmovrs(R2, S2);
    __ vmovrs(R3, S3);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, -4);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vdupw, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-4, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vzipqw, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S0, 0.0);
    __ LoadSImmediate(S1, 1.0);
    __ LoadSImmediate(S2, 2.0);
    __ LoadSImmediate(S3, 3.0);
    __ LoadSImmediate(S4, 4.0);
    __ LoadSImmediate(S5, 5.0);
    __ LoadSImmediate(S6, 6.0);
    __ LoadSImmediate(S7, 7.0);

    __ vzipqw(Q0, Q1);

    __ vsubqs(Q0, Q1, Q0);

    __ vadds(S0, S0, S1);
    __ vadds(S0, S0, S2);
    __ vadds(S0, S0, S3);
    __ bx(LR);
  } else {
    __ LoadSImmediate(S0, 8.0);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vzipqw, test) {
  EXPECT(test != NULL);
  typedef float (*Vzipqw)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_FLOAT(Vzipqw, test->entry());
  EXPECT_FLOAT_EQ(8.0, res, 0.0001f);
}


ASSEMBLER_TEST_GENERATE(Vceqqi32, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ mov(R0, Operand(1));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(20));
    __ vmovsr(S5, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(40));
    __ vmovsr(S7, R0);

    __ vceqqi(kWord, Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, -2);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vceqqi32, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-2, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vceqqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S0, 1.0);
    __ LoadSImmediate(S1, 2.0);
    __ LoadSImmediate(S2, 3.0);
    __ LoadSImmediate(S3, 4.0);
    __ LoadSImmediate(S4, 1.0);
    __ LoadSImmediate(S5, 4.0);
    __ LoadSImmediate(S6, 3.0);
    __ LoadSImmediate(S7, 8.0);

    __ vceqqs(Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, -2);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vceqqs, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-2, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vcgeqi32, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ mov(R0, Operand(1));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(1));
    __ vmovsr(S5, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(1));
    __ vmovsr(S7, R0);

    __ vcgeqi(kWord, Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, -2);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vcgeqi32, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-2, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vcugeqi32, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ LoadImmediate(R0, -1);
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(1));
    __ vmovsr(S5, R0);
    __ LoadImmediate(R0, -3);
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(1));
    __ vmovsr(S7, R0);

    __ vcugeqi(kWord, Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, -2);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vcugeqi32, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-2, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vcgeqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S0, 1.0);
    __ LoadSImmediate(S1, 2.0);
    __ LoadSImmediate(S2, 3.0);
    __ LoadSImmediate(S3, 4.0);
    __ LoadSImmediate(S4, 1.0);
    __ LoadSImmediate(S5, 1.0);
    __ LoadSImmediate(S6, 3.0);
    __ LoadSImmediate(S7, 1.0);

    __ vcgeqs(Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, -2);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vcgeqs, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-2, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vcgtqi32, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(1));
    __ vmovsr(S5, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(1));
    __ vmovsr(S7, R0);

    __ vcgtqi(kWord, Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, -2);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vcgtqi32, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-2, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vcugtqi32, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ mov(R0, Operand(1));
    __ vmovsr(S0, R0);
    __ mov(R0, Operand(2));
    __ vmovsr(S1, R0);
    __ mov(R0, Operand(3));
    __ vmovsr(S2, R0);
    __ mov(R0, Operand(4));
    __ vmovsr(S3, R0);
    __ LoadImmediate(R0, -1);
    __ vmovsr(S4, R0);
    __ mov(R0, Operand(1));
    __ vmovsr(S5, R0);
    __ LoadImmediate(R0, -3);
    __ vmovsr(S6, R0);
    __ mov(R0, Operand(1));
    __ vmovsr(S7, R0);

    __ vcugtqi(kWord, Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, -2);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vcugtqi32, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-2, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vcgtqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S0, 1.0);
    __ LoadSImmediate(S1, 2.0);
    __ LoadSImmediate(S2, 3.0);
    __ LoadSImmediate(S3, 4.0);
    __ LoadSImmediate(S4, 2.0);
    __ LoadSImmediate(S5, 1.0);
    __ LoadSImmediate(S6, 4.0);
    __ LoadSImmediate(S7, 1.0);

    __ vcgtqs(Q2, Q1, Q0);

    __ vmovrs(R0, S8);
    __ vmovrs(R1, S9);
    __ vmovrs(R2, S10);
    __ vmovrs(R3, S11);

    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R2));
    __ add(R0, R0, Operand(R3));
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, -2);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vcgtqs, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(-2, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vminqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S0, 1.0);
    __ LoadSImmediate(S1, 2.0);
    __ LoadSImmediate(S2, 3.0);
    __ LoadSImmediate(S3, 4.0);

    __ LoadSImmediate(S4, 2.0);
    __ LoadSImmediate(S5, 1.0);
    __ LoadSImmediate(S6, 6.0);
    __ LoadSImmediate(S7, 3.0);

    __ vminqs(Q2, Q1, Q0);

    __ vadds(S8, S8, S9);
    __ vadds(S8, S8, S10);
    __ vadds(S8, S8, S11);

    __ vcvtis(S0, S8);
    __ vmovrs(R0, S0);
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 8);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vminqs, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(8, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Vmaxqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S0, 1.0);
    __ LoadSImmediate(S1, 2.0);
    __ LoadSImmediate(S2, 3.0);
    __ LoadSImmediate(S3, 4.0);

    __ LoadSImmediate(S4, 2.0);
    __ LoadSImmediate(S5, 1.0);
    __ LoadSImmediate(S6, 6.0);
    __ LoadSImmediate(S7, 3.0);

    __ vmaxqs(Q2, Q1, Q0);

    __ vadds(S8, S8, S9);
    __ vadds(S8, S8, S10);
    __ vadds(S8, S8, S11);

    __ vcvtis(S0, S8);
    __ vmovrs(R0, S0);
    __ bx(LR);
  } else {
    __ LoadImmediate(R0, 14);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vmaxqs, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(14, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


// This is the same function as in the Simulator.
static float arm_recip_estimate(float a) {
  // From the ARM Architecture Reference Manual A2-85.
  if (isinf(a) || (fabs(a) >= exp2f(126))) return 0.0;
  else if (a == 0.0) return kPosInfinity;
  else if (isnan(a)) return a;

  uint32_t a_bits = bit_cast<uint32_t, float>(a);
  // scaled = '0011 1111 1110' : a<22:0> : Zeros(29)
  uint64_t scaled = (static_cast<uint64_t>(0x3fe) << 52) |
                    ((static_cast<uint64_t>(a_bits) & 0x7fffff) << 29);
  // result_exp = 253 - UInt(a<30:23>)
  int32_t result_exp = 253 - ((a_bits >> 23) & 0xff);
  ASSERT((result_exp >= 1) && (result_exp <= 252));

  double scaled_d = bit_cast<double, uint64_t>(scaled);
  ASSERT((scaled_d >= 0.5) && (scaled_d < 1.0));

  // a in units of 1/512 rounded down.
  int32_t q = static_cast<int32_t>(scaled_d * 512.0);
  // reciprocal r.
  double r = 1.0 / ((static_cast<double>(q) + 0.5) / 512.0);
  // r in units of 1/256 rounded to nearest.
  int32_t s = static_cast<int32_t>(256.0 * r + 0.5);
  double estimate = static_cast<double>(s) / 256.0;
  ASSERT((estimate >= 1.0) && (estimate <= (511.0/256.0)));

  // result = sign : result_exp<7:0> : estimate<51:29>
  int32_t result_bits =
      (a_bits & 0x80000000) | ((result_exp & 0xff) << 23) |
      ((bit_cast<uint64_t, double>(estimate) >> 29) & 0x7fffff);
  return bit_cast<float, int32_t>(result_bits);
}


ASSEMBLER_TEST_GENERATE(Vrecpeqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S4, 147.0);
    __ vmovs(S5, S4);
    __ vmovs(S6, S4);
    __ vmovs(S7, S4);

    __ vrecpeqs(Q0, Q1);

    __ bx(LR);
  } else {
    __ LoadSImmediate(S0, arm_recip_estimate(147.0));
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vrecpeqs, test) {
  EXPECT(test != NULL);
  typedef float (*Vrecpeqs)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_FLOAT(Vrecpeqs, test->entry());
  EXPECT_FLOAT_EQ(arm_recip_estimate(147.0), res, 0.0001f);
}


ASSEMBLER_TEST_GENERATE(Vrecpsqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S4, 5.0);
    __ LoadSImmediate(S5, 2.0);
    __ LoadSImmediate(S6, 3.0);
    __ LoadSImmediate(S7, 4.0);

    __ LoadSImmediate(S8, 10.0);
    __ LoadSImmediate(S9, 1.0);
    __ LoadSImmediate(S10, 6.0);
    __ LoadSImmediate(S11, 3.0);

    __ vrecpsqs(Q0, Q1, Q2);

    __ bx(LR);
  } else {
    __ LoadSImmediate(S0, 2.0 - 10.0 * 5.0);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vrecpsqs, test) {
  EXPECT(test != NULL);
  typedef float (*Vrecpsqs)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_FLOAT(Vrecpsqs, test->entry());
  EXPECT_FLOAT_EQ(2.0 - 10.0 * 5.0, res, 0.0001f);
}


ASSEMBLER_TEST_GENERATE(Reciprocal, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S4, 147000.0);
    __ vmovs(S5, S4);
    __ vmovs(S6, S4);
    __ vmovs(S7, S4);

    // Reciprocal estimate.
    __ vrecpeqs(Q0, Q1);
    // 2 Newton-Raphson steps.
    __ vrecpsqs(Q2, Q1, Q0);
    __ vmulqs(Q0, Q0, Q2);
    __ vrecpsqs(Q2, Q1, Q0);
    __ vmulqs(Q0, Q0, Q2);

    __ bx(LR);
  } else {
    __ LoadSImmediate(S0, 1.0/147000.0);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Reciprocal, test) {
  EXPECT(test != NULL);
  typedef float (*Reciprocal)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_FLOAT(Reciprocal, test->entry());
  EXPECT_FLOAT_EQ(1.0/147000.0, res, 0.0001f);
}


static float arm_reciprocal_sqrt_estimate(float a) {
  // From the ARM Architecture Reference Manual A2-87.
  if (isinf(a) || (fabs(a) >= exp2f(126))) return 0.0;
  else if (a == 0.0) return kPosInfinity;
  else if (isnan(a)) return a;

  uint32_t a_bits = bit_cast<uint32_t, float>(a);
  uint64_t scaled;
  if (((a_bits >> 23) & 1) != 0) {
    // scaled = '0 01111111101' : operand<22:0> : Zeros(29)
    scaled = (static_cast<uint64_t>(0x3fd) << 52) |
             ((static_cast<uint64_t>(a_bits) & 0x7fffff) << 29);
  } else {
    // scaled = '0 01111111110' : operand<22:0> : Zeros(29)
    scaled = (static_cast<uint64_t>(0x3fe) << 52) |
             ((static_cast<uint64_t>(a_bits) & 0x7fffff) << 29);
  }
  // result_exp = (380 - UInt(operand<30:23>) DIV 2;
  int32_t result_exp = (380 - ((a_bits >> 23) & 0xff)) / 2;

  double scaled_d = bit_cast<double, uint64_t>(scaled);
  ASSERT((scaled_d >= 0.25) && (scaled_d < 1.0));

  double r;
  if (scaled_d < 0.5) {
    // range 0.25 <= a < 0.5

    // a in units of 1/512 rounded down.
    int32_t q0 = static_cast<int32_t>(scaled_d * 512.0);
    // reciprocal root r.
    r = 1.0 / sqrt((static_cast<double>(q0) + 0.5) / 512.0);
  } else {
    // range 0.5 <= a < 1.0

    // a in units of 1/256 rounded down.
    int32_t q1 = static_cast<int32_t>(scaled_d * 256.0);
    // reciprocal root r.
    r = 1.0 / sqrt((static_cast<double>(q1) + 0.5) / 256.0);
  }
  // r in units of 1/256 rounded to nearest.
  int32_t s = static_cast<int>(256.0 * r + 0.5);
  double estimate = static_cast<double>(s) / 256.0;
  ASSERT((estimate >= 1.0) && (estimate <= (511.0/256.0)));

  // result = 0 : result_exp<7:0> : estimate<51:29>
  int32_t result_bits = ((result_exp & 0xff) << 23) |
      ((bit_cast<uint64_t, double>(estimate) >> 29) & 0x7fffff);
  return bit_cast<float, int32_t>(result_bits);
}


ASSEMBLER_TEST_GENERATE(Vrsqrteqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S4, 147.0);
    __ vmovs(S5, S4);
    __ vmovs(S6, S4);
    __ vmovs(S7, S4);

    __ vrsqrteqs(Q0, Q1);

    __ bx(LR);
  } else {
    __ LoadSImmediate(S0, arm_reciprocal_sqrt_estimate(147.0));
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vrsqrteqs, test) {
  EXPECT(test != NULL);
  typedef float (*Vrsqrteqs)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_FLOAT(Vrsqrteqs, test->entry());
  EXPECT_FLOAT_EQ(arm_reciprocal_sqrt_estimate(147.0), res, 0.0001f);
}


ASSEMBLER_TEST_GENERATE(Vrsqrtsqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S4, 5.0);
    __ LoadSImmediate(S5, 2.0);
    __ LoadSImmediate(S6, 3.0);
    __ LoadSImmediate(S7, 4.0);

    __ LoadSImmediate(S8, 10.0);
    __ LoadSImmediate(S9, 1.0);
    __ LoadSImmediate(S10, 6.0);
    __ LoadSImmediate(S11, 3.0);

    __ vrsqrtsqs(Q0, Q1, Q2);

    __ bx(LR);
  } else {
    __ LoadSImmediate(S0, (3.0 - 10.0 * 5.0) / 2.0);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vrsqrtsqs, test) {
  EXPECT(test != NULL);
  typedef float (*Vrsqrtsqs)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_FLOAT(Vrsqrtsqs, test->entry());
  EXPECT_FLOAT_EQ((3.0 - 10.0 * 5.0)/2.0, res, 0.0001f);
}


ASSEMBLER_TEST_GENERATE(ReciprocalSqrt, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S4, 147000.0);
    __ vmovs(S5, S4);
    __ vmovs(S6, S4);
    __ vmovs(S7, S4);

    // Reciprocal square root estimate.
    __ vrsqrteqs(Q0, Q1);
    // 2 Newton-Raphson steps. xn+1 = xn * (3 - Q1*xn^2) / 2.
    // First step.
    __ vmulqs(Q2, Q0, Q0);  // Q2 <- xn^2
    __ vrsqrtsqs(Q2, Q1, Q2);  // Q2 <- (3 - Q1*Q2) / 2.
    __ vmulqs(Q0, Q0, Q2);  // xn+1 <- xn * Q2
    // Second step.
    __ vmulqs(Q2, Q0, Q0);
    __ vrsqrtsqs(Q2, Q1, Q2);
    __ vmulqs(Q0, Q0, Q2);

    __ bx(LR);
  } else {
    __ LoadSImmediate(S0, 1.0/sqrt(147000.0));
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(ReciprocalSqrt, test) {
  EXPECT(test != NULL);
  typedef float (*ReciprocalSqrt)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_FLOAT(ReciprocalSqrt, test->entry());
  EXPECT_FLOAT_EQ(1.0/sqrt(147000.0), res, 0.0001f);
}


ASSEMBLER_TEST_GENERATE(SIMDSqrt, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S4, 147000.0);
    __ vmovs(S5, S4);
    __ vmovs(S6, S4);
    __ vmovs(S7, S4);

    // Reciprocal square root estimate.
    __ vrsqrteqs(Q0, Q1);
    // 2 Newton-Raphson steps. xn+1 = xn * (3 - Q1*xn^2) / 2.
    // First step.
    __ vmulqs(Q2, Q0, Q0);  // Q2 <- xn^2
    __ vrsqrtsqs(Q2, Q1, Q2);  // Q2 <- (3 - Q1*Q2) / 2.
    __ vmulqs(Q0, Q0, Q2);  // xn+1 <- xn * Q2
    // Second step.
    __ vmulqs(Q2, Q0, Q0);
    __ vrsqrtsqs(Q2, Q1, Q2);
    __ vmulqs(Q0, Q0, Q2);

    // Reciprocal.
    __ vmovq(Q1, Q0);
    // Reciprocal estimate.
    __ vrecpeqs(Q0, Q1);
    // 2 Newton-Raphson steps.
    __ vrecpsqs(Q2, Q1, Q0);
    __ vmulqs(Q0, Q0, Q2);
    __ vrecpsqs(Q2, Q1, Q0);
    __ vmulqs(Q0, Q0, Q2);

    __ bx(LR);
  } else {
    __ LoadSImmediate(S0, sqrt(147000.0));
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(SIMDSqrt, test) {
  EXPECT(test != NULL);
  typedef float (*SIMDSqrt)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_FLOAT(SIMDSqrt, test->entry());
  EXPECT_FLOAT_EQ(sqrt(147000.0), res, 0.0001f);
}


ASSEMBLER_TEST_GENERATE(SIMDSqrt2, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S4, 1.0);
    __ LoadSImmediate(S5, 4.0);
    __ LoadSImmediate(S6, 9.0);
    __ LoadSImmediate(S7, 16.0);

    // Reciprocal square root estimate.
    __ vrsqrteqs(Q0, Q1);
    // 2 Newton-Raphson steps. xn+1 = xn * (3 - Q1*xn^2) / 2.
    // First step.
    __ vmulqs(Q2, Q0, Q0);  // Q2 <- xn^2
    __ vrsqrtsqs(Q2, Q1, Q2);  // Q2 <- (3 - Q1*Q2) / 2.
    __ vmulqs(Q0, Q0, Q2);  // xn+1 <- xn * Q2
    // Second step.
    __ vmulqs(Q2, Q0, Q0);
    __ vrsqrtsqs(Q2, Q1, Q2);
    __ vmulqs(Q0, Q0, Q2);

    // Reciprocal.
    __ vmovq(Q1, Q0);
    // Reciprocal estimate.
    __ vrecpeqs(Q0, Q1);
    // 2 Newton-Raphson steps.
    __ vrecpsqs(Q2, Q1, Q0);
    __ vmulqs(Q0, Q0, Q2);
    __ vrecpsqs(Q2, Q1, Q0);
    __ vmulqs(Q0, Q0, Q2);

    __ vadds(S0, S0, S1);
    __ vadds(S0, S0, S2);
    __ vadds(S0, S0, S3);

    __ bx(LR);
  } else {
    __ LoadSImmediate(S0, 10.0);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(SIMDSqrt2, test) {
  EXPECT(test != NULL);
  typedef float (*SIMDSqrt2)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_FLOAT(SIMDSqrt2, test->entry());
  EXPECT_FLOAT_EQ(10.0, res, 0.0001f);
}


ASSEMBLER_TEST_GENERATE(SIMDDiv, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S4, 1.0);
    __ LoadSImmediate(S5, 4.0);
    __ LoadSImmediate(S6, 9.0);
    __ LoadSImmediate(S7, 16.0);

    __ LoadSImmediate(S12, 4.0);
    __ LoadSImmediate(S13, 16.0);
    __ LoadSImmediate(S14, 36.0);
    __ LoadSImmediate(S15, 64.0);

    // Reciprocal estimate.
    __ vrecpeqs(Q0, Q1);
    // 2 Newton-Raphson steps.
    __ vrecpsqs(Q2, Q1, Q0);
    __ vmulqs(Q0, Q0, Q2);
    __ vrecpsqs(Q2, Q1, Q0);
    __ vmulqs(Q0, Q0, Q2);

    __ vmulqs(Q0, Q3, Q0);
    __ vadds(S0, S0, S1);
    __ vadds(S0, S0, S2);
    __ vadds(S0, S0, S3);

    __ bx(LR);
  } else {
    __ LoadSImmediate(S0, 16.0);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(SIMDDiv, test) {
  EXPECT(test != NULL);
  typedef float (*SIMDDiv)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_FLOAT(SIMDDiv, test->entry());
  EXPECT_FLOAT_EQ(16.0, res, 0.0001f);
}


ASSEMBLER_TEST_GENERATE(Vabsqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S4, 1.0);
    __ LoadSImmediate(S5, -1.0);
    __ LoadSImmediate(S6, 1.0);
    __ LoadSImmediate(S7, -1.0);

    __ vabsqs(Q0, Q1);

    __ vadds(S0, S0, S1);
    __ vadds(S0, S0, S2);
    __ vadds(S0, S0, S3);

    __ bx(LR);
  } else {
    __ LoadSImmediate(S0, 4.0);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vabsqs, test) {
  EXPECT(test != NULL);
  typedef float (*Vabsqs)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_FLOAT(Vabsqs, test->entry());
  EXPECT_FLOAT_EQ(4.0, res, 0.0001f);
}


ASSEMBLER_TEST_GENERATE(Vnegqs, assembler) {
  if (TargetCPUFeatures::neon_supported()) {
    __ LoadSImmediate(S4, 1.0);
    __ LoadSImmediate(S5, -2.0);
    __ LoadSImmediate(S6, 1.0);
    __ LoadSImmediate(S7, -2.0);

    __ vnegqs(Q0, Q1);

    __ vadds(S0, S0, S1);
    __ vadds(S0, S0, S2);
    __ vadds(S0, S0, S3);

    __ bx(LR);
  } else {
    __ LoadSImmediate(S0, 2.0);
    __ bx(LR);
  }
}


ASSEMBLER_TEST_RUN(Vnegqs, test) {
  EXPECT(test != NULL);
  typedef float (*Vnegqs)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_FLOAT(Vnegqs, test->entry());
  EXPECT_FLOAT_EQ(2.0, res, 0.0001f);
}


ASSEMBLER_TEST_GENERATE(MultCheckOverflow, assembler) {
  // Both positive, no overflow
  Label overflow1, test1;
  __ LoadImmediate(R0, 42);
  __ LoadImmediate(R1, 0xff);
  __ LoadImmediate(R2, 0xf0);
  __ CheckMultSignedOverflow(R1, R2, R3, D0, D1, &overflow1);
  __ b(&test1);
  __ Bind(&overflow1);
  __ LoadImmediate(R0, 1);
  __ Ret();


  // Left negative no overflow.
  __ Bind(&test1);
  Label overflow2, test2;
  __ LoadImmediate(R1, -0xff);
  __ LoadImmediate(R2, 0xf0);
  __ CheckMultSignedOverflow(R1, R2, R3, D0, D1, &overflow2);
  __ b(&test2);
  __ Bind(&overflow2);
  __ LoadImmediate(R0, 2);
  __ Ret();

  // Right negative no overflow
  Label overflow3, test3;
  __ Bind(&test2);
  __ LoadImmediate(R1, 0xff);
  __ LoadImmediate(R2, -0xf0);
  __ CheckMultSignedOverflow(R1, R2, R3, D0, D1, &overflow3);
  __ b(&test3);
  __ Bind(&overflow3);
  __ LoadImmediate(R0, 3);
  __ Ret();

  // Both negative no overflow.
  Label overflow4, test4;
  __ Bind(&test3);
  __ LoadImmediate(R1, -0xff);
  __ LoadImmediate(R2, -0xf0);
  __ CheckMultSignedOverflow(R1, R2, R3, D0, D1, &overflow4);
  __ b(&test4);
  __ Bind(&overflow4);
  __ LoadImmediate(R0, 4);
  __ Ret();

  // Both positive with overflow.
  Label test5;
  __ Bind(&test4);
  __ LoadImmediate(R1, 0x0fffffff);
  __ LoadImmediate(R2, 0xffff);
  __ CheckMultSignedOverflow(R1, R2, R3, D0, D1, &test5);
  __ LoadImmediate(R0, 5);
  __ Ret();

  // left negative with overflow.
  Label test6;
  __ Bind(&test5);
  __ LoadImmediate(R1, -0x0fffffff);
  __ LoadImmediate(R2, 0xffff);
  __ CheckMultSignedOverflow(R1, R2, R3, D0, D1, &test6);
  __ LoadImmediate(R0, 6);
  __ Ret();

  // right negative with overflow.
  Label test7;
  __ Bind(&test6);
  __ LoadImmediate(R1, 0x0fffffff);
  __ LoadImmediate(R2, -0xffff);
  __ CheckMultSignedOverflow(R1, R2, R3, D0, D1, &test7);
  __ LoadImmediate(R0, 7);
  __ Ret();

  // both negative with overflow.
  Label test8;
  __ Bind(&test7);
  __ LoadImmediate(R1, -0x0fffffff);
  __ LoadImmediate(R2, -0xffff);
  __ CheckMultSignedOverflow(R1, R2, R3, D0, D1, &test8);
  __ LoadImmediate(R0, 8);
  __ Ret();

  __ Bind(&test8);
  __ Ret();
}


ASSEMBLER_TEST_RUN(MultCheckOverflow, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(Tst, test->entry()));
}


// Called from assembler_test.cc.
// LR: return address.
// R0: context.
// R1: value.
// R2: growable array.
ASSEMBLER_TEST_GENERATE(StoreIntoObject, assembler) {
  __ PushList((1 << CTX) | (1 << LR));
  __ mov(CTX, Operand(R0));
  __ StoreIntoObject(R2,
                     FieldAddress(R2, GrowableObjectArray::data_offset()),
                     R1);
  __ PopList((1 << CTX) | (1 << LR));
  __ Ret();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
