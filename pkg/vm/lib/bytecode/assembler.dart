// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.assembler;

import 'package:kernel/ast.dart' show TreeNode;
import 'package:vm/bytecode/options.dart';

import 'dbc.dart';
import 'exceptions.dart' show ExceptionsTable;
import 'local_variable_table.dart' show LocalVariableTable;
import 'source_positions.dart' show SourcePositions;

import 'dart:typed_data' show Uint8List;

class Label {
  final bool allowsBackwardJumps;
  List<int> _jumps = <int>[];
  int offset = -1;

  Label({this.allowsBackwardJumps: false});

  bool get isBound => offset >= 0;

  int jumpOperand(int jumpOffset) {
    if (isBound) {
      if (offset <= jumpOffset && !allowsBackwardJumps) {
        throw 'Backward jump to this label is not allowed';
      }
      // Jump instruction takes a relative offset.
      return offset - jumpOffset;
    }
    _jumps.add(jumpOffset);
    return 0;
  }

  List<int> bind(int offset) {
    assert(!isBound);
    this.offset = offset;
    final jumps = _jumps;
    _jumps = null;
    return jumps;
  }
}

class BytecodeAssembler {
  static const int kByteMask = 0xFF;
  static const int kUint32Mask = 0xFFFFFFFF;
  static const int kMinInt8 = -0x80;
  static const int kMaxInt8 = 0x7F;
  static const int kMinInt24 = -0x800000;
  static const int kMaxInt24 = 0x7FFFFF;
  static const int kMinInt32 = -0x80000000;
  static const int kMaxInt32 = 0x7FFFFFFF;

  static const int kInitialCapacity = 32;

  int _length = 0;
  Uint8List _buffer = new Uint8List(kInitialCapacity);

  final ExceptionsTable exceptionsTable = new ExceptionsTable();
  final LocalVariableTable localVariableTable = new LocalVariableTable();
  final SourcePositions sourcePositions = new SourcePositions();
  final bool _emitSourcePositions;
  bool isUnreachable = false;
  int currentSourcePosition = TreeNode.noOffset;

  BytecodeAssembler(BytecodeOptions options)
      : _emitSourcePositions = options.emitSourcePositions;

  int get offset => _length;

  Uint8List get bytecode => new Uint8List.view(_buffer.buffer, 0, _length);

  void bind(Label label) {
    final List<int> jumps = label.bind(offset);
    for (int jumpOffset in jumps) {
      _patchJump(jumpOffset, label.jumpOperand(jumpOffset));
    }
    if (jumps.isNotEmpty || label.allowsBackwardJumps) {
      isUnreachable = false;
    }
  }

  @pragma('vm:prefer-inline')
  void emitSourcePosition() {
    if (_emitSourcePositions &&
        !isUnreachable &&
        currentSourcePosition != TreeNode.noOffset) {
      sourcePositions.add(offset, currentSourcePosition);
    }
  }

  // TreeNode.noOffset (-1) source position on calls is used to mark synthetic
  // calls without corresponding source position. Debugger uses the absence of
  // source position to distinguish these calls and avoid stopping at them
  // while single stepping.
  @pragma('vm:prefer-inline')
  void emitSourcePositionForCall() {
    if (_emitSourcePositions && !isUnreachable) {
      sourcePositions.add(
          offset,
          currentSourcePosition == TreeNode.noOffset
              ? SourcePositions.syntheticCodeMarker
              : currentSourcePosition);
    }
  }

  void emitYieldPointSourcePosition(int yieldSourcePosition) {
    if (!isUnreachable) {
      sourcePositions.addYieldPoint(offset, yieldSourcePosition);
    }
  }

  void _grow() {
    final newSize = _buffer.length << 1;
    final newBuffer = new Uint8List(newSize);
    newBuffer.setRange(0, _buffer.length, _buffer);
    _buffer = newBuffer;
  }

