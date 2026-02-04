// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is a semi-automated port of
// runtime/vm/compiler/assembler/disassembler_arm64.cc
// with constants from runtime/vm/constants_arm64.h.
//
// TODO: use string interpoloation instead of custom format options.
// TODO: refactor to better fit idiomatic Dart style.
// TODO: follow the standard arm64 assembly language in the disassembly.

import 'dart:typed_data';

// --- Constants from runtime/vm/constants_arm64.h ---

// enum Register
const int R0 = 0;
const int R1 = 1;
const int R2 = 2;
const int R3 = 3;
const int R4 = 4;
const int R5 = 5;
const int R6 = 6;
const int R7 = 7;
const int R8 = 8;
const int R9 = 9;
const int R10 = 10;
const int R11 = 11;
const int R12 = 12;
const int R13 = 13;
const int R14 = 14;
const int R15 = 15;
const int R16 = 16;
const int R17 = 17;
const int R18 = 18;
const int R19 = 19;
const int R20 = 20;
const int R21 = 21;
const int R22 = 22;
const int R23 = 23;
const int R24 = 24;
const int R25 = 25;
const int R26 = 26;
const int R27 = 27;
const int R28 = 28;
const int R29 = 29;
const int R30 = 30;
const int R31 = 31;
const int kNumberOfCpuRegisters = 32;
const int kNoRegister = -1;

// Aliases.
const int IP0 = R16;
const int IP1 = R17;
const int SP = R15;
const int FP = R29;
const int LR = R30;
const int LINK_REGISTER = R30;

// enum VRegister
const int V0 = 0;
const int V1 = 1;
const int V2 = 2;
const int V3 = 3;
const int V4 = 4;
const int V5 = 5;
const int V6 = 6;
const int V7 = 7;
const int V8 = 8;
const int V9 = 9;
const int V10 = 10;
const int V11 = 11;
const int V12 = 12;
const int V13 = 13;
const int V14 = 14;
const int V15 = 15;
const int V16 = 16;
const int V17 = 17;
const int V18 = 18;
const int V19 = 19;
const int V20 = 20;
const int V21 = 21;
const int V22 = 22;
const int V23 = 23;
const int V24 = 24;
const int V25 = 25;
const int V26 = 26;
const int V27 = 27;
const int V28 = 28;
const int V29 = 29;
const int V30 = 30;
const int V31 = 31;
const int kNumberOfVRegisters = 32;
const int kNoVRegister = -1;

const List<String> _cpuRegNames = [
  'r0',
  'r1',
  'r2',
  'r3',
  'r4',
  'r5',
  'r6',
  'r7',
  'r8',
  'r9',
  'r10',
  'r11',
  'r12',
  'r13',
  'r14',
  'sp',
  'tmp',
  'r17',
  'r18',
  'r19',
  'r20',
  'r21',
  'null',
  'r23',
  'code',
  'r25',
  'thr',
  'pp',
  'heap_bits',
  'fp',
  'lr',
  'zr/csp',
];

// Register aliases.
const int TMP = R16;
const int TMP2 = R17;
const int PP = R27;
const int CODE_REG = R24;
const int SPREG = R15;
const int THR = R26;
const int HEAP_BITS = R28;
const int NULL_REG = R22;

// Bit constants
const int B0 = (1 << 0);
const int B1 = (1 << 1);
const int B2 = (1 << 2);
const int B3 = (1 << 3);
const int B4 = (1 << 4);
const int B5 = (1 << 5);
const int B6 = (1 << 6);
const int B7 = (1 << 7);
const int B8 = (1 << 8);
const int B9 = (1 << 9);
const int B10 = (1 << 10);
const int B11 = (1 << 11);
const int B12 = (1 << 12);
const int B13 = (1 << 13);
const int B14 = (1 << 14);
const int B15 = (1 << 15);
const int B16 = (1 << 16);
const int B17 = (1 << 17);
const int B18 = (1 << 18);
const int B19 = (1 << 19);
const int B20 = (1 << 20);
const int B21 = (1 << 21);
const int B22 = (1 << 22);
const int B23 = (1 << 23);
const int B24 = (1 << 24);
const int B25 = (1 << 25);
const int B26 = (1 << 26);
const int B27 = (1 << 27);
const int B28 = (1 << 28);
const int B29 = (1 << 29);
const int B30 = (1 << 30);
const int B31 = (1 << 31);

// Opcodes
class MainOp {
  static const int DPImmediateMask = 0x1c000000;
  static const int DPImmediateFixed = B28;
  static const int CompareBranchMask = 0x1c000000;
  static const int CompareBranchFixed = B28 | B26;
  static const int LoadStoreMask = B27 | B25;
  static const int LoadStoreFixed = B27;
  static const int DPRegisterMask = 0x0e000000;
  static const int DPRegisterFixed = B27 | B25;
  static const int DPSimd1Mask = 0x1e000000;
  static const int DPSimd1Fixed = B27 | B26 | B25;
  static const int DPSimd2Mask = 0x1e000000;
  static const int DPSimd2Fixed = B28 | DPSimd1Fixed;
  static const int FPMask = 0x5e000000;
  static const int FPFixed = B28 | B27 | B26 | B25;
}

class MoveWideOp {
  static const int MoveWideMask = 0x1f800000;
  static const int MoveWideFixed = MainOp.DPImmediateFixed | B25 | B23;
  static const int MOVN = MoveWideFixed;
  static const int MOVZ = MoveWideFixed | B30;
  static const int MOVK = MoveWideFixed | B30 | B29;
}

class AddSubImmOp {
  static const int AddSubImmMask = 0x1f000000;
  static const int AddSubImmFixed = MainOp.DPImmediateFixed | B24;
  static const int ADDI = AddSubImmFixed;
  static const int SUBI = AddSubImmFixed | B30;
}

class BitfieldOp {
  static const int BitfieldMask = 0x1f800000;
  static const int BitfieldFixed = 0x13000000;
}

class LogicalImmOp {
  static const int LogicalImmMask = 0x1f800000;
  static const int LogicalImmFixed = MainOp.DPImmediateFixed | B25;
}

class PCRelOp {
  static const int PCRelMask = 0x1f000000;
  static const int PCRelFixed = MainOp.DPImmediateFixed;
}

class ExceptionGenOp {
  static const int ExceptionGenMask = 0xff000000;
  static const int ExceptionGenFixed = MainOp.CompareBranchFixed | B31 | B30;
  static const int SVC = ExceptionGenFixed | B0;
  static const int BRK = ExceptionGenFixed | B21;
  static const int HLT = ExceptionGenFixed | B22;
}

class SystemOp {
  static const int SystemMask = 0xffc00000;
  static const int SystemFixed = MainOp.CompareBranchFixed | B31 | B30 | B24;
  static const int CLREX =
      SystemFixed |
      B17 |
      B16 |
      B13 |
      B12 |
      B11 |
      B10 |
      B9 |
      B8 |
      B6 |
      B4 |
      B3 |
      B2 |
      B1 |
      B0;
}

class UnconditionalBranchRegOp {
  static const int UnconditionalBranchRegMask = 0xfe000000;
  static const int UnconditionalBranchRegFixed =
      MainOp.CompareBranchFixed | B31 | B30 | B25;
}

class CompareAndBranchOp {
  static const int CompareAndBranchMask = 0x7e000000;
  static const int CompareAndBranchFixed = MainOp.CompareBranchFixed | B29;
}

class ConditionalBranchOp {
  static const int ConditionalBranchMask = 0xfe000000;
  static const int ConditionalBranchFixed = MainOp.CompareBranchFixed | B30;
}

class TestAndBranchOp {
  static const int TestAndBranchMask = 0x7e000000;
  static const int TestAndBranchFixed = MainOp.CompareBranchFixed | B29 | B25;
}

class UnconditionalBranchOp {
  static const int UnconditionalBranchMask = 0x7c000000;
  static const int UnconditionalBranchFixed = MainOp.CompareBranchFixed;
}

class AtomicMemoryOp {
  static const int AtomicMemoryMask = 0x3f200c00;
  static const int AtomicMemoryFixed = B29 | B28 | B27 | B21;
  static const int LDCLR = AtomicMemoryFixed | B12;
  static const int LDSET = AtomicMemoryFixed | B13 | B12;
}

