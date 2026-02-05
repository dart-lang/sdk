// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/back_end/code.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/back_end/arm64/stack_frame.dart';
import 'package:native_compiler/runtime/vm_defs.dart';
import 'package:cfg/ir/constant_value.dart';

const int log2wordSize = 3;
const int wordSize = 1 << log2wordSize;

// General-purpose registers.
const Register R0 = Register(0, 'R0');
const Register R1 = Register(1, 'R1');
const Register R2 = Register(2, 'R2');
const Register R3 = Register(3, 'R3');
const Register R4 = Register(4, 'R4');
const Register R5 = Register(5, 'R5');
const Register R6 = Register(6, 'R6');
const Register R7 = Register(7, 'R7');
const Register R8 = Register(8, 'R8');
const Register R9 = Register(9, 'R9');
const Register R10 = Register(10, 'R10');
const Register R11 = Register(11, 'R11');
const Register R12 = Register(12, 'R12');
const Register R13 = Register(13, 'R13');
const Register R14 = Register(14, 'R14');
const Register R15 = Register(15, 'R15');
const Register R16 = Register(16, 'R16');
const Register R17 = Register(17, 'R17');
const Register R18 = Register(18, 'R18');
const Register R19 = Register(19, 'R19');
const Register R20 = Register(20, 'R20');
const Register R21 = Register(21, 'R21');
const Register R22 = Register(22, 'R22');
const Register R23 = Register(23, 'R23');
const Register R24 = Register(24, 'R24');
const Register R25 = Register(25, 'R25');
const Register R26 = Register(26, 'R26');
const Register R27 = Register(27, 'R27');
const Register R28 = Register(28, 'R28');
const Register R29 = Register(29, 'R29');
const Register R30 = Register(30, 'R30');
// Intentionally skip R31 as both SP and ZR have the same encoding 31.
const Register SP = Register(32, 'SP');
const Register ZR = Register(33, 'ZR');

const int numberOfRegisters = 32;

// Register aliases.
const Register FP = R29;
const Register LR = R30;
const Register returnReg = R0;
const Register tempReg = R16;
const Register temp2Reg = R17;
const Register poolPointerReg = R27;
const Register dispatchTableReg = R21;
const Register codeReg = R24;
const Register functionReg = R0;
const Register stackPointerReg = R15;
const Register inlineCacheDataReg = R5;
const Register argumentsDescriptorReg = R4;
const Register threadReg = R26;
const Register heapBitsReg = R28;
const Register nullReg = R22;

const Set<Register> allRegisters = {
  R0,
  R1,
  R2,
  R3,
  R4,
  R5,
  R6,
  R7,
  R8,
  R9,
  R10,
  R11,
  R12,
  R13,
  R14,
  R15,
  R16,
  R17,
  R18,
  R19,
  R20,
  R21,
  R22,
  R23,
  R24,
  R25,
  R26,
  R27,
  R28,
  R29,
  R30,
  SP,
  ZR,
};

const Set<Register> reservedRegisters = {
  stackPointerReg,
  tempReg,
  temp2Reg,
  poolPointerReg,
  dispatchTableReg,
  codeReg,
  threadReg,
  heapBitsReg,
  nullReg,
  R18,
  LR,
  FP,
  SP,
  ZR,
};

final allocatableRegisters = allRegisters
    .where((r) => !reservedRegisters.contains(r))
    .toList();

/// Floating-point registers.
const FPRegister V0 = FPRegister(0, 'V0');
const FPRegister V1 = FPRegister(1, 'V1');
const FPRegister V2 = FPRegister(2, 'V2');
const FPRegister V3 = FPRegister(3, 'V3');
const FPRegister V4 = FPRegister(4, 'V4');
const FPRegister V5 = FPRegister(5, 'V5');
const FPRegister V6 = FPRegister(6, 'V6');
const FPRegister V7 = FPRegister(7, 'V7');
const FPRegister V8 = FPRegister(8, 'V8');
const FPRegister V9 = FPRegister(9, 'V9');
const FPRegister V10 = FPRegister(10, 'V10');
const FPRegister V11 = FPRegister(11, 'V11');
const FPRegister V12 = FPRegister(12, 'V12');
const FPRegister V13 = FPRegister(13, 'V13');
const FPRegister V14 = FPRegister(14, 'V14');
const FPRegister V15 = FPRegister(15, 'V15');
const FPRegister V16 = FPRegister(16, 'V16');
const FPRegister V17 = FPRegister(17, 'V17');
const FPRegister V18 = FPRegister(18, 'V18');
const FPRegister V19 = FPRegister(19, 'V19');
const FPRegister V20 = FPRegister(20, 'V20');
const FPRegister V21 = FPRegister(21, 'V21');
const FPRegister V22 = FPRegister(22, 'V22');
const FPRegister V23 = FPRegister(23, 'V23');
const FPRegister V24 = FPRegister(24, 'V24');
const FPRegister V25 = FPRegister(25, 'V25');
const FPRegister V26 = FPRegister(26, 'V26');
const FPRegister V27 = FPRegister(27, 'V27');
const FPRegister V28 = FPRegister(28, 'V28');
const FPRegister V29 = FPRegister(29, 'V29');
const FPRegister V30 = FPRegister(30, 'V30');
const FPRegister V31 = FPRegister(31, 'V31');

const int numberOfFPRegisters = 32;

// Register aliases.
const FPRegister returnFPReg = V0;
const FPRegister fpTempReg = V31;

const Set<FPRegister> allFPRegisters = {
  V0,
  V1,
  V2,
  V3,
  V4,
  V5,
  V6,
  V7,
  V8,
  V9,
  V10,
  V11,
  V12,
  V13,
  V14,
  V15,
  V16,
  V17,
  V18,
  V19,
  V20,
  V21,
  V22,
  V23,
  V24,
  V25,
  V26,
  V27,
  V28,
  V29,
  V30,
  V31,
};