  void _growAndEmitBytes(int b0, [int b1, int b2, int b3, int b4, int b5]) {
    _grow();
    assert(_length + 6 < _buffer.length);
    _buffer[_length] = b0;
    ++_length;
    if (b1 != null) {
      _buffer[_length] = b1;
      ++_length;
      if (b2 != null) {
        _buffer[_length] = b2;
        ++_length;
        if (b3 != null) {
          _buffer[_length] = b3;
          ++_length;
          if (b4 != null) {
            _buffer[_length] = b4;
            ++_length;
            if (b5 != null) {
              _buffer[_length] = b5;
              ++_length;
            }
          }
        }
      }
    }
  }

  @pragma('vm:prefer-inline')
  void _emitByte(int abyte) {
    assert(_isUint8(abyte));
    if (_length < _buffer.length) {
      _buffer[_length] = abyte;
      ++_length;
    } else {
      _growAndEmitBytes(abyte);
    }
  }

  @pragma('vm:prefer-inline')
  void _emitBytes2(int b0, int b1) {
    assert(_isUint8(b0) && _isUint8(b1));
    if (_length + 1 < _buffer.length) {
      _buffer[_length] = b0;
      _buffer[_length + 1] = b1;
      _length += 2;
    } else {
      _growAndEmitBytes(b0, b1);
    }
  }

  @pragma('vm:prefer-inline')
  void _emitBytes3(int b0, int b1, int b2) {
    assert(_isUint8(b0) && _isUint8(b1) && _isUint8(b2));
    if (_length + 2 < _buffer.length) {
      _buffer[_length] = b0;
      _buffer[_length + 1] = b1;
      _buffer[_length + 2] = b2;
      _length += 3;
    } else {
      _growAndEmitBytes(b0, b1, b2);
    }
  }

  @pragma('vm:prefer-inline')
  void _emitBytes4(int b0, int b1, int b2, int b3) {
    assert(_isUint8(b0) && _isUint8(b1) && _isUint8(b2) && _isUint8(b3));
    if (_length + 3 < _buffer.length) {
      _buffer[_length] = b0;
      _buffer[_length + 1] = b1;
      _buffer[_length + 2] = b2;
      _buffer[_length + 3] = b3;
      _length += 4;
    } else {
      _growAndEmitBytes(b0, b1, b2, b3);
    }
  }

  void _emitBytes5(int b0, int b1, int b2, int b3, int b4) {
    assert(_isUint8(b0) &&
        _isUint8(b1) &&
        _isUint8(b2) &&
        _isUint8(b3) &&
        _isUint8(b4));
    if (_length + 4 < _buffer.length) {
      _buffer[_length] = b0;
      _buffer[_length + 1] = b1;
      _buffer[_length + 2] = b2;
      _buffer[_length + 3] = b3;
      _buffer[_length + 4] = b4;
      _length += 5;
    } else {
      _growAndEmitBytes(b0, b1, b2, b3, b4);
    }
  }

  void _emitBytes6(int b0, int b1, int b2, int b3, int b4, int b5) {
    assert(_isUint8(b0) &&
        _isUint8(b1) &&
        _isUint8(b2) &&
        _isUint8(b3) &&
        _isUint8(b4) &&
        _isUint8(b5));
    if (_length + 5 < _buffer.length) {
      _buffer[_length] = b0;
      _buffer[_length + 1] = b1;
      _buffer[_length + 2] = b2;
      _buffer[_length + 3] = b3;
      _buffer[_length + 4] = b4;
      _buffer[_length + 5] = b5;
      _length += 6;
    } else {
      _growAndEmitBytes(b0, b1, b2, b3, b4, b5);
    }
  }

  int _byteAt(int pos) {
    return _buffer[pos];
  }

  void _setByteAt(int pos, int value) {
    assert(_isUint8(value));
    _buffer[pos] = value;
  }

  @pragma('vm:prefer-inline')
  int _byte0(int v) => v & kByteMask;

  @pragma('vm:prefer-inline')
  int _byte1(int v) => (v >> 8) & kByteMask;

  @pragma('vm:prefer-inline')
  int _byte2(int v) => (v >> 16) & kByteMask;

  @pragma('vm:prefer-inline')
  int _byte3(int v) => (v >> 24) & kByteMask;

  @pragma('vm:prefer-inline')
  bool _isInt8(int v) => (kMinInt8 <= v) && (v <= kMaxInt8);