class LoadStoreRegOp {
  static const int LoadStoreRegMask = 0x3a000000;
  static const int LoadStoreRegFixed = MainOp.LoadStoreFixed | B29 | B28;
}

class LoadStoreRegPairOp {
  static const int LoadStoreRegPairMask = 0x3a000000;
  static const int LoadStoreRegPairFixed = MainOp.LoadStoreFixed | B29;
}

class LoadRegLiteralOp {
  static const int LoadRegLiteralMask = 0x3b000000;
  static const int LoadRegLiteralFixed = MainOp.LoadStoreFixed | B28;
}

class LoadStoreExclusiveOp {
  static const int LoadStoreExclusiveMask = 0x3f000000;
  static const int LoadStoreExclusiveFixed = B27;
}

class AddSubShiftExtOp {
  static const int AddSubShiftExtMask = 0x1f000000;
  static const int AddSubShiftExtFixed = MainOp.DPRegisterFixed | B24;
}

class AddSubWithCarryOp {
  static const int AddSubWithCarryMask = 0x1fe00000;
  static const int AddSubWithCarryFixed = MainOp.DPRegisterFixed | B28;
}

class LogicalShiftOp {
  static const int LogicalShiftMask = 0x1f000000;
  static const int LogicalShiftFixed = MainOp.DPRegisterFixed;
}

class MiscDP1SourceOp {
  static const int MiscDP1SourceMask = 0x5fe00000;
  static const int MiscDP1SourceFixed =
      MainOp.DPRegisterFixed | B30 | B28 | B23 | B22;
}

class MiscDP2SourceOp {
  static const int MiscDP2SourceMask = 0x5fe00000;
  static const int MiscDP2SourceFixed =
      MainOp.DPRegisterFixed | B28 | B23 | B22;
}

class MiscDP3SourceOp {
  static const int MiscDP3SourceMask = 0x1f000000;
  static const int MiscDP3SourceFixed = MainOp.DPRegisterFixed | B28 | B24;
  static const int MADDW = MiscDP3SourceFixed;
  static const int MADD = MiscDP3SourceFixed | B31;
  static const int MSUBW = MiscDP3SourceFixed | B15;
  static const int MSUB = MiscDP3SourceFixed | B31 | B15;
  static const int SMULH = MiscDP3SourceFixed | B31 | B22;
  static const int UMULH = MiscDP3SourceFixed | B31 | B23 | B22;
  static const int UMADDL = MiscDP3SourceFixed | B31 | B23 | B21;
  static const int SMADDL = MiscDP3SourceFixed | B31 | B21;
  static const int SMSUBL = MiscDP3SourceFixed | B31 | B21 | B15;
  static const int UMSUBL = MiscDP3SourceFixed | B31 | B23 | B21 | B15;
}

class ConditionalSelectOp {
  static const int ConditionalSelectMask = 0x1fe00000;
  static const int ConditionalSelectFixed = MainOp.DPRegisterFixed | B28 | B23;
}

class SIMDCopyOp {
  static const int SIMDCopyMask = 0x9fe08400;
  static const int SIMDCopyFixed = MainOp.DPSimd1Fixed | B10;
}

class SIMDThreeSameOp {
  static const int SIMDThreeSameMask = 0x9f200400;
  static const int SIMDThreeSameFixed = MainOp.DPSimd1Fixed | B21 | B10;
}

class SIMDTwoRegOp {
  static const int SIMDTwoRegMask = 0x9f3e0c00;
  static const int SIMDTwoRegFixed = MainOp.DPSimd1Fixed | B21 | B11;
}

class FPImmOp {
  static const int FPImmMask = 0x5f201c00;
  static const int FPImmFixed = MainOp.FPFixed | B21 | B12;
}

class FPIntCvtOp {
  static const int FPIntCvtMask = 0x5f00fc00;
  static const int FPIntCvtFixed = MainOp.FPFixed | B21;
}

class FPOneSourceOp {
  static const int FPOneSourceMask = 0x5f207c00;
  static const int FPOneSourceFixed = MainOp.FPFixed | B21 | B14;
}

class FPTwoSourceOp {
  static const int FPTwoSourceMask = 0xff200c00;
  static const int FPTwoSourceFixed = MainOp.FPFixed | B21 | B11;
}

class FPCompareOp {
  static const int FPCompareMask = 0xffa0fc07;
  static const int FPCompareFixed = MainOp.FPFixed | B21 | B13;
}

const int kDMB_ISH = 0xD5033BBF;
const int kDMB_ISHST = 0xD5033ABF;

enum Shift { LSL, LSR, ASR, ROR, kMaxShift }

const List<String> _shiftNames = ['lsl', 'lsr', 'asr', 'ror'];

enum Extend { UXTB, UXTH, UXTW, UXTX, SXTB, SXTH, SXTW, SXTX, kMaxExtend }

const List<String> _extendNames = [
  'uxtb',
  'uxth',
  'uxtw',
  'uxtx',
  'sxtb',
  'sxth',
  'sxtw',
  'sxtx',
];

enum R31Type { R31IsSP, R31IsZR }

enum Condition {
  EQ,
  NE,
  CS,
  CC,
  MI,
  PL,
  VS,
  VC,
  HI,
  LS,
  GE,
  LT,
  GT,
  LE,
  AL,
  NV,
  kNumberOfConditions,
  kInvalidCondition,
}

const List<String> _condNames = [
  'eq',
  'ne',
  'cs',
  'cc',
  'mi',
  'pl',
  'vs',
  'vc',
  'hi',
  'ls',
  'ge',
  'lt',
  'gt',
  'le',
  '',
  'invalid',
];

int invertCondition(int cond) => cond ^ 1;

class InstructionFields {
  static const int kSFShift = 31;
  static const int kRdShift = 0;
  static const int kRdBits = 5;
  static const int kRnShift = 5;
  static const int kRnBits = 5;
  static const int kRaShift = 10;
  static const int kRaBits = 5;
  static const int kRmShift = 16;
  static const int kRmBits = 5;
  static const int kRtShift = 0;
  static const int kRtBits = 5;
  static const int kRt2Shift = 10;
  static const int kRt2Bits = 5;
  static const int kRsShift = 16;
  static const int kRsBits = 5;
  static const int kVdShift = 0;
  static const int kVdBits = 5;
  static const int kVnShift = 5;
  static const int kVnBits = 5;
  static const int kVtShift = 0;
  static const int kVtBits = 5;
  static const int kImm12Shift = 10;
  static const int kImm12Bits = 12;
  static const int kImm16Shift = 5;
  static const int kImm16Bits = 16;
  static const int kImm19Shift = 5;
  static const int kImm19Bits = 19;
  static const int kImm26Shift = 0;
  static const int kImm26Bits = 26;
  static const int kImmSShift = 10;
  static const int kImmSBits = 6;
  static const int kImmRShift = 16;
  static const int kImmRBits = 6;
  static const int kNShift = 22;
  static const int kHWShift = 21;
  static const int kHWBits = 2;
  static const int kImm12ShiftShift = 22;
  static const int kShiftTypeShift = 22;
  static const int kShiftTypeBits = 2;
  static const int kExtendTypeShift = 13;
  static const int kExtendTypeBits = 3;
  static const int kAddShiftExtendShift = 21;
  static const int kImm6Shift = 10;
  static const int kImm9Shift = 12;
  static const int kSImm7Shift = 15;
  static const int kSelCondShift = 12;
  static const int kCondShift = 0;
}

extension type Instr(int value) {
  int bit(int pos) => (value >> pos) & 1;
  int bits(int start, int len) => (value >> start) & ((1 << len) - 1);
  int signedBits(int start, int len) {
    int val = bits(start, len);
    if ((val & (1 << (len - 1))) != 0) {
      val -= (1 << len);
    }
    return val;
  }