const Set<FPRegister> reservedFPRegisters = {fpTempReg};

final allocatableFPRegisters = allFPRegisters
    .where((r) => !reservedFPRegisters.contains(r))
    .toList();

enum Extend {
  UXTB, // Zero extend byte.
  UXTH, // Zero extend halfword (16 bits).
  UXTW, // Zero extend word (32 bits).
  UXTX, // Zero extend doubleword (64 bits).
  SXTB, // Sign extend byte.
  SXTH, // Sign extend halfword (16 bits).
  SXTW, // Sign extend word (32 bits).
  SXTX, // Sign extend doubleword (64 bits).
}

enum Shift { LSL, LSR, ASR, ROR }

/// reg (LSL|LSR|ASR) #imm operand.
class ShiftedRegOperand implements Operand {
  final Register reg;
  final Shift shift;
  final int shiftAmount;
  const ShiftedRegOperand(this.reg, this.shift, this.shiftAmount);
}

/// reg (U|S)XT(B|H|W|X) #imm operand.
class ExtRegOperand implements Operand {
  final Register reg;
  final Extend ext;
  final int shiftAmount;
  const ExtRegOperand(this.reg, this.ext, [this.shiftAmount = 0])
    : assert(0 <= shiftAmount && shiftAmount <= 4);
}

/// [base + reg LSL #imm] address operand.
class RegRegAddress implements Address {
  final Register base;
  final Register reg;
  final int shift;
  RegRegAddress(this.base, this.reg, this.shift);
}

/// [base + reg (S|U)XTW {imm}] address operand.
class RegExtRegAddress implements Address {
  final Register base;
  final Register reg;
  final Extend ext;
  final bool scaled;
  RegExtRegAddress(this.base, this.reg, this.ext, {this.scaled = false});
}

class WritebackRegOffsetAddress implements Address {
  final Register base;
  final int offset;
  final bool isPostIndexed;
  WritebackRegOffsetAddress(
    this.base,
    this.offset, {
    required this.isPostIndexed,
  });
}

// Bits to simplify encoding of the instructions.
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

/// Assembler targeting ARM64 (ARMv8, AArch64) ISA.
///
/// Arguments of all methods are assumed to be within encoding constraints of
/// the target ISA unless noticed otherwise. This includes all offsets used in
/// addresses, immediates and branch distances.
/// The constraints are checked either with assertions or by throwing errors in
/// invalid cases. Certain macro-instructions can be used to lift these
/// restrictions by generating extra code.
///
/// TODO: support long branches, large offsets and floating-point instructions.
/// TODO: measure performance overhead of always checking encoding constraints.
final class Arm64Assembler extends Assembler with Uint32OutputBuffer {
  Arm64Assembler(super.vmOffsets);

  /// Create a [base + offset] address for arbitrary offset,
  /// generating extra code if necessary.
  /// The resulting address can be used in ldr/str instructions.
  @override
  Address address(
    Register base,
    int offset, [
    OperandSize sz = OperandSize.s64,
  ]) {
    final scale = sz.log2sizeInBytes;
    if (_isInt(9, offset) ||
        (_isUint(12 + scale, offset) &&
            ((offset & (sz.sizeInBytes - 1)) == 0))) {
      return RegOffsetAddress(base, offset);
    } else {
      throw 'Large address offsets are not implemented yet: $offset';
    }
  }

  /// Create a [base + offset] address for arbitrary offset,
  /// generating extra code if necessary.
  /// The resulting address can be used in ldp/stp instructions.
  Address pairAddress(
    Register base,
    int offset, [
    OperandSize sz = OperandSize.s64,
  ]) {
    final scale = sz.log2sizeInBytes;
    if (_isInt(7 + scale, offset) && ((offset & (sz.sizeInBytes - 1)) == 0)) {
      return RegOffsetAddress(base, offset);
    } else {
      throw 'Large address offsets are not implemented yet: $offset';
    }
  }

  @override
  void enterDartFrame() {
    pushPair(FP, LR);
    mov(FP, stackPointerReg);

    // Tag and save caller pool pointer.
    add(poolPointerReg, poolPointerReg, Immediate(heapObjectTag));
    pushPair(poolPointerReg, codeReg);

    // Load and untag current pool pointer.
    ldr(
      poolPointerReg,
      fieldAddress(codeReg, vmOffsets.Code_object_pool_offset),
    );
    sub(poolPointerReg, poolPointerReg, Immediate(heapObjectTag));
  }

  @override
  void leaveDartFrame() {
    // Restore and untag pool pointer.
    ldr(
      poolPointerReg,
      RegOffsetAddress(FP, Arm64StackFrame.poolPointerOffsetFromFP),
    );
    sub(poolPointerReg, poolPointerReg, Immediate(heapObjectTag));

    mov(stackPointerReg, FP);
    popPair(FP, LR);
  }

  @override
  void push(Register reg) {
    str(
      reg,
      WritebackRegOffsetAddress(
        stackPointerReg,
        -wordSize,
        isPostIndexed: false,
      ),
    );
  }

  @override
  void pop(Register reg) {
    ldr(
      reg,
      WritebackRegOffsetAddress(stackPointerReg, wordSize, isPostIndexed: true),
    );
  }

  @override
  void pushPair(Register low, Register high) {
    stp(
      low,
      high,
      WritebackRegOffsetAddress(
        stackPointerReg,
        -2 * wordSize,
        isPostIndexed: false,
      ),
    );
  }

  @override
  void popPair(Register low, Register high) {
    ldp(
      low,
      high,
      WritebackRegOffsetAddress(
        stackPointerReg,
        2 * wordSize,
        isPostIndexed: true,
      ),
    );
  }