  @pragma('vm:prefer-inline')
  bool _isInt24(int v) => (kMinInt24 <= v) && (v <= kMaxInt24);

  @pragma('vm:prefer-inline')
  bool _isInt32(int v) => (kMinInt32 <= v) && (v <= kMaxInt32);

  @pragma('vm:prefer-inline')
  bool _isUint8(int v) => (v & kByteMask) == v;

  @pragma('vm:prefer-inline')
  bool _isUint32(int v) => (v & kUint32Mask) == v;

  @pragma('vm:prefer-inline')
  void _emitInstruction0(Opcode opcode) {
    if (isUnreachable) {
      return;
    }
    _emitByte(opcode.index);
  }

  @pragma('vm:prefer-inline')
  void _emitInstructionA(Opcode opcode, int ra) {
    if (isUnreachable) {
      return;
    }
    _emitBytes2(opcode.index, ra);
  }

  @pragma('vm:prefer-inline')
  void _emitInstructionD(Opcode opcode, int rd) {
    if (isUnreachable) {
      return;
    }
    if (_isUint8(rd)) {
      _emitBytes2(opcode.index, rd);
    } else {
      assert(_isUint32(rd));
      _emitBytes5(opcode.index + kWideModifier, _byte0(rd), _byte1(rd),
          _byte2(rd), _byte3(rd));
    }
  }

  @pragma('vm:prefer-inline')
  void _emitInstructionX(Opcode opcode, int rx) {
    if (isUnreachable) {
      return;
    }
    if (_isInt8(rx)) {
      _emitBytes2(opcode.index, rx & kByteMask);
    } else {
      assert(_isInt32(rx));
      _emitBytes5(opcode.index + kWideModifier, _byte0(rx), _byte1(rx),
          _byte2(rx), _byte3(rx));
    }
  }

  @pragma('vm:prefer-inline')
  void _emitInstructionAE(Opcode opcode, int ra, int re) {
    if (isUnreachable) {
      return;
    }
    if (_isUint8(re)) {
      _emitBytes3(opcode.index, ra, re);
    } else {
      assert(_isUint32(re));
      _emitBytes6(opcode.index + kWideModifier, ra, _byte0(re), _byte1(re),
          _byte2(re), _byte3(re));
    }
  }

  @pragma('vm:prefer-inline')
  void _emitInstructionAY(Opcode opcode, int ra, int ry) {
    if (isUnreachable) {
      return;
    }
    if (_isInt8(ry)) {
      _emitBytes3(opcode.index, ra, ry & kByteMask);
    } else {
      assert(_isInt32(ry));
      _emitBytes6(opcode.index + kWideModifier, ra, _byte0(ry), _byte1(ry),
          _byte2(ry), _byte3(ry));
    }
  }

  @pragma('vm:prefer-inline')
  void _emitInstructionDF(Opcode opcode, int rd, int rf) {
    if (isUnreachable) {
      return;
    }
    if (_isUint8(rd)) {
      _emitBytes3(opcode.index, rd, rf);
    } else {
      assert(_isUint32(rd));
      _emitBytes6(opcode.index + kWideModifier, _byte0(rd), _byte1(rd),
          _byte2(rd), _byte3(rd), rf);
    }
  }

  @pragma('vm:prefer-inline')
  void _emitInstructionABC(Opcode opcode, int ra, int rb, int rc) {
    if (isUnreachable) {
      return;
    }
    _emitBytes4(opcode.index, ra, rb, rc);
  }

  @pragma('vm:prefer-inline')
  void emitSpecializedBytecode(Opcode opcode) {
    assert(BytecodeFormats[opcode].encoding == Encoding.k0);
    emitSourcePosition();
    _emitInstruction0(opcode);
  }

  @pragma('vm:prefer-inline')
  void _emitJumpInstruction(Opcode opcode, Label label) {
    assert(isJump(opcode));
    if (isUnreachable) {
      return;
    }
    final int target = label.jumpOperand(offset);
    // Use compact representation only for backwards jumps.
    // TODO(alexmarkov): generate compact forward jumps as well.
    if (label.isBound && _isInt8(target)) {
      _emitBytes2(opcode.index, target & kByteMask);
    } else {
      assert(_isInt24(target));
      _emitBytes4(opcode.index + kWideModifier, _byte0(target), _byte1(target),
          _byte2(target));
    }
  }

