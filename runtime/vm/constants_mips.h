// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CONSTANTS_MIPS_H_
#define VM_CONSTANTS_MIPS_H_

namespace dart {

enum Register {
  ZR =  0,
  AT =  1,
  V0 =  2,
  V1 =  3,
  A0 =  4,
  A1 =  5,
  A2 =  6,
  A3 =  7,
  T0 =  8,
  T1 =  9,
  T2 = 10,
  T3 = 11,
  T4 = 12,
  T5 = 13,
  T6 = 14,
  T7 = 15,
  S0 = 16,
  S1 = 17,
  S2 = 18,
  S3 = 19,
  S4 = 20,
  S5 = 21,
  S6 = 22,
  S7 = 23,
  T8 = 24,
  T9 = 25,
  K0 = 26,
  K1 = 27,
  GP = 28,
  SP = 29,
  FP = 30,
  RA = 31,
  kNumberOfCpuRegisters = 32,
  kNoRegister = -1,
};


// Values for double-precision floating point registers.
enum FRegister {
  F0  =  0,
  F1  =  1,
  F2  =  2,
  F3  =  3,
  F4  =  4,
  F5  =  5,
  F6  =  6,
  F7  =  7,
  F8  =  8,
  F9  =  9,
  F10 = 10,
  F11 = 11,
  F12 = 12,
  F13 = 13,
  F14 = 14,
  F15 = 15,
  F16 = 16,
  F17 = 17,
  F18 = 18,
  F19 = 19,
  F20 = 20,
  F21 = 21,
  F22 = 22,
  F23 = 23,
  F24 = 24,
  F25 = 25,
  F26 = 26,
  F27 = 27,
  F28 = 28,
  F29 = 29,
  F30 = 30,
  F31 = 31,
  kNumberOfFRegisters = 32,
  kNoFRegister = -1,
};


// Architecture independent aliases.
typedef FRegister FpuRegister;
const FpuRegister FpuTMP = F0;
const int kNumberOfFpuRegisters = kNumberOfFRegisters;


// Register aliases.
const Register TMP = AT;
const Register CTX = S7;  // Caches current context in generated code.
const Register SPREG = SP;
const Register FPREG = FP;


// Values for the condition field.  // UNIMPLEMENTED.
enum Condition {
  kNoCondition = -1,
  kMaxCondition = 16,
};

}  // namespace dart

#endif  // VM_CONSTANTS_MIPS_H_