  // Instruction classification using masks.
  bool isDPImmediateOp() =>
      (value & MainOp.DPImmediateMask) == MainOp.DPImmediateFixed;
  bool isCompareBranchOp() =>
      (value & MainOp.CompareBranchMask) == MainOp.CompareBranchFixed;
  bool isLoadStoreOp() =>
      (value & MainOp.LoadStoreMask) == MainOp.LoadStoreFixed;
  bool isDPRegisterOp() =>
      (value & MainOp.DPRegisterMask) == MainOp.DPRegisterFixed;
  bool isDPSimd1Op() => (value & MainOp.DPSimd1Mask) == MainOp.DPSimd1Fixed;
  bool isDPSimd2Op() => (value & MainOp.DPSimd2Mask) == MainOp.DPSimd2Fixed;
  bool isFPOp() => (value & MainOp.FPMask) == MainOp.FPFixed;

  bool isMoveWideOp() =>
      (value & MoveWideOp.MoveWideMask) == MoveWideOp.MoveWideFixed;
  bool isAddSubImmOp() =>
      (value & AddSubImmOp.AddSubImmMask) == AddSubImmOp.AddSubImmFixed;
  bool isBitfieldOp() =>
      (value & BitfieldOp.BitfieldMask) == BitfieldOp.BitfieldFixed;
  bool isLogicalImmOp() =>
      (value & LogicalImmOp.LogicalImmMask) == LogicalImmOp.LogicalImmFixed;
  bool isPCRelOp() => (value & PCRelOp.PCRelMask) == PCRelOp.PCRelFixed;

  bool isExceptionGenOp() =>
      (value & ExceptionGenOp.ExceptionGenMask) ==
      ExceptionGenOp.ExceptionGenFixed;
  bool isSystemOp() => (value & SystemOp.SystemMask) == SystemOp.SystemFixed;
  bool isUnconditionalBranchRegOp() =>
      (value & UnconditionalBranchRegOp.UnconditionalBranchRegMask) ==
      UnconditionalBranchRegOp.UnconditionalBranchRegFixed;
  bool isCompareAndBranchOp() =>
      (value & CompareAndBranchOp.CompareAndBranchMask) ==
      CompareAndBranchOp.CompareAndBranchFixed;
  bool isConditionalBranchOp() =>
      (value & ConditionalBranchOp.ConditionalBranchMask) ==
      ConditionalBranchOp.ConditionalBranchFixed;
  bool isTestAndBranchOp() =>
      (value & TestAndBranchOp.TestAndBranchMask) ==
      TestAndBranchOp.TestAndBranchFixed;
  bool isUnconditionalBranchOp() =>
      (value & UnconditionalBranchOp.UnconditionalBranchMask) ==
      UnconditionalBranchOp.UnconditionalBranchFixed;

  bool isAtomicMemoryOp() =>
      (value & AtomicMemoryOp.AtomicMemoryMask) ==
      AtomicMemoryOp.AtomicMemoryFixed;
  bool isLoadStoreRegOp() =>
      (value & LoadStoreRegOp.LoadStoreRegMask) ==
      LoadStoreRegOp.LoadStoreRegFixed;
  bool isLoadStoreRegPairOp() =>
      (value & LoadStoreRegPairOp.LoadStoreRegPairMask) ==
      LoadStoreRegPairOp.LoadStoreRegPairFixed;
  bool isLoadRegLiteralOp() =>
      (value & LoadRegLiteralOp.LoadRegLiteralMask) ==
      LoadRegLiteralOp.LoadRegLiteralFixed;
  bool isLoadStoreExclusiveOp() =>
      (value & LoadStoreExclusiveOp.LoadStoreExclusiveMask) ==
      LoadStoreExclusiveOp.LoadStoreExclusiveFixed;

  bool isAddSubShiftExtOp() =>
      (value & AddSubShiftExtOp.AddSubShiftExtMask) ==
      AddSubShiftExtOp.AddSubShiftExtFixed;
  bool isAddSubWithCarryOp() =>
      (value & AddSubWithCarryOp.AddSubWithCarryMask) ==
      AddSubWithCarryOp.AddSubWithCarryFixed;
  bool isLogicalShiftOp() =>
      (value & LogicalShiftOp.LogicalShiftMask) ==
      LogicalShiftOp.LogicalShiftFixed;
  bool isMiscDP1SourceOp() =>
      (value & MiscDP1SourceOp.MiscDP1SourceMask) ==
      MiscDP1SourceOp.MiscDP1SourceFixed;
  bool isMiscDP2SourceOp() =>
      (value & MiscDP2SourceOp.MiscDP2SourceMask) ==
      MiscDP2SourceOp.MiscDP2SourceFixed;
  bool isMiscDP3SourceOp() =>
      (value & MiscDP3SourceOp.MiscDP3SourceMask) ==
      MiscDP3SourceOp.MiscDP3SourceFixed;
  bool isConditionalSelectOp() =>
      (value & ConditionalSelectOp.ConditionalSelectMask) ==
      ConditionalSelectOp.ConditionalSelectFixed;

  bool isSIMDCopyOp() =>
      (value & SIMDCopyOp.SIMDCopyMask) == SIMDCopyOp.SIMDCopyFixed;
  bool isSIMDThreeSameOp() =>
      (value & SIMDThreeSameOp.SIMDThreeSameMask) ==
      SIMDThreeSameOp.SIMDThreeSameFixed;
  bool isSIMDTwoRegOp() =>
      (value & SIMDTwoRegOp.SIMDTwoRegMask) == SIMDTwoRegOp.SIMDTwoRegFixed;

  bool isFPImmOp() => (value & FPImmOp.FPImmMask) == FPImmOp.FPImmFixed;
  bool isFPIntCvtOp() =>
      (value & FPIntCvtOp.FPIntCvtMask) == FPIntCvtOp.FPIntCvtFixed;
  bool isFPOneSourceOp() =>
      (value & FPOneSourceOp.FPOneSourceMask) == FPOneSourceOp.FPOneSourceFixed;
  bool isFPTwoSourceOp() =>
      (value & FPTwoSourceOp.FPTwoSourceMask) == FPTwoSourceOp.FPTwoSourceFixed;
  bool isFPCompareOp() =>
      (value & FPCompareOp.FPCompareMask) == FPCompareOp.FPCompareFixed;

  int rdField() => bits(InstructionFields.kRdShift, InstructionFields.kRdBits);
  int rnField() => bits(InstructionFields.kRnShift, InstructionFields.kRnBits);
  int rmField() => bits(InstructionFields.kRmShift, InstructionFields.kRmBits);
  int raField() => bits(InstructionFields.kRaShift, InstructionFields.kRaBits);
  int rtField() => bits(InstructionFields.kRtShift, InstructionFields.kRtBits);
  int rt2Field() =>
      bits(InstructionFields.kRt2Shift, InstructionFields.kRt2Bits);
  int rsField() => bits(InstructionFields.kRsShift, InstructionFields.kRsBits);

  int vdField() => bits(InstructionFields.kVdShift, InstructionFields.kVdBits);
  int vnField() => bits(InstructionFields.kVnShift, InstructionFields.kVnBits);
  int vmField() => bits(16, 5); // kVmShift is not defined
  int vtField() => bits(InstructionFields.kVtShift, InstructionFields.kVtBits);
  int vt2Field() => bits(10, 5); // kVt2Shift is not defined

  int imm12Field() =>
      bits(InstructionFields.kImm12Shift, InstructionFields.kImm12Bits);
  int imm12ShiftField() => bits(InstructionFields.kImm12ShiftShift, 2);
  int sImm9Field() => signedBits(InstructionFields.kImm9Shift, 9);
  int sImm7Field() => signedBits(InstructionFields.kSImm7Shift, 7);

  int shiftTypeField() =>
      bits(InstructionFields.kShiftTypeShift, InstructionFields.kShiftTypeBits);
  int shiftAmountField() => bits(InstructionFields.kImm6Shift, 6);
  int extendTypeField() => bits(
    InstructionFields.kExtendTypeShift,
    InstructionFields.kExtendTypeBits,
  );
  int extShiftAmountField() => bits(10, 3); // kImm3Shift is not defined

  int sfField() => bit(InstructionFields.kSFShift);
  int szField() => bits(30, 2);
  bool hasS() => bit(29) == 1;
  int sField() => bit(29);
  int conditionField() => bits(InstructionFields.kCondShift, 4);
  int selectConditionField() => bits(InstructionFields.kSelCondShift, 4);