  void _patchJump(int pos, int rt) {
    final Opcode opcode = Opcode.values[_byteAt(pos) - kWideModifier];
    assert(hasWideVariant(opcode));
    assert(isJump(opcode));
    assert(_isInt24(rt));
    _setByteAt(pos + 1, _byte0(rt));
    _setByteAt(pos + 2, _byte1(rt));
    _setByteAt(pos + 3, _byte2(rt));
  }

  void emitTrap() {
    _emitInstruction0(Opcode.kTrap);
    isUnreachable = true;
  }

  @pragma('vm:prefer-inline')
  void emitDrop1() {
    _emitInstruction0(Opcode.kDrop1);
  }

  @pragma('vm:prefer-inline')
  void emitJump(Label label) {
    _emitJumpInstruction(Opcode.kJump, label);
    isUnreachable = true;
  }

  @pragma('vm:prefer-inline')
  void emitJumpIfNoAsserts(Label label) {
    _emitJumpInstruction(Opcode.kJumpIfNoAsserts, label);
  }

  @pragma('vm:prefer-inline')
  void emitJumpIfNotZeroTypeArgs(Label label) {
    _emitJumpInstruction(Opcode.kJumpIfNotZeroTypeArgs, label);
  }

  @pragma('vm:prefer-inline')
  void emitJumpIfEqStrict(Label label) {
    _emitJumpInstruction(Opcode.kJumpIfEqStrict, label);
  }

  @pragma('vm:prefer-inline')
  void emitJumpIfNeStrict(Label label) {
    _emitJumpInstruction(Opcode.kJumpIfNeStrict, label);
  }

  @pragma('vm:prefer-inline')
  void emitJumpIfTrue(Label label) {
    _emitJumpInstruction(Opcode.kJumpIfTrue, label);
  }

  @pragma('vm:prefer-inline')
  void emitJumpIfFalse(Label label) {
    _emitJumpInstruction(Opcode.kJumpIfFalse, label);
  }

  @pragma('vm:prefer-inline')
  void emitJumpIfNull(Label label) {
    _emitJumpInstruction(Opcode.kJumpIfNull, label);
  }

  @pragma('vm:prefer-inline')
  void emitJumpIfNotNull(Label label) {
    _emitJumpInstruction(Opcode.kJumpIfNotNull, label);
  }

  @pragma('vm:prefer-inline')
  void emitJumpIfUnchecked(Label label) {
    _emitJumpInstruction(Opcode.kJumpIfUnchecked, label);
  }

  @pragma('vm:prefer-inline')
  void emitReturnTOS() {
    emitSourcePosition();
    _emitInstruction0(Opcode.kReturnTOS);
    isUnreachable = true;
  }

  @pragma('vm:prefer-inline')
  void emitPush(int rx) {
    _emitInstructionX(Opcode.kPush, rx);
  }

  @pragma('vm:prefer-inline')
  void emitLoadConstant(int ra, int re) {
    _emitInstructionAE(Opcode.kLoadConstant, ra, re);
  }

  @pragma('vm:prefer-inline')
  void emitPushConstant(int rd) {
    _emitInstructionD(Opcode.kPushConstant, rd);
  }

  @pragma('vm:prefer-inline')
  void emitPushNull() {
    _emitInstruction0(Opcode.kPushNull);
  }

  @pragma('vm:prefer-inline')
  void emitPushTrue() {
    _emitInstruction0(Opcode.kPushTrue);
  }

  @pragma('vm:prefer-inline')
  void emitPushFalse() {
    _emitInstruction0(Opcode.kPushFalse);
  }

  @pragma('vm:prefer-inline')
  void emitPushInt(int rx) {
    _emitInstructionX(Opcode.kPushInt, rx);
  }

  @pragma('vm:prefer-inline')
  void emitStoreLocal(int rx) {
    _emitInstructionX(Opcode.kStoreLocal, rx);
  }

  @pragma('vm:prefer-inline')
  void emitPopLocal(int rx) {
    _emitInstructionX(Opcode.kPopLocal, rx);
  }