  @override
  void bind(Label label) {
    final offset = length;
    label.bindTo(offset);
    for (final branchOffset in label.branchOffsets) {
      final instr = getAt(branchOffset);
      if ((instr & (B30 | B29 | B28 | B27 | B26)) == (B28 | B26)) {
        // Unconditional branch.
        assert((instr & 0x3ffffff) == 0);
        setAt(branchOffset, instr | label.encodingImm26(branchOffset));
      } else if ((instr &
              (B31 | B30 | B29 | B28 | B27 | B26 | B25 | B24 | B4)) ==
          (B30 | B28 | B26)) {
        // Conditional branch.
        assert(((instr >> 5) & 0x7ffff) == 0);
        setAt(branchOffset, instr | label.encodingImm19(branchOffset));
      } else if ((instr & (B30 | B29 | B28 | B27 | B26 | B25)) ==
          (B29 | B28 | B26)) {
        // Compare and branch.
        assert(((instr >> 5) & 0x7ffff) == 0);
        setAt(branchOffset, instr | label.encodingImm19(branchOffset));
      } else if ((instr & (B30 | B29 | B28 | B27 | B26 | B25)) ==
          (B29 | B28 | B26 | B25)) {
        // Test and branch.
        assert(((instr >> 5) & 0x3fff) == 0);
        setAt(branchOffset, instr | label.encodingImm14(branchOffset));
      } else {
        throw 'Unrecognized instruction ${instr.toRadixString(16)} at $branchOffset';
      }
    }
  }

  @override
  void jump(Label label) {
    b(label);
  }

  @override
  void branchIf(Condition condition, Label label) {
    b(label, condition);
  }

  @override
  void loadFromPool(Register reg, Object obj) {
    int poolIndex = objectPool.getObject(obj);
    ldr(
      reg,
      address(poolPointerReg, vmOffsets.ObjectPool_elementOffset(poolIndex)),
    );
  }

  @override
  void loadConstant(Register reg, ConstantValue value) {
    assert(reg != SP);

    if (value.isInt) {
      loadImmediate(reg, value.intValue);
    } else {
      loadFromPool(reg, value as Object);
    }
  }

  @override
  void loadImmediate(Register reg, int v) {
    assert(reg != SP);

    if (v >= 0) {
      // One movz.
      for (var shift = 0; shift < 64; shift += 16) {
        if (v & (0xffff << shift) == v) {
          movz(reg, (v >> shift) & 0xffff, shift);
          return;
        }
      }
    } else {
      // One movn.
      final negated = ~v;
      for (var shift = 0; shift < 64; shift += 16) {
        if (negated & (0xffff << shift) == negated) {
          movn(reg, (negated >> shift) & 0xffff, shift);
          return;
        }
      }
    }

    // One orr.
    if (canEncodeBitMasks(v)) {
      orr(reg, ZR, Immediate(v));
      return;
    }

    // Count number of 0 and 0xffff 16-bit parts.
    var countZ = 0, countN = 0;
    for (var shift = 0; shift < 64; shift += 16) {
      final mask = 0xffff << shift;
      if (v & mask == 0) {
        ++countZ;
      } else if (v & mask == mask) {
        ++countN;
      }
    }

    // Start with movz or movn, continue with movk.
    var initialized = false;
    final defaultValue = (countZ >= countN) ? 0 : 0xffff;
    for (var shift = 0; shift < 64; shift += 16) {
      final part = (v >> shift) & 0xffff;
      if (part != defaultValue) {
        if (initialized) {
          movk(reg, part, shift);
        } else {
          if (defaultValue == 0) {
            movz(reg, part, shift);
          } else {
            movn(reg, (~part) & 0xffff, shift);
          }
          initialized = true;
        }
      }
    }
    assert(initialized);
  }

  bool canEncodeImm12(int value) =>
      _isUint(12, value) || (value & 0xfff == 0 && _isUint(12, value >> 12));

  bool canEncodeBitMasks(int value, [OperandSize sz = OperandSize.s64]) =>
      Immediate(value).tryEncodingBitMasks(sz) != null;

  @override
  void addImmediate(
    Register dst,
    Register src,
    int value, [
    OperandSize sz = OperandSize.s64,
  ]) {
    assert(sz.is32or64);
    assert(_isInt(sz.bitWidth, value) || _isUint(sz.bitWidth, value));
    if (value == 0) {
      if (dst != src) {
        mov(dst, src, sz);
      }
    } else if (canEncodeImm12(value)) {
      add(dst, src, Immediate(value), sz);
    } else if (canEncodeImm12(-value)) {
      sub(dst, src, Immediate(-value), sz);
    } else {
      assert(src != tempReg);
      loadImmediate(tempReg, value);
      if (dst == SP || src == SP) {
        add(dst, src, ExtRegOperand(tempReg, .UXTX, 0), sz);
      } else {
        add(dst, src, tempReg, sz);
      }
    }
  }

  @override
  void subImmediate(
    Register dst,
    Register src,
    int value, [
    OperandSize sz = OperandSize.s64,
  ]) {
    assert(sz.is32or64);
    assert(_isInt(sz.bitWidth, value) || _isUint(sz.bitWidth, value));
    if (value == 0) {
      if (dst != src) {
        mov(dst, src, sz);
      }
    } else if (canEncodeImm12(value)) {
      sub(dst, src, Immediate(value), sz);
    } else if (canEncodeImm12(-value)) {
      add(dst, src, Immediate(-value), sz);
    } else {
      assert(src != tempReg);
      loadImmediate(tempReg, value);
      if (dst == SP || src == SP) {
        sub(dst, src, ExtRegOperand(tempReg, .UXTX, 0), sz);
      } else {
        sub(dst, src, tempReg, sz);
      }
    }
  }

  @override
  void andImmediate(
    Register dst,
    Register src,
    int value, [
    OperandSize sz = OperandSize.s64,
  ]) {
    assert(sz.is32or64);
    assert(_isInt(sz.bitWidth, value) || _isUint(sz.bitWidth, value));
    if (value == 0) {
      movz(dst, 0);
    } else if (value == -1) {
      mov(dst, src, sz);
    } else if (canEncodeBitMasks(value, sz)) {
      and(dst, src, Immediate(value), sz);
    } else {
      assert(src != tempReg);
      loadImmediate(tempReg, value);
      and(dst, src, tempReg, sz);
    }
  }