  R31Type rnMode() =>
      (isAddSubImmOp() ||
          isLoadStoreRegOp() ||
          (isAddSubShiftExtOp() && isExtend()))
      ? R31Type.R31IsSP
      : R31Type.R31IsZR;
  R31Type rdMode() {
    if (isAddSubImmOp() || (isAddSubShiftExtOp() && isExtend())) {
      return hasS() ? R31Type.R31IsZR : R31Type.R31IsSP;
    }
    if (isLogicalImmOp()) {
      return bits(29, 2) == 3 ? R31Type.R31IsZR : R31Type.R31IsSP;
    }
    return R31Type.R31IsZR;
  }

  bool isShift() =>
      isLogicalShiftOp() || (bit(InstructionFields.kAddShiftExtendShift) == 0);
  bool isExtend() =>
      !isLogicalShiftOp() && (bit(InstructionFields.kAddShiftExtendShift) == 1);

  int sImm26Field() =>
      signedBits(InstructionFields.kImm26Shift, InstructionFields.kImm26Bits);
  int sImm19Field() =>
      signedBits(InstructionFields.kImm19Shift, InstructionFields.kImm19Bits);
  int sImm14Field() => signedBits(5, 14); // kImm14Shift is not defined

  int imm16Field() =>
      bits(InstructionFields.kImm16Shift, InstructionFields.kImm16Bits);
  int hwField() => bits(InstructionFields.kHWShift, InstructionFields.kHWBits);
  int nField() => bit(InstructionFields.kNShift);
  int immRField() =>
      bits(InstructionFields.kImmRShift, InstructionFields.kImmRBits);
  int immSField() =>
      bits(InstructionFields.kImmSShift, InstructionFields.kImmSBits);

  int imm8Field() => bits(13, 8); // kImm8Shift is not defined

  static int vfpExpandImm(int imm8) {
    int sign = (imm8 >> 7) & 0x1;
    int exp = (imm8 >> 4) & 0x7;
    int frac = imm8 & 0xf;

    if ((exp & 0x4) == 0) {
      exp = (0x2 | (exp & 0x1)) << 1;
      if ((exp & 0x2) == 0) {
        exp = ((exp & 0x1) ^ 0x1);
      } else {
        exp = ((exp & 0x1) | 0x2);
      }
      exp = (0x3ff ^ 0x7) | (exp << 2);
    } else {
      exp = 0x3ff;
    }
    return (sign << 63) | (exp << 52) | (frac << 48);
  }

  int immLogical() {
    final n = nField();
    final immR = immRField();
    final immS = immSField();

    if (n == 1) {
      if (immS == 0x3F) return 0;
      int bits = (1 << (immS + 1)) - 1;
      return rotateRight(bits, immR, 64);
    } else {
      for (var width = 32; width >= 2; width ~/= 2) {
        if ((immS & width) == 0) {
          int mask = width - 1;
          if ((immS & mask) == mask) return 0;
          int bits = (1 << ((immS & mask) + 1)) - 1;
          return repeatBitsAcrossReg(
            64,
            rotateRight(bits, immR & mask, width),
            width,
          );
        }
      }
    }
    return 0; // Should be unreachable
  }
}

int rotateRight(int value, int rotate, int width) {
  int right = rotate & 63;
  int left = (width - rotate) & 63;
  return ((value & ((1 << right) - 1)) << left) | (value >> right);
}

int repeatBitsAcrossReg(int regSize, int value, int width) {
  int result = value & ((1 << width) - 1);
  for (var i = width; i < regSize; i *= 2) {
    result |= (result << i);
  }
  return result;
}

class ARM64Decoder {
  final StringBuffer _buffer;

  ARM64Decoder(this._buffer);

  void instructionDecode(Instr instr) {
    if (instr.isDPImmediateOp()) {
      decodeDPImmediate(instr);
    } else if (instr.isCompareBranchOp()) {
      decodeCompareBranch(instr);
    } else if (instr.isLoadStoreOp()) {
      decodeLoadStore(instr);
    } else if (instr.isDPRegisterOp()) {
      decodeDPRegister(instr);
    } else if (instr.isDPSimd1Op()) {
      decodeDPSimd1(instr);
    } else if (instr.isDPSimd2Op()) {
      decodeDPSimd2(instr);
    } else {
      unknown(instr);
    }
  }

  void print(String s) => _buffer.write(s);
  void printInt(int val) => _buffer.write(val.toString());

  void printRegister(int reg, R31Type r31t) {
    if (reg == 31) {
      print((r31t == R31Type.R31IsZR) ? "zr" : "csp");
    } else {
      print(_cpuRegNames[reg]);
    }
  }

  void printVRegister(int reg) => print("v$reg");

  void printShiftExtendRm(Instr instr) {
    int rm = instr.rmField();
    Shift shift = Shift.values[instr.shiftTypeField()];
    int shiftAmount = instr.shiftAmountField();
    Extend extend = Extend.values[instr.extendTypeField()];
    int extendShiftAmount = instr.extShiftAmountField();

    printRegister(rm, R31Type.R31IsZR);

    if (instr.isShift() && (shift == Shift.LSL) && (shiftAmount == 0)) {
      return;
    }
    if (instr.isShift()) {
      if ((shift == Shift.ROR) && (shiftAmount == 0)) {
        print(" RRX");
        return;
      } else if (((shift == Shift.LSR) || (shift == Shift.ASR)) &&
          (shiftAmount == 0)) {
        shiftAmount = 32;
      }
      print(" ");
      print(_shiftNames[shift.index]);
      print(" #");
      printInt(shiftAmount);
    } else {
      assert(instr.isExtend());
      print(" ");
      print(_extendNames[extend.index]);
      if (((instr.sfField() == 1) && (extend == Extend.UXTX)) ||
          ((instr.sfField() == 0) && (extend == Extend.UXTW))) {
        print(" ");
        printInt(extendShiftAmount);
      }
    }
  }

  void printMemOperand(Instr instr) {
    final int rn = instr.rnField();
    if (instr.bit(24) == 1) {
      final int scale = instr.szField();
      final int imm12 = instr.imm12Field();
      final int off = imm12 << scale;
      print("[");
      printRegister(rn, R31Type.R31IsSP);
      if (off != 0) {
        print(", #");
        printInt(off);
      }
      print("]");
    } else {
      switch (instr.bits(10, 2)) {
        case 0:
          final int imm9 = instr.sImm9Field();
          print("[");
          printRegister(rn, R31Type.R31IsSP);
          print(", #");
          printInt(imm9);
          print("]");
          break;
        case 1:
          final int imm9 = instr.sImm9Field();
          print("[");
          printRegister(rn, R31Type.R31IsSP);
          print("]");
          print(", #");
          printInt(imm9);
          print(" !");
          break;
        case 2:
          final int rm = instr.rmField();
          final Extend ext = Extend.values[instr.extendTypeField()];
          final int s = instr.bit(12);
          print("[");
          printRegister(rn, R31Type.R31IsSP);
          print(", ");
          printRegister(rm, R31Type.R31IsZR);
          print(" ");
          print(_extendNames[ext.index]);
          if (s == 1) print(" scaled");
          print("]");
          break;
        case 3:
          final int imm9 = instr.sImm9Field();
          print("[");
          printRegister(rn, R31Type.R31IsSP);
          print(", #");
          printInt(imm9);
          print("]!");
          break;
        default:
          print("???");
      }
    }
  }

  void printPairMemOperand(Instr instr) {
    final int rn = instr.rnField();
    final int simm7 = instr.sImm7Field();
    final int shift = (instr.bit(26) == 1)
        ? 2 + instr.szField()
        : 2 + instr.sfField();
    final int offset = simm7 << shift;
    print("[");
    printRegister(rn, R31Type.R31IsSP);
    switch (instr.bits(23, 3)) {
      case 1:
        print("], #");
        printInt(offset);
        print(" !");
        break;
      case 2:
        print(", #");
        printInt(offset);
        print("]");
        break;
      case 3:
        print(", #");
        printInt(offset);
        print("]!");
        break;
      default:
        print(", ???]");
        break;
    }
  }

  void printCondition(Instr instr) {
    if (instr.isConditionalSelectOp()) {
      print(_condNames[instr.selectConditionField()]);
    } else {
      print(_condNames[instr.conditionField()]);
    }
  }

