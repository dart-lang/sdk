// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/tool/wolf/generate.dart' and run
// 'dart run pkg/analyzer/tool/wolf/generate.dart' to update.

part of 'ir.dart';

mixin _RawIRWriterMixin implements _RawIRWriterMixinInterface {
  void alloc(int count) {
    _opcodes.add(Opcode.alloc);
    _params0.add(count);
    _params1.add(0);
  }

  void await_() {
    _opcodes.add(Opcode.await_);
    _params0.add(0);
    _params1.add(0);
  }

  void block(int inputCount, int outputCount) {
    _opcodes.add(Opcode.block);
    _params0.add(inputCount);
    _params1.add(outputCount);
  }

  void br(int nesting) {
    _opcodes.add(Opcode.br);
    _params0.add(nesting);
    _params1.add(0);
  }

  void brIf(int nesting) {
    _opcodes.add(Opcode.brIf);
    _params0.add(nesting);
    _params1.add(0);
  }

  void call(CallDescriptorRef callDescriptor, ArgumentNamesRef argumentNames) {
    _opcodes.add(Opcode.call);
    _params0.add(callDescriptor.index);
    _params1.add(argumentNames.index);
  }

  void concat(int count) {
    _opcodes.add(Opcode.concat);
    _params0.add(count);
    _params1.add(0);
  }

  void drop() {
    _opcodes.add(Opcode.drop);
    _params0.add(0);
    _params1.add(0);
  }

  void dup() {
    _opcodes.add(Opcode.dup);
    _params0.add(0);
    _params1.add(0);
  }

  void end() {
    _opcodes.add(Opcode.end);
    _params0.add(0);
    _params1.add(0);
  }

  void eq() {
    _opcodes.add(Opcode.eq);
    _params0.add(0);
    _params1.add(0);
  }

  void function(TypeRef type, FunctionFlags flags) {
    _opcodes.add(Opcode.function);
    _params0.add(type.index);
    _params1.add(flags._flags);
  }

  void identical() {
    _opcodes.add(Opcode.identical);
    _params0.add(0);
    _params1.add(0);
  }

  void is_(TypeRef type) {
    _opcodes.add(Opcode.is_);
    _params0.add(type.index);
    _params1.add(0);
  }

  void literal(LiteralRef value) {
    _opcodes.add(Opcode.literal);
    _params0.add(value.index);
    _params1.add(0);
  }

  void loop(int inputCount) {
    _opcodes.add(Opcode.loop);
    _params0.add(inputCount);
    _params1.add(0);
  }

  void not() {
    _opcodes.add(Opcode.not);
    _params0.add(0);
    _params1.add(0);
  }

  void readLocal(int localIndex) {
    _opcodes.add(Opcode.readLocal);
    _params0.add(localIndex);
    _params1.add(0);
  }

  void release(int count) {
    _opcodes.add(Opcode.release);
    _params0.add(count);
    _params1.add(0);
  }

  void shuffle(int popCount, StackIndicesRef stackIndices) {
    _opcodes.add(Opcode.shuffle);
    _params0.add(popCount);
    _params1.add(stackIndices.index);
  }

  void writeLocal(int localIndex) {
    _opcodes.add(Opcode.writeLocal);
    _params0.add(localIndex);
    _params1.add(0);
  }

  void yield_() {
    _opcodes.add(Opcode.yield_);
    _params0.add(0);
    _params1.add(0);
  }
}

mixin IRToStringMixin implements RawIRContainerInterface {
  String instructionToString(int address) {
    switch (opcodeAt(address)) {
      case Opcode.alloc:
        return 'alloc(${Opcode.alloc.decodeCount(this, address)})';

      case Opcode.release:
        return 'release(${Opcode.release.decodeCount(this, address)})';

      case Opcode.readLocal:
        return 'readLocal(${Opcode.readLocal.decodeLocalIndex(this, address)})';

      case Opcode.writeLocal:
        return 'writeLocal(${Opcode.writeLocal.decodeLocalIndex(this, address)})';

      case Opcode.literal:
        return 'literal(${literalRefToString(Opcode.literal.decodeValue(this, address))})';

      case Opcode.identical:
        return 'identical';

      case Opcode.eq:
        return 'eq';

      case Opcode.not:
        return 'not';

      case Opcode.concat:
        return 'concat(${Opcode.concat.decodeCount(this, address)})';

      case Opcode.is_:
        return 'is(${typeRefToString(Opcode.is_.decodeType(this, address))})';

      case Opcode.drop:
        return 'drop';

      case Opcode.dup:
        return 'dup';

      case Opcode.shuffle:
        return 'shuffle(${Opcode.shuffle.decodePopCount(this, address)}, ${stackIndicesRefToString(Opcode.shuffle.decodeStackIndices(this, address))})';

      case Opcode.block:
        return 'block(${Opcode.block.decodeInputCount(this, address)}, ${Opcode.block.decodeOutputCount(this, address)})';

      case Opcode.loop:
        return 'loop(${Opcode.loop.decodeInputCount(this, address)})';

      case Opcode.function:
        return 'function(${typeRefToString(Opcode.function.decodeType(this, address))}, ${functionFlagsToString(Opcode.function.decodeFlags(this, address))})';

      case Opcode.end:
        return 'end';

      case Opcode.br:
        return 'br(${Opcode.br.decodeNesting(this, address)})';

      case Opcode.brIf:
        return 'brIf(${Opcode.brIf.decodeNesting(this, address)})';

      case Opcode.await_:
        return 'await';

      case Opcode.yield_:
        return 'yield';

      case Opcode.call:
        return 'call(${callDescriptorRefToString(Opcode.call.decodeCallDescriptor(this, address))}, ${argumentNamesRefToString(Opcode.call.decodeArgumentNames(this, address))})';
      default:
        return '???';
    }
  }
}

