// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"  // NOLINT

#if defined(TARGET_ARCH_ARM)

#include "vm/constants.h"  // NOLINT

namespace dart {

using dart::bit_cast;

const char* cpu_reg_names[kNumberOfCpuRegisters] = {
    "r0", "r1",  "r2", "r3", "r4", "r5", "r6", "r7",
    "r8", "ctx", "pp", "fp", "ip", "sp", "lr", "pc",
};

const char* fpu_reg_names[kNumberOfFpuRegisters] = {
    "q0", "q1", "q2",  "q3",  "q4",  "q5",  "q6",  "q7",
#if defined(VFPv3_D32)
    "q8", "q9", "q10", "q11", "q12", "q13", "q14", "q15",
#endif
};
const char* fpu_d_reg_names[kNumberOfDRegisters] = {
    "d0",  "d1",  "d2",  "d3",  "d4",  "d5",  "d6",  "d7",
    "d8",  "d9",  "d10", "d11", "d12", "d13", "d14", "d15",
#if defined(VFPv3_D32)
    "d16", "d17", "d18", "d19", "d20", "d21", "d22", "d23",
    "d24", "d25", "d26", "d27", "d28", "d29", "d30", "d31",
#endif
};
const char* fpu_s_reg_names[kNumberOfSRegisters] = {
    "s0",  "s1",  "s2",  "s3",  "s4",  "s5",  "s6",  "s7",  "s8",  "s9",  "s10",
    "s11", "s12", "s13", "s14", "s15", "s16", "s17", "s18", "s19", "s20", "s21",
    "s22", "s23", "s24", "s25", "s26", "s27", "s28", "s29", "s30", "s31",
};

const Register CallingConventions::ArgumentRegisters[] = {R0, R1, R2, R3};

const FpuRegister CallingConventions::FpuArgumentRegisters[] = {Q0, Q1, Q2, Q3};
const DRegister CallingConventions::FpuDArgumentRegisters[] = {D0, D1, D2, D3,
                                                               D4, D5, D6, D7};
const SRegister CallingConventions::FpuSArgumentRegisters[] = {
    S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15};

float ReciprocalEstimate(float a) {
  // From the ARM Architecture Reference Manual A2-85.
  if (isinf(a) || (fabs(a) >= exp2f(126)))
    return a >= 0.0f ? 0.0f : -0.0f;
  else if (a == 0.0f)
    return 1.0f / a;
  else if (isnan(a))
    return a;

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
  ASSERT((estimate >= 1.0) && (estimate <= (511.0 / 256.0)));

  // result = sign : result_exp<7:0> : estimate<51:29>
  int32_t result_bits =
      (a_bits & 0x80000000) | ((result_exp & 0xff) << 23) |
      ((bit_cast<uint64_t, double>(estimate) >> 29) & 0x7fffff);
  return bit_cast<float, int32_t>(result_bits);
}

float ReciprocalStep(float op1, float op2) {
  float p;
  if ((isinf(op1) && op2 == 0.0f) || (op1 == 0.0f && isinf(op2))) {
    p = 0.0f;
  } else {
    p = op1 * op2;
  }
  return 2.0f - p;
}

float ReciprocalSqrtEstimate(float a) {
  // From the ARM Architecture Reference Manual A2-87.
  if (a < 0.0f)
    return NAN;
  else if (isinf(a) || (fabs(a) >= exp2f(126)))
    return 0.0f;
  else if (a == 0.0)
    return 1.0f / a;
  else if (isnan(a))
    return a;

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
  ASSERT((estimate >= 1.0) && (estimate <= (511.0 / 256.0)));

  // result = 0 : result_exp<7:0> : estimate<51:29>
  int32_t result_bits =
      ((result_exp & 0xff) << 23) |
      ((bit_cast<uint64_t, double>(estimate) >> 29) & 0x7fffff);
  return bit_cast<float, int32_t>(result_bits);
}

float ReciprocalSqrtStep(float op1, float op2) {
  float p;
  if ((isinf(op1) && op2 == 0.0f) || (op1 == 0.0f && isinf(op2))) {
    p = 0.0f;
  } else {
    p = op1 * op2;
  }
  return (3.0f - p) / 2.0f;
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM)