  void printInvertedCondition(Instr instr) {
    if (instr.isConditionalSelectOp()) {
      print(_condNames[invertCondition(instr.selectConditionField())]);
    } else {
      print(_condNames[invertCondition(instr.conditionField())]);
    }
  }

  void format(Instr instr, String formatStr) {
    var currentPos = 0;
    while (currentPos < formatStr.length) {
      final char = formatStr[currentPos];
      if (char == "'") {
        var end = formatStr.indexOf(' ', currentPos);
        if (end == -1) end = formatStr.length;
        final option = formatStr.substring(currentPos + 1, end);
        currentPos += formatOption(instr, option) + 1;
      } else {
        print(char);
        currentPos++;
      }
    }
  }

  int formatOption(Instr instr, String option) {
    if (option.startsWith('r')) return formatRegister(instr, option);
    if (option.startsWith('v')) return formatVRegister(instr, option);

    switch (option[0]) {
      case 'b':
        if (option.startsWith('bitimm')) {
          var imm = instr.immLogical();
          if (instr.sfField() == 0) {
            imm &= 0xffffffff;
          }
          print("0x");
          if (imm < 0) {
            // Print in two halves to avoid printing value as signed "0x-123".
            print((imm >>> 32).toRadixString(16));
            print((imm & 0xffffffff).toRadixString(16).padLeft(8, '0'));
          } else {
            print(imm.toRadixString(16));
          }
          return 6; // 'bitimm'.length;
        } else if (option.startsWith('bitpos')) {
          int bitpos = instr.bits(19, 5) | (instr.bit(31) << 5);
          print("#");
          printInt(bitpos);
          return 6;
        }
        break;
      case 'c':
        if (option.startsWith('csz')) {
          final imm5 = instr.bits(16, 5);
          var typ = "??";
          if ((imm5 & 0x1) != 0) {
            typ = "b";
          } else if ((imm5 & 0x2) != 0) {
            typ = "h";
          } else if ((imm5 & 0x4) != 0) {
            typ = "s";
          } else if ((imm5 & 0x8) != 0) {
            typ = "d";
          }
          print(typ);
          return 3;
        } else if (option.startsWith('condinverted')) {
          printInvertedCondition(instr);
          return 12;
        } else if (option.startsWith('cond')) {
          printCondition(instr);
          return 4;
        }
        break;
      case 'd':
        {
          int off;
          if (option.startsWith('dest26')) {
            off = instr.sImm26Field() << 2;
          } else if (option.startsWith('dest19')) {
            off = instr.sImm19Field() << 2;
          } else if (option.startsWith('dest14')) {
            off = instr.sImm14Field() << 2;
          } else {
            break;
          }
          print("${off >= 0 ? '+' : ''}$off");
          return 6;
        }
      case 'f':
        if (option.startsWith('fsz')) {
          int sz = instr.szField();
          print(switch (sz) {
            0 => (instr.bit(23) == 1) ? "q" : "b",
            1 => "h",
            2 => "s",
            3 => "d",
            _ => "?",
          });
          return 3;
        }
        break;
      case 'h':
        if (option.startsWith('hw')) {
          final shift = instr.hwField() << 4;
          if (shift != 0) print(" lsl $shift");
          return 2;
        }
        break;
      case 'i':
        if (option.startsWith('imm12s')) {
          int imm = instr.imm12Field();
          if (instr.imm12ShiftField() == 1) imm <<= 12;
          print("#0x${imm.toRadixString(16)}");
          return 6;
        } else if (option.startsWith('imm12')) {
          print("#0x${instr.imm12Field().toRadixString(16)}");
          return 5;
        } else if (option.startsWith('imm16')) {
          print("#0x${instr.imm16Field().toRadixString(16)}");
          return 5;
        } else if (option.startsWith('immd')) {
          final imm = Instr.vfpExpandImm(instr.imm8Field());
          final d = ByteData(8)
            ..setInt64(0, imm, Endian.host)
            ..getFloat64(0, Endian.host);
          print(d.toString());
          return 4;
        } else if (option.startsWith('immr')) {
          print("#${instr.immRField()}");
          return 4;
        } else if (option.startsWith('imms')) {
          print("#${instr.immSField()}");
          return 4;
        }
        break;
      case 'm':
        if (option.startsWith('memop')) {
          printMemOperand(instr);
          return 5;
        }
        break;
      case 'o':
        if (option.startsWith('opc')) {
          if (instr.bit(26) == 0) {
            if (instr.bit(31) == 0) {
              if (instr.bit(30) == 1) {
                print("sw");
              } else {
                print("w");
              }
            } else {
              // 64-bit width is most commonly used, no need to print "x".
            }
          } else {
            switch (instr.bits(30, 2)) {
              case 0:
                print("s");
                break;
              case 1:
                print("d");
                break;
              case 2:
                print("q");
                break;
              case 3:
                print("?");
                break;
            }
          }
          return 3;
        }
        break;
      case 'p':
        if (option.startsWith('pmemop')) {
          printPairMemOperand(instr);
          return 6;
        }
        break;
      case 's':
        if (option.startsWith('shift_op')) {
          printShiftExtendRm(instr);
          return 8;
        } else if (option.startsWith('sf')) {
          if (instr.sfField() == 0) print('w');
          return 2;
        } else if (option.startsWith('sz')) {
          final sz = instr.szField();
          print(switch (sz) {
            0 => "b",
            1 => "h",
            2 => "w",
            3 => "",
            _ => "?",
          });
          return 2;
        } else {
          if (instr.hasS()) print("s");
          return 1;
        }
    }
    throw 'Unexpected format option $option';
  }

  int formatRegister(Instr instr, String format) {
    assert(format[0] == 'r');
    switch (format[1]) {
      case 'n':
        printRegister(instr.rnField(), instr.rnMode());
        return 2;
      case 'd':
        printRegister(instr.rdField(), instr.rdMode());
        return 2;
      case 'm':
        printRegister(instr.rmField(), R31Type.R31IsZR);
        return 2;
      case 't':
        if (format[2] == '2') {
          printRegister(instr.rt2Field(), R31Type.R31IsZR);
          return 3;
        }
        printRegister(instr.rtField(), R31Type.R31IsZR);
        return 2;
      case 'a':
        printRegister(instr.raField(), R31Type.R31IsZR);
        return 2;
      case 's':
        printRegister(instr.rsField(), R31Type.R31IsZR);
        return 2;
    }
    throw 'Unexpected register format $format';
  }

  int formatVRegister(Instr instr, String format) {
    assert(format[0] == 'v');
    switch (format[1]) {
      case 'd':
        printVRegister(instr.vdField());
        return 2;
      case 'n':
        printVRegister(instr.vnField());
        return 2;
      case 'm':
        printVRegister(instr.vmField());
        return 2;
      case 't':
        if (format[2] == '2') {
          printVRegister(instr.vt2Field());
          return 3;
        }
        printVRegister(instr.vtField());
        return 2;
    }
    throw 'Unexpected v-register format $format';
  }

  void unknown(Instr instr) => print("unknown");

  void decodeMoveWide(Instr instr) {
    switch (instr.bits(29, 2)) {
      case 0:
        format(instr, "movn'sf 'rd, 'imm16'hw");
        break;
      case 2:
        format(instr, "movz'sf 'rd, 'imm16'hw");
        break;
      case 3:
        format(instr, "movk'sf 'rd, 'imm16'hw");
        break;
      default:
        unknown(instr);
    }
  }

  void decodeLoadStoreReg(Instr instr) {
    if (instr.bit(26) == 1) {
      // SIMD or FP
      if (instr.bit(22) == 1) {
        format(instr, "fldr'fsz 'vt, 'memop");
      } else {
        format(instr, "fstr'fsz 'vt, 'memop");
      }
    } else {
      // Integer
      if (instr.bits(22, 2) == 0) {
        format(instr, "str'sz 'rt, 'memop");
      } else if (instr.bits(23, 1) == 1) {
        format(instr, "ldrs'sz 'rt, 'memop");
      } else {
        format(instr, "ldr'sz 'rt, 'memop");
      }
    }
  }

  void decodeDPImmediate(Instr instr) {
    if (instr.isMoveWideOp()) {
      decodeMoveWide(instr);
    } else if (instr.isAddSubImmOp()) {
      decodeAddSubImm(instr);
    } else if (instr.isBitfieldOp()) {
      decodeBitfield(instr);
    } else if (instr.isLogicalImmOp()) {
      decodeLogicalImm(instr);
    } else if (instr.isPCRelOp()) {
      decodePCRel(instr);
    } else {
      unknown(instr);
    }
  }