class _ParameterShape0 extends Opcode {
  const _ParameterShape0._(super.index) : super._();

  int decodeCount(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return ir._params0[address];
  }
}

class _ParameterShape1 extends Opcode {
  const _ParameterShape1._(super.index) : super._();

  int decodeLocalIndex(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return ir._params0[address];
  }
}

class _ParameterShape2 extends Opcode {
  const _ParameterShape2._(super.index) : super._();

  LiteralRef decodeValue(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return LiteralRef(ir._params0[address]);
  }
}

class _ParameterShape3 extends Opcode {
  const _ParameterShape3._(super.index) : super._();
}

class _ParameterShape4 extends Opcode {
  const _ParameterShape4._(super.index) : super._();

  TypeRef decodeType(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return TypeRef(ir._params0[address]);
  }
}

class _ParameterShape5 extends Opcode {
  const _ParameterShape5._(super.index) : super._();

  int decodePopCount(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return ir._params0[address];
  }

  StackIndicesRef decodeStackIndices(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return StackIndicesRef(ir._params1[address]);
  }
}

class _ParameterShape6 extends Opcode {
  const _ParameterShape6._(super.index) : super._();

  int decodeInputCount(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return ir._params0[address];
  }

  int decodeOutputCount(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return ir._params1[address];
  }
}

class _ParameterShape7 extends Opcode {
  const _ParameterShape7._(super.index) : super._();

  int decodeInputCount(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return ir._params0[address];
  }
}

class _ParameterShape8 extends Opcode {
  const _ParameterShape8._(super.index) : super._();

  TypeRef decodeType(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return TypeRef(ir._params0[address]);
  }

  FunctionFlags decodeFlags(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return FunctionFlags._(ir._params1[address]);
  }
}

class _ParameterShape9 extends Opcode {
  const _ParameterShape9._(super.index) : super._();

  int decodeNesting(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return ir._params0[address];
  }
}

class _ParameterShape10 extends Opcode {
  const _ParameterShape10._(super.index) : super._();

  CallDescriptorRef decodeCallDescriptor(
      RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return CallDescriptorRef(ir._params0[address]);
  }

  ArgumentNamesRef decodeArgumentNames(
      RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return ArgumentNamesRef(ir._params1[address]);
  }
}

// TODO(paulberry): when extension types are supported, make this an extension
// type, as well as all the `_ParameterShape` classes.
class Opcode {
  final int index;

  const Opcode._(this.index);

  static const alloc = _ParameterShape0._(0);
  static const release = _ParameterShape0._(1);
  static const readLocal = _ParameterShape1._(2);
  static const writeLocal = _ParameterShape1._(3);
  static const literal = _ParameterShape2._(4);
  static const identical = _ParameterShape3._(5);
  static const eq = _ParameterShape3._(6);
  static const not = _ParameterShape3._(7);
  static const concat = _ParameterShape0._(8);
  static const is_ = _ParameterShape4._(9);
  static const drop = _ParameterShape3._(10);
  static const dup = _ParameterShape3._(11);
  static const shuffle = _ParameterShape5._(12);
  static const block = _ParameterShape6._(13);
  static const loop = _ParameterShape7._(14);
  static const function = _ParameterShape8._(15);
  static const end = _ParameterShape3._(16);
  static const br = _ParameterShape9._(17);
  static const brIf = _ParameterShape9._(18);
  static const await_ = _ParameterShape3._(19);
  static const yield_ = _ParameterShape3._(20);
  static const call = _ParameterShape10._(21);

  String describe() => opcodeNameTable[index];

  static const opcodeNameTable = [
    "alloc",
    "release",
    "readLocal",
    "writeLocal",
    "literal",
    "identical",
    "eq",
    "not",
    "concat",
    "is",
    "drop",
    "dup",
    "shuffle",
    "block",
    "loop",
    "function",
    "end",
    "br",
    "brIf",
    "await",
    "yield",
    "call",
  ];
}