  @pragma('vm:prefer-inline')
  void emitDirectCall(int rd, int rf) {
    emitSourcePositionForCall();
    _emitInstructionDF(Opcode.kDirectCall, rd, rf);
  }

  @pragma('vm:prefer-inline')
  void emitUncheckedDirectCall(int rd, int rf) {
    emitSourcePositionForCall();
    _emitInstructionDF(Opcode.kUncheckedDirectCall, rd, rf);
  }

  @pragma('vm:prefer-inline')
  void emitInterfaceCall(int rd, int rf) {
    emitSourcePositionForCall();
    _emitInstructionDF(Opcode.kInterfaceCall, rd, rf);
  }

  @pragma('vm:prefer-inline')
  void emitInstantiatedInterfaceCall(int rd, int rf) {
    emitSourcePositionForCall();
    _emitInstructionDF(Opcode.kInstantiatedInterfaceCall, rd, rf);
  }

  @pragma('vm:prefer-inline')
  void emitUncheckedClosureCall(int rd, int rf) {
    emitSourcePositionForCall();
    _emitInstructionDF(Opcode.kUncheckedClosureCall, rd, rf);
  }

  @pragma('vm:prefer-inline')
  void emitUncheckedInterfaceCall(int rd, int rf) {
    emitSourcePositionForCall();
    _emitInstructionDF(Opcode.kUncheckedInterfaceCall, rd, rf);
  }

  @pragma('vm:prefer-inline')
  void emitDynamicCall(int rd, int rf) {
    emitSourcePositionForCall();
    _emitInstructionDF(Opcode.kDynamicCall, rd, rf);
  }

  @pragma('vm:prefer-inline')
  void emitNativeCall(int rd) {
    _emitInstructionD(Opcode.kNativeCall, rd);
  }

  @pragma('vm:prefer-inline')
  void emitLoadStatic(int rd) {
    _emitInstructionD(Opcode.kLoadStatic, rd);
  }

  @pragma('vm:prefer-inline')
  void emitStoreStaticTOS(int rd) {
    emitSourcePosition();
    _emitInstructionD(Opcode.kStoreStaticTOS, rd);
  }

  @pragma('vm:prefer-inline')
  void emitCreateArrayTOS() {
    _emitInstruction0(Opcode.kCreateArrayTOS);
  }

  @pragma('vm:prefer-inline')
  void emitAllocate(int rd) {
    emitSourcePosition();
    _emitInstructionD(Opcode.kAllocate, rd);
  }

  @pragma('vm:prefer-inline')
  void emitAllocateT() {
    emitSourcePosition();
    _emitInstruction0(Opcode.kAllocateT);
  }

  @pragma('vm:prefer-inline')
  void emitStoreIndexedTOS() {
    _emitInstruction0(Opcode.kStoreIndexedTOS);
  }

  @pragma('vm:prefer-inline')
  void emitStoreFieldTOS(int rd) {
    emitSourcePosition();
    _emitInstructionD(Opcode.kStoreFieldTOS, rd);
  }

  @pragma('vm:prefer-inline')
  void emitStoreContextParent() {
    _emitInstruction0(Opcode.kStoreContextParent);
  }

  @pragma('vm:prefer-inline')
  void emitStoreContextVar(int ra, int re) {
    _emitInstructionAE(Opcode.kStoreContextVar, ra, re);
  }

  @pragma('vm:prefer-inline')
  void emitLoadFieldTOS(int rd) {
    _emitInstructionD(Opcode.kLoadFieldTOS, rd);
  }

  @pragma('vm:prefer-inline')
  void emitLoadTypeArgumentsField(int rd) {
    _emitInstructionD(Opcode.kLoadTypeArgumentsField, rd);
  }

  @pragma('vm:prefer-inline')
  void emitLoadContextParent() {
    _emitInstruction0(Opcode.kLoadContextParent);
  }

  @pragma('vm:prefer-inline')
  void emitLoadContextVar(int ra, int re) {
    _emitInstructionAE(Opcode.kLoadContextVar, ra, re);
  }

  @pragma('vm:prefer-inline')
  void emitBooleanNegateTOS() {
    _emitInstruction0(Opcode.kBooleanNegateTOS);
  }

