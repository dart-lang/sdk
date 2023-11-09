// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/tool/wolf/generate.dart' and run
// 'dart run pkg/analyzer/tool/wolf/generate.dart' to update.

part of 'ir.dart';

mixin _RawIRWriterMixin implements _RawIRWriterMixinInterface {
  void drop() {
    _opcodes.add(Opcode.drop);
    _params0.add(0);
    _params1.add(0);
  }

  void end() {
    _opcodes.add(Opcode.end);
    _params0.add(0);
    _params1.add(0);
  }

  void function(TypeRef type, FunctionFlags flags) {
    _opcodes.add(Opcode.function);
    _params0.add(type.index);
    _params1.add(flags._flags);
  }

  void literal(LiteralRef value) {
    _opcodes.add(Opcode.literal);
    _params0.add(value.index);
    _params1.add(0);
  }
}

mixin IRToStringMixin implements RawIRContainerInterface {
  String instructionToString(int address) {
    switch (opcodeAt(address)) {
      case Opcode.literal:
        return 'literal(${literalRefToString(Opcode.literal.decodeValue(this, address))})';

      case Opcode.drop:
        return 'drop';

      case Opcode.function:
        return 'function(${typeRefToString(Opcode.function.decodeType(this, address))}, ${functionFlagsToString(Opcode.function.decodeFlags(this, address))})';

      case Opcode.end:
        return 'end';
      default:
        return '???';
    }
  }
}

class _ParameterShape0 extends Opcode {
  const _ParameterShape0._(super.index) : super._();

  LiteralRef decodeValue(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return LiteralRef(ir._params0[address]);
  }
}

class _ParameterShape1 extends Opcode {
  const _ParameterShape1._(super.index) : super._();
}

class _ParameterShape2 extends Opcode {
  const _ParameterShape2._(super.index) : super._();

  TypeRef decodeType(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return TypeRef(ir._params0[address]);
  }

  FunctionFlags decodeFlags(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return FunctionFlags._(ir._params1[address]);
  }
}

/// TODO(paulberry): when extension types are supported, make this an extension
/// type, as well as all the `_ParameterShape` classes.
class Opcode {
  final int index;

  const Opcode._(this.index);

  static const literal = _ParameterShape0._(0);
  static const drop = _ParameterShape1._(1);
  static const function = _ParameterShape2._(2);
  static const end = _ParameterShape1._(3);

  String describe() => opcodeNameTable[index];

  static const opcodeNameTable = [
    "literal",
    "drop",
    "function",
    "end",
  ];
}