  void decodeCompareBranch(Instr instr) {
    if (instr.isExceptionGenOp()) {
      decodeExceptionGen(instr);
    } else if (instr.isSystemOp()) {
      decodeSystem(instr);
    } else if (instr.isUnconditionalBranchRegOp()) {
      decodeUnconditionalBranchReg(instr);
    } else if (instr.isCompareAndBranchOp()) {
      decodeCompareAndBranch(instr);
    } else if (instr.isConditionalBranchOp()) {
      decodeConditionalBranch(instr);
    } else if (instr.isTestAndBranchOp()) {
      decodeTestAndBranch(instr);
    } else if (instr.isUnconditionalBranchOp()) {
      decodeUnconditionalBranch(instr);
    } else {
      unknown(instr);
    }
  }

  void decodeLoadStore(Instr instr) {
    if (instr.isAtomicMemoryOp()) {
      decodeAtomicMemory(instr);
    } else if (instr.isLoadStoreRegOp()) {
      decodeLoadStoreReg(instr);
    } else if (instr.isLoadStoreRegPairOp()) {
      decodeLoadStoreRegPair(instr);
    } else if (instr.isLoadRegLiteralOp()) {
      decodeLoadRegLiteral(instr);
    } else if (instr.isLoadStoreExclusiveOp()) {
      decodeLoadStoreExclusive(instr);
    } else {
      unknown(instr);
    }
  }

  void decodeDPRegister(Instr instr) {
    if (instr.isAddSubShiftExtOp()) {
      decodeAddSubShiftExt(instr);
    } else if (instr.isAddSubWithCarryOp()) {
      decodeAddSubWithCarry(instr);
    } else if (instr.isLogicalShiftOp()) {
      decodeLogicalShift(instr);
    } else if (instr.isMiscDP1SourceOp()) {
      decodeMiscDP1Source(instr);
    } else if (instr.isMiscDP2SourceOp()) {
      decodeMiscDP2Source(instr);
    } else if (instr.isMiscDP3SourceOp()) {
      decodeMiscDP3Source(instr);
    } else if (instr.isConditionalSelectOp()) {
      decodeConditionalSelect(instr);
    } else {
      unknown(instr);
    }
  }

  void decodeDPSimd1(Instr instr) {
    if (instr.isSIMDCopyOp()) {
      decodeSIMDCopy(instr);
    } else if (instr.isSIMDThreeSameOp()) {
      decodeSIMDThreeSame(instr);
    } else if (instr.isSIMDTwoRegOp()) {
      decodeSIMDTwoReg(instr);
    } else {
      unknown(instr);
    }
  }

  void decodeDPSimd2(Instr instr) {
    if (instr.isFPOp()) {
      decodeFP(instr);
    } else {
      unknown(instr);
    }
  }

  void decodeAddSubImm(Instr instr) {
    switch (instr.bit(30)) {
      case 0:
        {
          if ((instr.rdField() == R31) && (instr.sField() == 1)) {
            format(instr, "cmn'sf 'rn, 'imm12s");
          } else {
            if (((instr.rdField() == R31) || (instr.rnField() == R31)) &&
                (instr.imm12Field() == 0) &&
                (instr.bit(29) == 0)) {
              format(instr, "mov'sf 'rd, 'rn");
            } else {
              format(instr, "add'sf's 'rd, 'rn, 'imm12s");
            }
          }
          break;
        }
      case 1:
        {
          if ((instr.rdField() == R31) && (instr.sField() == 1)) {
            format(instr, "cmp'sf 'rn, 'imm12s");
          } else {
            format(instr, "sub'sf's 'rd, 'rn, 'imm12s");
          }
          break;
        }
      default:
        unknown(instr);
        break;
    }
  }

  void decodeBitfield(Instr instr) {
    var regSize = instr.sfField() == 0 ? 32 : 64;
    int op = instr.bits(29, 2);
    int rImm = instr.immRField();
    int sImm = instr.immSField();
    switch (op) {
      case 0:
        if (rImm == 0) {
          if (sImm == 7) {
            format(instr, "sxtb 'rd, 'rn");
            return;
          } else if (sImm == 15) {
            format(instr, "sxth 'rd, 'rn");
            return;
          } else if (sImm == 31) {
            format(instr, "sxtw 'rd, 'rn");
            return;
          }
        }
        if (sImm == (regSize - 1)) {
          format(instr, "asr'sf 'rd, 'rn, 'immr");
          return;
        }
        format(instr, "sbfm'sf 'rd, 'rn, 'immr, 'imms");
        break;
      case 1:
        format(instr, "bfm'sf 'rd, 'rn, 'immr, 'imms");
        break;
      case 2:
        if (rImm == 0) {
          if (sImm == 7) {
            format(instr, "uxtb 'rd, 'rn");
            return;
          } else if (sImm == 15) {
            format(instr, "uxth 'rd, 'rn");
            return;
          }
        }
        if ((sImm != (regSize - 1)) && ((sImm + 1) == rImm)) {
          int shift = regSize - sImm - 1;
          format(instr, "lsl'sf 'rd, 'rn, #");
          printInt(shift);
          return;
        } else if (sImm == (regSize - 1)) {
          format(instr, "lsr'sf 'rd, 'rn, 'immr");
          return;
        }
        format(instr, "ubfm'sf 'rd, 'rn, 'immr, 'imms");
        break;
      default:
        unknown(instr);
    }
  }

  void decodeLogicalImm(Instr instr) {
    int op = instr.bits(29, 2);
    switch (op) {
      case 0:
        format(instr, "and'sf 'rd, 'rn, 'bitimm");
        break;
      case 1:
        if (instr.rnField() == R31) {
          format(instr, "mov'sf 'rd, 'bitimm");
        } else {
          format(instr, "orr'sf 'rd, 'rn, 'bitimm");
        }
        break;
      case 2:
        format(instr, "eor'sf 'rd, 'rn, 'bitimm");
        break;
      case 3:
        if (instr.rdField() == R31) {
          format(instr, "tst'sf 'rn, 'bitimm");
        } else {
          format(instr, "and'sfs 'rd, 'rn, 'bitimm");
        }
        break;
      default:
        unknown(instr);
    }
  }

  void decodePCRel(Instr instr) {
    final op = instr.bit(31);
    if (op == 0) {
      format(instr, "adr 'rd, 'pcadr");
    } else {
      unknown(instr);
    }
  }

  void decodeExceptionGen(Instr instr) {
    if ((instr.bits(0, 2) == 1) &&
        (instr.bits(2, 3) == 0) &&
        (instr.bits(21, 3) == 0)) {
      format(instr, "svc 'imm16");
    } else if ((instr.bits(0, 2) == 0) &&
        (instr.bits(2, 3) == 0) &&
        (instr.bits(21, 3) == 1)) {
      format(instr, "brk 'imm16");
    } else if ((instr.bits(0, 2) == 0) &&
        (instr.bits(2, 3) == 0) &&
        (instr.bits(21, 3) == 2)) {
      format(instr, "hlt 'imm16");
    } else {
      unknown(instr);
    }
  }

  void decodeSystem(Instr instr) {
    if (instr.value == SystemOp.CLREX) {
      format(instr, "clrex");
      return;
    }
    if (instr.value == kDMB_ISH) {
      format(instr, "dmb ish");
      return;
    }
    if (instr.value == kDMB_ISHST) {
      format(instr, "dmb ishst");
      return;
    }
    if ((instr.bits(0, 8) == 0x1f) &&
        (instr.bits(12, 4) == 2) &&
        (instr.bits(16, 3) == 3) &&
        (instr.bits(19, 2) == 0) &&
        (instr.bit(21) == 0)) {
      if (instr.bits(8, 4) == 0) {
        format(instr, "nop");
      } else {
        unknown(instr);
      }
    } else {
      unknown(instr);
    }
  }