  @pragma('vm:prefer-inline')
  void emitThrow(int ra) {
    emitSourcePosition();
    _emitInstructionA(Opcode.kThrow, ra);
    isUnreachable = true;
  }

  @pragma('vm:prefer-inline')
  void emitEntry(int rd) {
    _emitInstructionD(Opcode.kEntry, rd);
  }

  @pragma('vm:prefer-inline')
  void emitFrame(int rd) {
    _emitInstructionD(Opcode.kFrame, rd);
  }

  @pragma('vm:prefer-inline')
  void emitSetFrame(int ra) {
    _emitInstructionA(Opcode.kSetFrame, ra);
  }

  @pragma('vm:prefer-inline')
  void emitAllocateContext(int ra, int re) {
    _emitInstructionAE(Opcode.kAllocateContext, ra, re);
  }

  @pragma('vm:prefer-inline')
  void emitCloneContext(int ra, int re) {
    _emitInstructionAE(Opcode.kCloneContext, ra, re);
  }

  @pragma('vm:prefer-inline')
  void emitMoveSpecial(SpecialIndex ra, int ry) {
    _emitInstructionAY(Opcode.kMoveSpecial, ra.index, ry);
  }

  @pragma('vm:prefer-inline')
  void emitInstantiateType(int rd) {
    emitSourcePosition();
    _emitInstructionD(Opcode.kInstantiateType, rd);
  }

  @pragma('vm:prefer-inline')
  void emitInstantiateTypeArgumentsTOS(int ra, int re) {
    emitSourcePosition();
    _emitInstructionAE(Opcode.kInstantiateTypeArgumentsTOS, ra, re);
  }

  @pragma('vm:prefer-inline')
  void emitAssertAssignable(int ra, int re) {
    emitSourcePosition();
    _emitInstructionAE(Opcode.kAssertAssignable, ra, re);
  }

  @pragma('vm:prefer-inline')
  void emitAssertSubtype() {
    emitSourcePosition();
    _emitInstruction0(Opcode.kAssertSubtype);
  }

  @pragma('vm:prefer-inline')
  void emitAssertBoolean(int ra) {
    emitSourcePosition();
    _emitInstructionA(Opcode.kAssertBoolean, ra);
  }

  @pragma('vm:prefer-inline')
  void emitCheckStack(int ra) {
    emitSourcePosition();
    _emitInstructionA(Opcode.kCheckStack, ra);
  }

  @pragma('vm:prefer-inline')
  void emitDebugCheck() {
    emitSourcePosition();
    _emitInstruction0(Opcode.kDebugCheck);
  }

  @pragma('vm:prefer-inline')
  void emitCheckFunctionTypeArgs(int ra, int re) {
    emitSourcePosition();
    _emitInstructionAE(Opcode.kCheckFunctionTypeArgs, ra, re);
  }

  @pragma('vm:prefer-inline')
  void emitEntryFixed(int ra, int re) {
    _emitInstructionAE(Opcode.kEntryFixed, ra, re);
  }

  @pragma('vm:prefer-inline')
  void emitEntryOptional(int ra, int rb, int rc) {
    _emitInstructionABC(Opcode.kEntryOptional, ra, rb, rc);
  }

  @pragma('vm:prefer-inline')
  void emitAllocateClosure(int rd) {
    emitSourcePosition();
    _emitInstructionD(Opcode.kAllocateClosure, rd);
  }

  @pragma('vm:prefer-inline')
  void emitNullCheck(int rd) {
    emitSourcePosition();
    _emitInstructionD(Opcode.kNullCheck, rd);
  }

  @pragma('vm:prefer-inline')
  void emitInitLateField(int rd) {
    emitSourcePosition();
    _emitInstructionD(Opcode.kInitLateField, rd);
  }

  @pragma('vm:prefer-inline')
  void emitPushUninitializedSentinel() {
    _emitInstruction0(Opcode.kPushUninitializedSentinel);
  }

  @pragma('vm:prefer-inline')
  void emitJumpIfInitialized(Label label) {
    _emitJumpInstruction(Opcode.kJumpIfInitialized, label);
  }
}
