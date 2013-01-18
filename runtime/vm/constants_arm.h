// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CONSTANTS_ARM_H_
#define VM_CONSTANTS_ARM_H_

namespace dart {

// We support both VFPv3-D16 and VFPv3-D32 profiles, but currently only one at
// a time.
#define VFPv3_D16
#if defined(VFPv3_D16) == defined(VFPv3_D32)
#error "Exactly one of VFPv3_D16 or VFPv3_D32 can be defined at a time."
#endif


enum Register {
  R0  =  0,
  R1  =  1,
  R2  =  2,
  R3  =  3,
  R4  =  4,
  R5  =  5,
  R6  =  6,
  R7  =  7,
  R8  =  8,
  R9  =  9,
  R10 = 10,
  R11 = 11,
  R12 = 12,
  R13 = 13,
  R14 = 14,
  R15 = 15,
  FP  = 11,
  IP  = 12,
  SP  = 13,
  LR  = 14,
  PC  = 15,
  kNumberOfCpuRegisters = 16,
  kNoRegister = -1,
};


// Values for single-precision floating point registers.
enum SRegister {
  S0  =  0,
  S1  =  1,
  S2  =  2,
  S3  =  3,
  S4  =  4,
  S5  =  5,
  S6  =  6,
  S7  =  7,
  S8  =  8,
  S9  =  9,
  S10 = 10,
  S11 = 11,
  S12 = 12,
  S13 = 13,
  S14 = 14,
  S15 = 15,
  S16 = 16,
  S17 = 17,
  S18 = 18,
  S19 = 19,
  S20 = 20,
  S21 = 21,
  S22 = 22,
  S23 = 23,
  S24 = 24,
  S25 = 25,
  S26 = 26,
  S27 = 27,
  S28 = 28,
  S29 = 29,
  S30 = 30,
  S31 = 31,
  kNumberOfSRegisters = 32,
  kNoSRegister = -1,
};


// Values for double-precision floating point registers.
enum DRegister {
  D0  =  0,
  D1  =  1,
  D2  =  2,
  D3  =  3,
  D4  =  4,
  D5  =  5,
  D6  =  6,
  D7  =  7,
  D8  =  8,
  D9  =  9,
  D10 = 10,
  D11 = 11,
  D12 = 12,
  D13 = 13,
  D14 = 14,
  D15 = 15,
#ifdef VFPv3_D16
  kNumberOfDRegisters = 16,
#else
  D16 = 16,
  D17 = 17,
  D18 = 18,
  D19 = 19,
  D20 = 20,
  D21 = 21,
  D22 = 22,
  D23 = 23,
  D24 = 24,
  D25 = 25,
  D26 = 26,
  D27 = 27,
  D28 = 28,
  D29 = 29,
  D30 = 30,
  D31 = 31,
  kNumberOfDRegisters = 32,
#endif
  kNumberOfOverlappingDRegisters = 16,
  kNoDRegister = -1,
};


// Architecture independent aliases.
typedef DRegister FpuRegister;
const FpuRegister FpuTMP = D0;
const int kNumberOfFpuRegisters = kNumberOfDRegisters;


// Register aliases.
const Register TMP = kNoRegister;  // No scratch register used by assembler.
const Register CTX = R9;           // Caches current context in generated code.
const Register SPREG = SP;
const Register FPREG = FP;


// Values for the condition field as defined in section A3.2.
enum Condition {
  kNoCondition = -1,
  EQ =  0,  // equal
  NE =  1,  // not equal
  CS =  2,  // carry set/unsigned higher or same
  CC =  3,  // carry clear/unsigned lower
  MI =  4,  // minus/negative
  PL =  5,  // plus/positive or zero
  VS =  6,  // overflow
  VC =  7,  // no overflow
  HI =  8,  // unsigned higher
  LS =  9,  // unsigned lower or same
  GE = 10,  // signed greater than or equal
  LT = 11,  // signed less than
  GT = 12,  // signed greater than
  LE = 13,  // signed less than or equal
  AL = 14,  // always (unconditional)
  kSpecialCondition = 15,  // special condition (refer to section A3.2.1)
  kMaxCondition = 16,
};

}  // namespace dart

#endif  // VM_CONSTANTS_ARM_H_