  @override
  void callRuntime(RuntimeEntry entry, int argumentCount) {
    ldr(
      R5,
      address(
        threadReg,
        vmOffsets.Thread_runtime_entry_offset(entry, wordSize),
      ),
    );
    loadImmediate(R4, argumentCount);
    ldr(
      LR,
      address(threadReg, vmOffsets.Thread_call_to_runtime_entry_point_offset),
    );
    blr(LR);
  }

  @override
  void callLeafRuntime(LeafRuntimeEntry entry) {
    unimplemented("callLeafRuntime $entry");
  }

  @override
  void callStub(Code stub) {
    loadFromPool(codeReg, stub);
    ldr(LR, fieldAddress(codeReg, vmOffsets.Code_entry_point_offset.first));
    blr(LR);
  }

  @override
  void unimplemented(String message) {
    loadConstant(R0, ConstantValue.fromString(message));
    push(R0);
    callRuntime(RuntimeEntry.FatalError, 1);
  }

  // [rd] and [rn] can be SP if [o] is Immediate or ExtRegOperand.
  // For an unmodified rm in this case, use ExtRegOperand(rm, Extend.UXTX, 0).
  void add(
    Register rd,
    Register rn,
    Operand o, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitAddSub(rd, rn, o, sz, false, false);
  }

  // [rn] can be SP if [o] is Immediate or ExtRegOperand.
  // For an unmodified rm in this case, use ExtRegOperand(rm, Extend.UXTX, 0).
  void adds(
    Register rd,
    Register rn,
    Operand o, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitAddSub(rd, rn, o, sz, true, false);
  }

  // [rd] and [rn] can be SP if [o] is Immediate or ExtRegOperand.
  // For an unmodified rm in this case, use ExtRegOperand(rm, Extend.UXTX, 0).
  void sub(
    Register rd,
    Register rn,
    Operand o, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitAddSub(rd, rn, o, sz, false, true);
  }

  // [rn] can be SP if [o] is Immediate or ExtRegOperand.
  void subs(
    Register rd,
    Register rn,
    Operand o, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitAddSub(rd, rn, o, sz, true, true);
  }

  void addw(Register rd, Register rn, Operand o) {
    add(rd, rn, o, OperandSize.s32);
  }

  void addsw(Register rd, Register rn, Operand o) {
    adds(rd, rn, o, OperandSize.s32);
  }

  void subw(Register rd, Register rn, Operand o) {
    sub(rd, rn, o, OperandSize.s32);
  }

  void subsw(Register rd, Register rn, Operand o) {
    subs(rd, rn, o, OperandSize.s32);
  }

  void cmp(Register rn, Operand o, [OperandSize sz = OperandSize.s64]) {
    subs(ZR, rn, o, sz);
  }

  void cmn(Register rn, Operand o, [OperandSize sz = OperandSize.s64]) {
    adds(ZR, rn, o, sz);
  }

  void _emitAddSub(
    Register rd,
    Register rn,
    Operand o,
    OperandSize sz,
    bool setFlags,
    bool subtract,
  ) {
    assert(sz.is32or64);
    if (o is Register) {
      o = ShiftedRegOperand(o, Shift.LSL, 0);
    }
    switch (o) {
      case Immediate():
        emit(
          (B24 | B28) |
              rd.encodingRd(allowSP: !setFlags) |
              rn.encodingRn(allowSP: true) |
              o.encodingImm12 |
              (setFlags ? B29 : 0) |
              (subtract ? B30 : 0) |
              (sz.is64 ? B31 : 0),
        );
      case ShiftedRegOperand():
        emit(
          (B24 | B25 | B27) |
              rd.encodingRd() |
              rn.encodingRn() |
              o.encoding(sz) |
              (setFlags ? B29 : 0) |
              (subtract ? B30 : 0) |
              (sz.is64 ? B31 : 0),
        );
      case ExtRegOperand():
        emit(
          (B24 | B25 | B27) |
              rd.encodingRd(allowSP: !setFlags) |
              rn.encodingRn(allowSP: true) |
              o.encoding |
              (setFlags ? B29 : 0) |
              (subtract ? B30 : 0) |
              (sz.is64 ? B31 : 0),
        );
      default:
        throw 'Unexpect operand ${o.runtimeType}';
    }
  }

  void adc(
    Register rd,
    Register rn,
    Register rm, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitAddSubWithCarry(rd, rn, rm, sz, false, false);
  }

  void adcs(
    Register rd,
    Register rn,
    Register rm, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitAddSubWithCarry(rd, rn, rm, sz, true, false);
  }

  void sbc(
    Register rd,
    Register rn,
    Register rm, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitAddSubWithCarry(rd, rn, rm, sz, false, true);
  }

  void sbcs(
    Register rd,
    Register rn,
    Register rm, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitAddSubWithCarry(rd, rn, rm, sz, true, true);
  }

  void adcw(Register rd, Register rn, Register rm) {
    adc(rd, rn, rm, OperandSize.s32);
  }

  void adcsw(Register rd, Register rn, Register rm) {
    adcs(rd, rn, rm, OperandSize.s32);
  }

  void sbcw(Register rd, Register rn, Register rm) {
    sbc(rd, rn, rm, OperandSize.s32);
  }

  void sbcsw(Register rd, Register rn, Register rm) {
    sbcs(rd, rn, rm, OperandSize.s32);
  }

  void _emitAddSubWithCarry(
    Register rd,
    Register rn,
    Register rm,
    OperandSize sz,
    bool setFlags,
    bool subtract,
  ) {
    assert(sz.is32or64);
    emit(
      (B25 | B27 | B28) |
          rd.encodingRd() |
          rn.encodingRn() |
          rm.encodingRm() |
          (setFlags ? B29 : 0) |
          (subtract ? B30 : 0) |
          (sz.is64 ? B31 : 0),
    );
  }

