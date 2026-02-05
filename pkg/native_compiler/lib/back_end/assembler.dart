// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:native_compiler/back_end/code.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/back_end/object_pool.dart';
import 'package:native_compiler/runtime/vm_defs.dart';
import 'package:cfg/ir/constant_value.dart' show ConstantValue;

enum OperandSize {
  u8,
  u16,
  u32,
  u64,
  s8,
  s16,
  s32,
  s64;

  bool get is32 => (this == u32) || (this == s32);
  bool get is64 => (this == u64) || (this == s64);
  bool get is32or64 => is32 || is64;

  bool get isSigned =>
      (this == s8) || (this == s16) || (this == s32) || (this == s64);

  int get bitWidth => switch (this) {
    u8 || s8 => 8,
    u16 || s16 => 16,
    u32 || s32 => 32,
    u64 || s64 => 64,
  };

  int get sizeInBytes => switch (this) {
    u8 || s8 => 1,
    u16 || s16 => 2,
    u32 || s32 => 4,
    u64 || s64 => 8,
  };

  int get log2sizeInBytes => switch (this) {
    u8 || s8 => 0,
    u16 || s16 => 1,
    u32 || s32 => 2,
    u64 || s64 => 3,
  };
}

/// Immediate operand.
class Immediate implements Operand {
  final int value;
  const Immediate(this.value);
}

/// Address operand.
abstract interface class Address implements Operand {}

/// [base + offset] address operand.
class RegOffsetAddress implements Address {
  final Register base;
  final int offset;
  RegOffsetAddress(this.base, this.offset);
}

/// Destination of a branch.
class Label {
  int _offset = -1;
  final branchOffsets = <int>[];

  Label();

  bool get isBound => _offset >= 0;

  // Returns relative offset from the branch to the label,
  // or 0 if label is not bound yet.
  int relativeBranchOffset(int branchOffset) {
    if (isBound) {
      return _offset - branchOffset;
    }
    branchOffsets.add(branchOffset);
    return 0;
  }

  void bindTo(int offset) {
    assert(offset >= 0);
    assert(!isBound);
    _offset = offset;
  }
}

enum Condition {
  unconditional,
  equal,
  notEqual,
  less,
  lessOrEqual,
  greater,
  greaterOrEqual,
  unsignedLess,
  unsignedLessOrEqual,
  unsignedGreater,
  unsignedGreaterOrEqual,
  negative,
  positiveOrZero,
  overflow,
  noOverflow;

  static const Condition zero = equal;
  static const Condition notZero = notEqual;
}

/// Base class for architecture-specific assembler.
///
/// Contains declarations of macro-instructions
/// which can be used on all architectures.
abstract base class Assembler {
  final VMOffsets vmOffsets;
  final ObjectPool objectPool = ObjectPool();

  Assembler(this.vmOffsets);

  Uint8List get bytes;

  /// Create a [base + offset] address for arbitrary offset,
  /// generating extra code if necessary.
  /// The resulting address can be used in ordinary load/store instructions.
  Address address(Register base, int offset, [OperandSize sz]);

  /// Create an address for an field of Dart instance.
  Address fieldAddress(Register obj, int offset) =>
      address(obj, offset - heapObjectTag);

  void enterDartFrame();
  void leaveDartFrame();

  // Push and pop values using Dart stackPointerReg.
  void push(Register reg);
  void pop(Register reg);
  void pushPair(Register low, Register high);
  void popPair(Register low, Register high);

  // Labels and branches.
  void bind(Label label);
  void jump(Label label);
  void branchIf(Condition condition, Label label);

  void loadFromPool(Register reg, Object obj);
  void loadConstant(Register reg, ConstantValue value);

  /// Load arbitrary integer [value] into register.
  void loadImmediate(Register reg, int value);

  /// [dst] = [src] + arbitrary integer [value].
  void addImmediate(
    Register dst,
    Register src,
    int value, [
    OperandSize sz = OperandSize.s64,
  ]);

  /// [dst] = [src] - arbitrary integer [value].
  void subImmediate(
    Register dst,
    Register src,
    int value, [
    OperandSize sz = OperandSize.s64,
  ]);

  /// [dst] = bitwise and ([src], arbitrary integer [value]).
  void andImmediate(
    Register dst,
    Register src,
    int value, [
    OperandSize sz = OperandSize.s64,
  ]);

  void callRuntime(RuntimeEntry entry, int argumentCount);
  void callLeafRuntime(LeafRuntimeEntry entry);
  void callStub(Code stub);

  void unimplemented(String message);
}

/// Assembler output buffer holding 32-bit instructions.
mixin Uint32OutputBuffer {
  static const int initialSize = 16;

  Uint32List _buffer = Uint32List(initialSize);
  int _length = 0;

  int get length => _length;

  @pragma("vm:prefer-inline")
  void emit(int instr) {
    if (_length < _buffer.length) {
      _buffer[_length++] = instr;
    } else {
      _expandAndEmit(instr);
    }
  }

  @pragma("vm:never-inline")
  void _expandAndEmit(int instr) {
    final Uint32List old = _buffer;
    _buffer = Uint32List(old.length << 1);
    _buffer.setRange(0, old.length, old);
    _buffer[_length++] = instr;
  }

  int getAt(int offset) => _buffer[offset];

  void setAt(int offset, int instr) {
    _buffer[offset] = instr;
  }

  Uint8List get bytes => _buffer.buffer.asUint8List(0, _length << 2);
}