  void decodeUnconditionalBranchReg(Instr instr) {
    if ((instr.bits(0, 5) == 0) &&
        (instr.bits(10, 5) == 0) &&
        (instr.bits(16, 5) == 0x1f)) {
      switch (instr.bits(21, 4)) {
        case 0:
          format(instr, "br 'rn");
          break;
        case 1:
          format(instr, "blr 'rn");
          break;
        case 2:
          if (instr.rnField() == LINK_REGISTER) {
            format(instr, "ret");
          } else {
            format(instr, "ret 'rn");
          }
          break;
        default:
          unknown(instr);
      }
    }
  }

  void decodeCompareAndBranch(Instr instr) {
    final op = instr.bit(24);
    if (op == 0) {
      format(instr, "cbz'sf 'rt, 'dest19");
    } else {
      format(instr, "cbnz'sf 'rt, 'dest19");
    }
  }

  void decodeConditionalBranch(Instr instr) {
    if ((instr.bit(24) != 0) || (instr.bit(4) != 0)) {
      unknown(instr);
      return;
    }
    format(instr, "b'cond 'dest19");
  }

  void decodeTestAndBranch(Instr instr) {
    final op = instr.bit(24);
    if (op == 0) {
      format(instr, "tbz'sf 'rt, 'bitpos, 'dest14");
    } else {
      format(instr, "tbnz'sf 'rt, 'bitpos, 'dest14");
    }
  }

  void decodeUnconditionalBranch(Instr instr) {
    final op = instr.bit(31);
    if (op == 0) {
      format(instr, "b 'dest26");
    } else {
      format(instr, "bl 'dest26");
    }
  }

  void decodeAtomicMemory(Instr instr) {
    switch (instr.bits(12, 3)) {
      case 1:
        format(instr, "ldclr'sz 'rs, 'rt, ['rn]");
        break;
      case 3:
        format(instr, "ldset'sz 'rs, 'rt, ['rn]");
        break;
      default:
        unknown(instr);
    }
  }

  void decodeLoadStoreRegPair(Instr instr) {
    if (instr.bit(26) == 1) {
      // SIMD or FP
      if (instr.bit(22) == 1) {
        format(instr, "fldp'opc 'vt, 'vt2, 'pmemop");
      } else {
        format(instr, "fstp'opc 'vt, 'vt2, 'pmemop");
      }
    } else {
      // Integer
      if (instr.bit(22) == 1) {
        format(instr, "ldp'opc 'rt, 'rt2, 'pmemop");
      } else {
        format(instr, "stp'opc 'rt, 'rt2, 'pmemop");
      }
    }
  }

  void decodeLoadRegLiteral(Instr instr) {
    if ((instr.bit(31) != 0) ||
        (instr.bit(29) != 0) ||
        (instr.bits(24, 3) != 0)) {
      unknown(instr);
    }
    if (instr.bit(30) != 0) {
      format(instr, "ldrx 'rt, 'pcldr");
    } else {
      format(instr, "ldrw 'rt, 'pcldr");
    }
  }

  void decodeLoadStoreExclusive(Instr instr) {
    if (instr.bit(31) != 1 ||
        instr.bit(21) != 0 ||
        instr.bit(23) != instr.bit(15)) {
      unknown(instr);
    }
    final isLoad = instr.bit(22) == 1;
    final isExclusive = instr.bit(23) == 0;
    final isOrdered = instr.bit(15) == 1;
    if (isLoad) {
      final isLoadAcquire = !isExclusive && isOrdered;
      if (isLoadAcquire) {
        format(instr, "ldar'sz 'rt, ['rn]");
      } else {
        format(instr, "ldxr'sz 'rt, ['rn]");
      }
    } else {
      final isStoreRelease = !isExclusive && isOrdered;
      if (isStoreRelease) {
        format(instr, "stlr'sz 'rt, ['rn]");
      } else {
        format(instr, "stxr'sz 'rs, 'rt, ['rn]");
      }
    }
  }

  void decodeAddSubShiftExt(Instr instr) {
    switch (instr.bit(30)) {
      case 0:
        if ((instr.rdField() == R31) && (instr.sField() == 1)) {
          format(instr, "cmn'sf 'rn, 'shift_op");
        } else {
          format(instr, "add'sf's 'rd, 'rn, 'shift_op");
        }
        break;
      case 1:
        if ((instr.rdField() == R31) && (instr.sField() == 1)) {
          format(instr, "cmp'sf 'rn, 'shift_op");
        } else {
          if (instr.rnField() == R31) {
            format(instr, "neg'sf's 'rd, 'shift_op");
          } else {
            format(instr, "sub'sf's 'rd, 'rn, 'shift_op");
          }
        }
        break;
      default:
        // unreachable
        break;
    }
  }

  void decodeAddSubWithCarry(Instr instr) {
    switch (instr.bit(30)) {
      case 0:
        format(instr, "adc'sf's 'rd, 'rn, 'rm");
        break;
      case 1:
        format(instr, "sbc'sf's 'rd, 'rn, 'rm");
        break;
      default: // unreachable
    }
  }

  void decodeLogicalShift(Instr instr) {
    final op = (instr.bits(29, 2) << 1) | instr.bit(21);
    switch (op) {
      case 0:
        format(instr, "and'sf 'rd, 'rn, 'shift_op");
        break;
      case 1:
        format(instr, "bic'sf 'rd, 'rn, 'shift_op");
        break;
      case 2:
        if ((instr.rnField() == R31) &&
            (instr.isShift()) &&
            (instr.shiftTypeField() == Shift.LSL.index)) {
          if (instr.shiftAmountField() == 0) {
            format(instr, "mov'sf 'rd, 'rm");
          } else {
            format(instr, "lsl'sf 'rd, 'rm, 'imms");
          }
        } else {
          format(instr, "orr'sf 'rd, 'rn, 'shift_op");
        }
        break;
      case 3:
        format(instr, "orn'sf 'rd, 'rn, 'shift_op");
        break;
      case 4:
        format(instr, "eor'sf 'rd, 'rn, 'shift_op");
        break;
      case 5:
        format(instr, "eon'sf 'rd, 'rn, 'shift_op");
        break;
      case 6:
        if (instr.rdField() == R31) {
          format(instr, "tst'sf 'rn, 'shift_op");
        } else {
          format(instr, "and'sfs 'rd, 'rn, 'shift_op");
        }
        break;
      case 7:
        format(instr, "bic'sfs 'rd, 'rn, 'shift_op");
        break;
      default: // unreachable
    }
  }

  void decodeMiscDP1Source(Instr instr) {
    if (instr.bit(29) != 0) {
      unknown(instr);
      return;
    }
    final op = instr.bits(10, 10);
    switch (op) {
      case 0:
        format(instr, "rbit'sf 'rd, 'rn");
        break;
      case 4:
        format(instr, "clz'sf 'rd, 'rn");
        break;
      default:
        unknown(instr);
    }
  }

  void decodeMiscDP2Source(Instr instr) {
    if (instr.bit(29) != 0) {
      unknown(instr);
      return;
    }
    final op = instr.bits(10, 5);
    switch (op) {
      case 2:
        format(instr, "udiv'sf 'rd, 'rn, 'rm");
        break;
      case 3:
        format(instr, "sdiv'sf 'rd, 'rn, 'rm");
        break;
      case 8:
        format(instr, "lsl'sf 'rd, 'rn, 'rm");
        break;
      case 9:
        format(instr, "lsr'sf 'rd, 'rn, 'rm");
        break;
      case 10:
        format(instr, "asr'sf 'rd, 'rn, 'rm");
        break;
      default:
        unknown(instr);
    }
  }