  void bfm(
    Register rd,
    Register rn,
    int immR,
    int immS, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitBitfieldMove(B24 | B25 | B28 | B29, rd, rn, immR, immS, sz);
  }

  void sbfm(
    Register rd,
    Register rn,
    int immR,
    int immS, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitBitfieldMove(B24 | B25 | B28, rd, rn, immR, immS, sz);
  }

  void ubfm(
    Register rd,
    Register rn,
    int immR,
    int immS, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitBitfieldMove(B24 | B25 | B28 | B30, rd, rn, immR, immS, sz);
  }

  void bfi(
    Register rd,
    Register rn,
    int lowBit,
    int width, [
    OperandSize sz = OperandSize.s64,
  ]) {
    assert(sz.is32or64);
    bfm(rd, rn, (-lowBit) & (sz.bitWidth - 1), width - 1, sz);
  }

  void bfc(
    Register rd,
    int lowBit,
    int width, [
    OperandSize sz = OperandSize.s64,
  ]) {
    assert(sz.is32or64);
    bfm(rd, ZR, (-lowBit) & (sz.bitWidth - 1), width - 1, sz);
  }

  void bfxil(
    Register rd,
    Register rn,
    int lowBit,
    int width, [
    OperandSize sz = OperandSize.s64,
  ]) {
    bfm(rd, rn, lowBit, lowBit + width - 1, sz);
  }

  void sbfiz(
    Register rd,
    Register rn,
    int lowBit,
    int width, [
    OperandSize sz = OperandSize.s64,
  ]) {
    assert(sz.is32or64);
    sbfm(rd, rn, (-lowBit) & (sz.bitWidth - 1), width - 1, sz);
  }

  void sbfx(
    Register rd,
    Register rn,
    int lowBit,
    int width, [
    OperandSize sz = OperandSize.s64,
  ]) {
    sbfm(rd, rn, lowBit, lowBit + width - 1, sz);
  }

  void ubfiz(
    Register rd,
    Register rn,
    int lowBit,
    int width, [
    OperandSize sz = OperandSize.s64,
  ]) {
    assert(sz.is32or64);
    ubfm(rd, rn, (-lowBit) & (sz.bitWidth - 1), width - 1, sz);
  }

  void ubfx(
    Register rd,
    Register rn,
    int lowBit,
    int width, [
    OperandSize sz = OperandSize.s64,
  ]) {
    ubfm(rd, rn, lowBit, lowBit + width - 1, sz);
  }

  void sxtb(Register rd, Register rn, [OperandSize sz = OperandSize.s64]) {
    sbfm(rd, rn, 0, 7, sz);
  }

  void sxth(Register rd, Register rn, [OperandSize sz = OperandSize.s64]) {
    sbfm(rd, rn, 0, 15, sz);
  }

  void sxtw(Register rd, Register rn) {
    sbfm(rd, rn, 0, 31, OperandSize.s64);
  }

  void uxtb(Register rd, Register rn, [OperandSize sz = OperandSize.s64]) {
    ubfm(rd, rn, 0, 7, sz);
  }

  void uxth(Register rd, Register rn, [OperandSize sz = OperandSize.s64]) {
    ubfm(rd, rn, 0, 15, sz);
  }

  void _emitBitfieldMove(
    int opcode,
    Register rd,
    Register rn,
    int immR,
    int immS,
    OperandSize sz,
  ) {
    assert(sz.is32or64);
    assert(0 <= immR && immR < sz.bitWidth);
    assert(0 <= immS && immS < sz.bitWidth);
    emit(
      opcode |
          rd.encodingRd() |
          rn.encodingRn() |
          (immS << 10) |
          (immR << 16) |
          (sz.is64 ? (B31 | B22) : 0),
    );
  }

  // Logical operations with immediate or shifted register.
  void and(
    Register rd,
    Register rn,
    Operand o, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitLogical(0, rd, rn, o, sz, false, true);
  }

  void ands(
    Register rd,
    Register rn,
    Operand o, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitLogical(B29 | B30, rd, rn, o, sz, true, true);
  }

  void eor(
    Register rd,
    Register rn,
    Operand o, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitLogical(B30, rd, rn, o, sz, false, true);
  }

  void orr(
    Register rd,
    Register rn,
    Operand o, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitLogical(B29, rd, rn, o, sz, false, true);
  }

  void tst(Register rn, Operand o, [OperandSize sz = OperandSize.s64]) {
    ands(ZR, rn, o, sz);
  }

  void andw(Register rd, Register rn, Operand o) {
    and(rd, rn, o, OperandSize.s32);
  }

  void eorw(Register rd, Register rn, Operand o) {
    eor(rd, rn, o, OperandSize.s32);
  }

  void orrw(Register rd, Register rn, Operand o) {
    orr(rd, rn, o, OperandSize.s32);
  }

  // Logical operations with shifted register.
  void bic(
    Register rd,
    Register rn,
    Operand o, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitLogical(B21, rd, rn, o, sz, false, false);
  }

  void bics(
    Register rd,
    Register rn,
    Operand o, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitLogical(B21 | B29 | B30, rd, rn, o, sz, false, false);
  }

  void eon(
    Register rd,
    Register rn,
    Operand o, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitLogical(B21 | B30, rd, rn, o, sz, false, false);
  }

  void orn(
    Register rd,
    Register rn,
    Operand o, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitLogical(B21 | B29, rd, rn, o, sz, false, false);
  }

  void mvn(Register rd, Operand o, [OperandSize sz = OperandSize.s64]) {
    orn(rd, ZR, o, sz);
  }

  void bicw(Register rd, Register rn, Operand o) {
    bic(rd, rn, o, OperandSize.s32);
  }

  void eonw(Register rd, Register rn, Operand o) {
    eon(rd, rn, o, OperandSize.s32);
  }

  void ornw(Register rd, Register rn, Operand o) {
    orn(rd, rn, o, OperandSize.s32);
  }

  void mov(Register rd, Register rn, [OperandSize sz = OperandSize.s64]) {
    if ((rd == SP) || (rn == SP)) {
      add(rd, rn, Immediate(0), sz);
    } else {
      orr(rd, ZR, rn, sz);
    }
  }

  void movw(Register rd, Register rn) {
    mov(rd, rn, OperandSize.s32);
  }

  void _emitLogical(
    int opcode,
    Register rd,
    Register rn,
    Operand o,
    OperandSize sz,
    bool setFlags,
    bool allowImmediate,
  ) {
    assert(sz.is32or64);
    if (o is Register) {
      o = ShiftedRegOperand(o, Shift.LSL, 0);
    }
    switch (o) {
      case Immediate():
        assert(allowImmediate);
        emit(
          B25 |
              B28 |
              opcode |
              rd.encodingRd(allowSP: !setFlags) |
              rn.encodingRn() |
              o.encodingBitMasks(sz) |
              (sz.is64 ? B31 : 0),
        );
      case ShiftedRegOperand():
        emit(
          B25 |
              B27 |
              opcode |
              rd.encodingRd() |
              rn.encodingRn() |
              o.encoding(sz) |
              (sz.is64 ? B31 : 0),
        );
      default:
        throw 'Unexpect operand ${o.runtimeType}';
    }
  }