  void decodeMiscDP3Source(Instr instr) {
    var zeroOperand = instr.raField() == R31;
    int maskedBits =
        instr.value & ~(0x1F << 5 | 0x1F << 16 | 0x1F << 10 | 0x1F << 0);

    if (maskedBits == MiscDP3SourceOp.MADD ||
        maskedBits == MiscDP3SourceOp.MADDW) {
      if (zeroOperand) {
        format(instr, "mul'sf 'rd, 'rn, 'rm");
      } else {
        format(instr, "madd'sf 'rd, 'rn, 'rm, 'ra");
      }
    } else if (maskedBits == MiscDP3SourceOp.MSUB ||
        maskedBits == MiscDP3SourceOp.MSUBW) {
      if (zeroOperand) {
        format(instr, "mneg'sf 'rd, 'rn, 'rm");
      } else {
        format(instr, "msub'sf 'rd, 'rn, 'rm, 'ra");
      }
    } else if (maskedBits == MiscDP3SourceOp.SMULH) {
      format(instr, "smulh 'rd, 'rn, 'rm");
    } else if (maskedBits == MiscDP3SourceOp.UMULH) {
      format(instr, "umulh 'rd, 'rn, 'rm");
    } else if (maskedBits == MiscDP3SourceOp.UMADDL) {
      if (zeroOperand) {
        format(instr, "umull 'rd, 'rn, 'rm");
      } else {
        format(instr, "umaddl 'rd, 'rn, 'rm, 'ra");
      }
    } else if (maskedBits == MiscDP3SourceOp.SMADDL) {
      if (zeroOperand) {
        format(instr, "smull 'rd, 'rn, 'rm");
      } else {
        format(instr, "smaddl 'rd, 'rn, 'rm, 'ra");
      }
    } else if (maskedBits == MiscDP3SourceOp.SMSUBL) {
      if (zeroOperand) {
        format(instr, "smnegl 'rd, 'rn, 'rm");
      } else {
        format(instr, "smsubl 'rd, 'rn, 'rm, 'ra");
      }
    } else if (maskedBits == MiscDP3SourceOp.UMSUBL) {
      if (zeroOperand) {
        format(instr, "umnegl 'rd, 'rn, 'rm");
      } else {
        format(instr, "umsubl 'rd, 'rn, 'rm, 'ra");
      }
    } else {
      unknown(instr);
    }
  }

  void decodeConditionalSelect(Instr instr) {
    int cond = instr.selectConditionField();
    bool nonSelect =
        (instr.rnField() == instr.rmField()) && ((cond & 0xe) != 0xe);
    if ((instr.bits(29, 2) == 0) && (instr.bits(10, 2) == 0)) {
      format(instr, "csel'sf 'rd, 'rn, 'rm, 'cond");
    } else if ((instr.bits(29, 2) == 0) && (instr.bits(10, 2) == 1)) {
      if (nonSelect) {
        if (instr.rnField() == 31 && instr.rmField() == 31) {
          format(instr, "cset'sf 'rd, 'condinverted");
        } else {
          format(instr, "cinc'sf 'rd, 'rn, 'condinverted");
        }
      } else {
        format(instr, "csinc'sf 'rd, 'rn, 'rm, 'cond");
      }
    } else if ((instr.bits(29, 2) == 2) && (instr.bits(10, 2) == 0)) {
      if (nonSelect) {
        if (instr.rnField() == 31 && instr.rmField() == 31) {
          format(instr, "csetm'sf 'rd, 'condinverted");
        } else {
          format(instr, "cinv'sf 'rd, 'rn, 'condinverted");
        }
      } else {
        format(instr, "csinv'sf 'rd, 'rn, 'rm, 'cond");
      }
    } else if ((instr.bits(29, 2) == 2) && (instr.bits(10, 2) == 1)) {
      if (nonSelect) {
        format(instr, "cneg'sf 'rd, 'rn, 'condinverted");
      } else {
        format(instr, "csneg'sf 'rd, 'rn, 'rm, 'cond");
      }
    } else {
      unknown(instr);
    }
  }

  void decodeSIMDCopy(Instr instr) => unknown(instr);
  void decodeSIMDThreeSame(Instr instr) => unknown(instr);
  void decodeSIMDTwoReg(Instr instr) => unknown(instr);

  void decodeFP(Instr instr) {
    if (instr.isFPImmOp()) {
      decodeFPImm(instr);
    } else if (instr.isFPIntCvtOp()) {
      decodeFPIntCvt(instr);
    } else if (instr.isFPOneSourceOp()) {
      decodeFPOneSource(instr);
    } else if (instr.isFPTwoSourceOp()) {
      decodeFPTwoSource(instr);
    } else if (instr.isFPCompareOp()) {
      decodeFPCompare(instr);
    } else {
      unknown(instr);
    }
  }

  void decodeFPImm(Instr instr) {
    if ((instr.bit(31) != 0) ||
        (instr.bit(29) != 0) ||
        (instr.bit(23) != 0) ||
        (instr.bits(5, 5) != 0)) {
      unknown(instr);
      return;
    }
    if (instr.bit(22) == 1) {
      // Double.
      format(instr, "fmovd 'vd, 'immd");
    } else {
      // Single.
      unknown(instr);
    }
  }

  void decodeFPIntCvt(Instr instr) {
    if (instr.bit(29) != 0) {
      unknown(instr);
      return;
    }

    if ((instr.sfField() == 0) && (instr.bits(22, 2) == 0)) {
      if (instr.bits(16, 5) == 6) {
        format(instr, "fmovrs'sf 'rd, 'vn");
      } else if (instr.bits(16, 5) == 7) {
        format(instr, "fmovsr'sf 'vd, 'rn");
      } else {
        unknown(instr);
      }
    } else if (instr.bits(22, 2) == 1) {
      if (instr.bits(16, 5) == 2) {
        format(instr, "scvtfd'sf 'vd, 'rn");
      } else if (instr.bits(16, 5) == 6) {
        format(instr, "fmovrd'sf 'rd, 'vn");
      } else if (instr.bits(16, 5) == 7) {
        format(instr, "fmovdr'sf 'vd, 'rn");
      } else if (instr.bits(16, 5) == 8) {
        format(instr, "fcvtps'sf 'rd, 'vn");
      } else if (instr.bits(16, 5) == 16) {
        format(instr, "fcvtms'sf 'rd, 'vn");
      } else if (instr.bits(16, 5) == 24) {
        format(instr, "fcvtzs'sf 'rd, 'vn");
      } else {
        unknown(instr);
      }
    } else {
      unknown(instr);
    }
  }

  void decodeFPOneSource(Instr instr) {
    final opc = instr.bits(15, 6);

    if ((opc != 5) && (instr.bit(22) != 1)) {
      // Source is interpreted as single-precision only if we're doing a
      // conversion from single -> double.
      unknown(instr);
      return;
    }

    switch (opc) {
      case 0:
        format(instr, "fmovdd 'vd, 'vn");
        break;
      case 1:
        format(instr, "fabsd 'vd, 'vn");
        break;
      case 2:
        format(instr, "fnegd 'vd, 'vn");
        break;
      case 3:
        format(instr, "fsqrtd 'vd, 'vn");
        break;
      case 4:
        format(instr, "fcvtsd 'vd, 'vn");
        break;
      case 5:
        format(instr, "fcvtds 'vd, 'vn");
        break;
      default:
        unknown(instr);
    }
  }

  void decodeFPTwoSource(Instr instr) {
    if (instr.bits(22, 2) != 1) {
      unknown(instr);
      return;
    }
    final opc = instr.bits(12, 4);

    switch (opc) {
      case 0:
        format(instr, "fmuld 'vd, 'vn, 'vm");
        break;
      case 1:
        format(instr, "fdivd 'vd, 'vn, 'vm");
        break;
      case 2:
        format(instr, "faddd 'vd, 'vn, 'vm");
        break;
      case 3:
        format(instr, "fsubd 'vd, 'vn, 'vm");
        break;
      default:
        unknown(instr);
    }
  }

  void decodeFPCompare(Instr instr) {
    if ((instr.bit(22) == 1) && (instr.bits(3, 2) == 0)) {
      format(instr, "fcmpd 'vn, 'vm");
    } else if ((instr.bit(22) == 1) && (instr.bits(3, 2) == 1)) {
      if (instr.vmField() == V0) {
        format(instr, "fcmpd 'vn, #0.0");
      } else {
        unknown(instr);
      }
    } else {
      unknown(instr);
    }
  }
}

class Disassembler {
  static String decodeInstruction(int instruction) {
    final buffer = StringBuffer();
    final decoder = ARM64Decoder(buffer);
    decoder.instructionDecode(Instr(instruction));
    return buffer.toString();
  }

  static String decodeInstructions(Uint32List instructions) {
    final buffer = StringBuffer();
    final decoder = ARM64Decoder(buffer);
    for (final instruction in instructions) {
      decoder.instructionDecode(Instr(instruction));
      buffer.writeln();
    }
    return buffer.toString();
  }
}