  void movz(
    Register rd,
    int value, [
    int shift = 0,
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitMoveImm(B30, rd, value, shift, sz);
  }

  void movn(
    Register rd,
    int value, [
    int shift = 0,
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitMoveImm(0, rd, value, shift, sz);
  }

  void movk(
    Register rd,
    int value, [
    int shift = 0,
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitMoveImm(B29 | B30, rd, value, shift, sz);
  }

  void _emitMoveImm(
    int opcode,
    Register rd,
    int value,
    int shift,
    OperandSize sz,
  ) {
    assert(_isUint(16, value));
    assert(
      shift == 0 || shift == 16 || sz.is64 && (shift == 32 || shift == 48),
    );
    assert(sz.is32or64);
    emit(
      B28 |
          B25 |
          B23 |
          opcode |
          ((shift >> 4) << 21) |
          (value << 5) |
          rd.encodingRd() |
          (sz.is64 ? B31 : 0),
    );
  }

  void ldr(Register rt, Address a, [OperandSize sz = OperandSize.s64]) {
    final needsSignExtension = !sz.is64 && sz.isSigned;
    _emitLoadStore(
      B22 | B27 | B28 | B29 | (needsSignExtension ? B23 : 0),
      rt,
      a,
      sz,
    );
  }

  void str(Register rt, Address a, [OperandSize sz = OperandSize.s64]) {
    _emitLoadStore(B27 | B28 | B29, rt, a, sz);
  }

  void _emitLoadStore(int opcode, Register rt, Address a, OperandSize sz) {
    switch (a) {
      case RegOffsetAddress():
        emit(
          opcode |
              rt.encodingRt() |
              a.encoding(sz) |
              (sz.log2sizeInBytes << 30),
        );
      case WritebackRegOffsetAddress():
        // Same value and base registers in case of pre- and
        // post-indexing is unpredictable.
        assert(rt != a.base);
        emit(
          opcode |
              rt.encodingRt() |
              a.encoding(sz) |
              (sz.log2sizeInBytes << 30),
        );
      default:
        throw 'Unexpect address ${a.runtimeType}';
    }
  }

  void ldp(
    Register low,
    Register high,
    Address a, [
    OperandSize sz = OperandSize.s64,
  ]) {
    assert(low != high);
    assert(sz.is32or64);
    _emitLoadStorePair(
      B22 | B27 | B29 | (sz == OperandSize.s32 ? B30 : 0),
      low,
      high,
      a,
      sz,
    );
  }

  void stp(
    Register low,
    Register high,
    Address a, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitLoadStorePair(B27 | B29, low, high, a, sz);
  }

  void ldpsw(Register low, Register high, Address a) {
    ldp(low, high, a, OperandSize.s32);
  }

  void _emitLoadStorePair(
    int opcode,
    Register rt,
    Register rt2,
    Address a,
    OperandSize sz,
  ) {
    assert(sz.is32or64);
    switch (a) {
      case RegOffsetAddress():
        emit(
          opcode |
              rt.encodingRt() |
              rt2.encodingRt2() |
              a.encodingPair(sz) |
              (sz.is64 ? B31 : 0),
        );
      case WritebackRegOffsetAddress():
        // Same value and base registers in case of pre- and
        // post-indexing is unpredictable.
        assert(rt != a.base);
        assert(rt2 != a.base);
        emit(
          opcode |
              rt.encodingRt() |
              rt2.encodingRt2() |
              a.encodingPair(sz) |
              (sz.is64 ? B31 : 0),
        );
      default:
        throw 'Unexpect address ${a.runtimeType}';
    }
  }

  void nop() {
    emit(
      B31 | B30 | B28 | B26 | B24 | B17 | B16 | B13 | B4 | B3 | B2 | B1 | B0,
    );
  }

  void b(Label label, [Condition condition = Condition.unconditional]) {
    final branchOffset = length;
    if (condition == Condition.unconditional) {
      emit(B28 | B26 | label.encodingImm26(branchOffset));
    } else {
      emit(
        B30 |
            B28 |
            B26 |
            label.encodingImm19(branchOffset) |
            condition.encoding,
      );
    }
  }

  void cbz(Register rt, Label label, [OperandSize sz = OperandSize.s64]) {
    _emitCompareAndBranch(rt, label, sz, false);
  }

  void cbnz(Register rt, Label label, [OperandSize sz = OperandSize.s64]) {
    _emitCompareAndBranch(rt, label, sz, true);
  }

  void _emitCompareAndBranch(
    Register rt,
    Label label,
    OperandSize sz,
    bool isNonZero,
  ) {
    assert(sz.is32or64);
    final branchOffset = length;
    emit(
      B29 |
          B28 |
          B26 |
          (isNonZero ? B24 : 0) |
          label.encodingImm19(branchOffset) |
          rt.encodingRt() |
          (sz.is64 ? B31 : 0),
    );
  }

  void tbz(
    Register rt,
    int bitNumber,
    Label label, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitTestAndBranch(rt, bitNumber, label, sz, false);
  }

  void tbnz(
    Register rt,
    int bitNumber,
    Label label, [
    OperandSize sz = OperandSize.s64,
  ]) {
    _emitTestAndBranch(rt, bitNumber, label, sz, true);
  }

  void _emitTestAndBranch(
    Register rt,
    int bitNumber,
    Label label,
    OperandSize sz,
    bool isNonZero,
  ) {
    assert(sz.is32or64);
    assert(0 <= bitNumber && bitNumber < sz.bitWidth);
    final branchOffset = length;
    emit(
      B29 |
          B28 |
          B26 |
          B25 |
          (isNonZero ? B24 : 0) |
          ((bitNumber & 0x1f) << 19) |
          label.encodingImm14(branchOffset) |
          rt.encodingRt() |
          (bitNumber >= 32 ? B31 : 0),
    );
  }

  void br(Register rn) {
    _emitBranchReg(0, rn);
  }

  void blr(Register rn) {
    _emitBranchReg(B21, rn);
  }

  void ret([Register rn = LR]) {
    _emitBranchReg(B22, rn);
  }

  void _emitBranchReg(int opcode, Register rn) {
    emit(
      B31 |
          B30 |
          B28 |
          B26 |
          B25 |
          B20 |
          B19 |
          B18 |
          B17 |
          B16 |
          opcode |
          rn.encodingRn(),
    );
  }
}

bool _isUint(int numBits, int value) => (value >>> numBits) == 0;
bool _isInt(int numBits, int value) {
  final shiftedOut = value >> (numBits - 1);
  return shiftedOut == 0 || shiftedOut == -1;
}

extension on Register {
  int encoding({bool allowSP = false}) {
    if (allowSP) {
      assert(0 <= index && index <= 30 || this == SP);
      return (this == SP) ? 31 : index;
    } else {
      assert(0 <= index && index <= 30 || this == ZR);
      return (this == ZR) ? 31 : index;
    }
  }

  int encodingRd({bool allowSP = false}) => encoding(allowSP: allowSP);
  int encodingRn({bool allowSP = false}) => encoding(allowSP: allowSP) << 5;
  int encodingRm({bool allowSP = false}) => encoding(allowSP: allowSP) << 16;
  int encodingRt({bool allowSP = false}) => encoding(allowSP: allowSP);
  int encodingRt2({bool allowSP = false}) => encoding(allowSP: allowSP) << 10;
}

extension on Immediate {
  int get encodingImm12 {
    if (_isUint(12, value)) {
      return value << 10;
    } else if (value & 0xfff == 0 && _isUint(12, value >> 12)) {
      return B22 | ((value >> 12) << 10);
    } else {
      throw 'Immediate $value cannot be encoded as imm12';
    }
  }

  int encodingBitMasks(OperandSize sz) =>
      tryEncodingBitMasks(sz) ??
      (throw 'Immediate $value cannot be encoded as bitmasks');

  int? tryEncodingBitMasks(OperandSize sz) {
    assert(sz.is32or64);
    int value = this.value;
    if (sz.is32) {
      // Ignore high 32 bits of 32-bit operands.
      value = value & 0xffffffff;
    }

    var n = 0;
    var immS = 0;
    var immR = 0;

    // Logical immediates are encoded using parameters N, imms and immr using
    // the following table:
    //
    //  N   imms    immr    size     S       R
    //  1  ssssss  rrrrrr    64    ssssss  rrrrrr
    //  0  0sssss  xrrrrr    32    sssss   rrrrr
    //  0  10ssss  xxrrrr    16    ssss    rrrr
    //  0  110sss  xxxrrr     8    sss     rrr
    //  0  1110ss  xxxxrr     4    ss      rr
    //  0  11110s  xxxxxr     2    s       r
    // (s bits must not be all set)
    //
    // A pattern is constructed of size bits, where the least significant S+1
    // bits are set. The pattern is rotated right by R, and repeated across a
    // 32 or 64-bit value, depending on destination register width.
    //
    // To test if an arbitrary immediate can be encoded using this scheme, an
    // iterative algorithm is used.

    // 1. If the value has all set or all clear bits, it can't be encoded.
    if (value == 0 || value == -1 || (sz.is32 && value == 0xffffffff)) {
      return null;
    }

    int width = sz.bitWidth;
    final leadingZeros = _countLeadingZeros(value, sz);
    final leadingOnes = _countLeadingZeros(
      ~value & (sz.is32 ? 0xffffffff : -1),
      sz,
    );
    final trailingZeros = _countTrailingZeros(value);
    final trailingOnes = _countTrailingZeros(~value);
    int setBits = _countOneBits(value);

    // The fixed bits in the immediate s field.
    // If width == 64 (X reg), start at 0xFFFFFF80.
    // If width == 32 (W reg), start at 0xFFFFFFC0, as the iteration for 64-bit
    // widths won't be executed.
    var immSFixed = sz.is64 ? -128 : -64;
    const immSMask = 0x3F;

    for (;;) {
      // 2. If the value is two bits wide, it can be encoded.
      if (width == 2) {
        n = 0;
        immS = 0x3C;
        immR = (value & 3) - 1;
        break;
      }

      n = (width == 64) ? 1 : 0;
      immS = ((immSFixed | (setBits - 1)) & immSMask);
      if ((leadingZeros + setBits) == width) {
        immR = 0;
      } else {
        immR = (leadingZeros > 0) ? (width - trailingZeros) : leadingOnes;
      }

      // 3. If the sum of leading zeros, trailing zeros and set bits is equal to
      //    the bit width of the value, it can be encoded.
      if (leadingZeros + trailingZeros + setBits == width) {
        break;
      }

      // 4. If the sum of leading ones, trailing ones and unset bits in the
      //    value is equal to the bit width of the value, it can be encoded.
      if (leadingOnes + trailingOnes + (width - setBits) == width) {
        break;
      }

      // 5. If the most-significant half of the bitwise value is equal to the
      //    least-significant half, return to step 2 using the least-significant
      //    half of the value.
      final mask = (1 << (width >> 1)) - 1;
      if ((value & mask) == ((value >> (width >> 1)) & mask)) {
        width >>= 1;
        setBits >>= 1;
        immSFixed >>= 1;
        continue;
      }

      // 6. Otherwise, the value can't be encoded.
      return null;
    }
    assert(_isUint(6, immR));
    assert(_isUint(6, immS));
    return (n << 22) | (immR << 16) | (immS << 10);
  }

  static int _countLeadingZeros(int value, OperandSize sz) =>
      value < 0 ? 0 : (sz.bitWidth - value.bitLength);

  static int _countTrailingZeros(int value) {
    var n = 0;
    while ((value & 0xff) == 0) {
      n += 8;
      value = value >>> 8;
    }
    while ((value & 1) == 0) {
      ++n;
      value = value >>> 1;
    }
    return n;
  }

  static int _countOneBits(int value) {
    value = ((value >>> 1) & 0x5555555555555555) + (value & 0x5555555555555555);
    value = ((value >>> 2) & 0x3333333333333333) + (value & 0x3333333333333333);
    value = ((value >>> 4) & 0x0f0f0f0f0f0f0f0f) + (value & 0x0f0f0f0f0f0f0f0f);
    value = ((value >>> 8) & 0x00ff00ff00ff00ff) + (value & 0x00ff00ff00ff00ff);
    value =
        ((value >>> 16) & 0x0000ffff0000ffff) + (value & 0x0000ffff0000ffff);
    value =
        ((value >>> 32) & 0x00000000ffffffff) + (value & 0x00000000ffffffff);
    return value;
  }
}

extension on ExtRegOperand {
  int get encoding {
    assert(0 <= shiftAmount && shiftAmount <= 4);
    return B21 | reg.encodingRm() | (ext.index << 13) | (shiftAmount << 10);
  }
}

extension on ShiftedRegOperand {
  int encoding(OperandSize sz) {
    assert(0 <= shiftAmount && shiftAmount < sz.bitWidth);
    return reg.encodingRm() | (shift.index << 22) | (shiftAmount << 10);
  }
}

extension on RegOffsetAddress {
  int encoding(OperandSize sz) {
    final scale = sz.log2sizeInBytes;
    if (_isUint(12 + scale, offset) && ((offset & (sz.sizeInBytes - 1)) == 0)) {
      return B24 | ((offset >> scale) << 10) | base.encodingRn(allowSP: true);
    } else if (_isInt(9, offset)) {
      return ((offset & 0x1ff) << 12) | base.encodingRn(allowSP: true);
    } else {
      throw 'Address offset is out of range: $offset';
    }
  }

  int encodingPair(OperandSize sz) {
    final scale = sz.log2sizeInBytes;
    assert(_isInt(7 + scale, offset) && ((offset & (sz.sizeInBytes - 1)) == 0));
    return B24 |
        (((offset >> scale) & 0x7f) << 15) |
        base.encodingRn(allowSP: true);
  }
}

extension on WritebackRegOffsetAddress {
  int encoding(OperandSize sz) {
    assert(_isInt(9, offset));
    return (isPostIndexed ? B10 : (B10 | B11)) |
        ((offset & 0x1ff) << 12) |
        base.encodingRn(allowSP: true);
  }

  int encodingPair(OperandSize sz) {
    final scale = sz.log2sizeInBytes;
    assert(_isInt(7 + scale, offset) && ((offset & (sz.sizeInBytes - 1)) == 0));
    return (isPostIndexed ? B23 : (B23 | B24)) |
        (((offset >> scale) & 0x7f) << 15) |
        base.encodingRn(allowSP: true);
  }
}

extension on Label {
  int encodingImm14(int branchOffset) {
    final relativeOffset = relativeBranchOffset(branchOffset);
    assert(_isInt(14, relativeOffset));
    return (relativeOffset & 0x3fff) << 5;
  }

  int encodingImm19(int branchOffset) {
    final relativeOffset = relativeBranchOffset(branchOffset);
    assert(_isInt(19, relativeOffset));
    return (relativeOffset & 0x7ffff) << 5;
  }

  int encodingImm26(int branchOffset) {
    final relativeOffset = relativeBranchOffset(branchOffset);
    assert(_isInt(26, relativeOffset));
    return (relativeOffset & 0x3ffffff);
  }
}

extension on Condition {
  int get encoding => switch (this) {
    Condition.equal => 0, // EQ
    Condition.notEqual => 1, // NE
    Condition.unsignedGreaterOrEqual => 2, // CS/HS
    Condition.unsignedLess => 3, // CC/LO
    Condition.negative => 4, // MI
    Condition.positiveOrZero => 5, // PL
    Condition.overflow => 6, // VS
    Condition.noOverflow => 7, // VC
    Condition.unsignedGreater => 8, // HI
    Condition.unsignedLessOrEqual => 9, // LS
    Condition.greaterOrEqual => 10, // GE
    Condition.less => 11, // LT
    Condition.greater => 12, // GT
    Condition.lessOrEqual => 13, // LE
    Condition.unconditional => 14, // AL
  };
}
