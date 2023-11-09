// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library contains data structures that define an intermediate
/// representation for Dart expressions and statements.
///
/// The intermediate representation models a stack-based machine in which stack
/// entries are Dart values. It aims to be fairly minimal, so that it can be
/// used as the basis for implementing lint rules and other static analyses,
/// without requiring the implementer to handle every possible Dart construct.
library;

part 'ir.g.dart';

/// Container for a sequence of IR instructions, which represents the body of a
/// single function, method, getter, setter, constructor, or initializer
/// expression.
///
/// The data is organized into lists of integers rather than a deeply nested
/// AST structure, in order to allow for random access and reduce the number of
/// cache lines that need to be loaded in order to perform analysis.
///
/// Other data structures that need to be referenced by the IR (e.g. types) are
/// stored in auxiliary tables, which are provided by subclasses.
///
/// To construct a sequence of IR instructions, see [RawIRWriter].
abstract class BaseIRContainer with IRToStringMixin {
  /// The opcode of each encoded instruction.
  final List<Opcode> _opcodes;
  @override
  final List<int> _params0;
  @override
  final List<int> _params1;

  BaseIRContainer(RawIRWriter writer)
      : _opcodes = writer._opcodes,
        _params0 = writer._params0,
        _params1 = writer._params1;

  int get endAddress => _opcodes.length;

  /// Given a [TypeRef] that represents a function type, returns the number of
  /// function parameters.
  int countParameters(TypeRef type);

  @override
  String functionFlagsToString(FunctionFlags flags) => flags.describe();

  @override
  String literalRefToString(LiteralRef literal) => 'literal#${literal.index}';

  @override
  Opcode opcodeAt(int address) => _opcodes[address];

  @override
  String typeRefToString(TypeRef type) => 'typeRef#${type.index}';
}

/// Flags describing properties of a function declaration that affect the
/// interpretation of its body.
///
/// TODO(paulberry): when extension types are supported, make this an extension
/// type.
class FunctionFlags {
  static const _asyncBit = 0;
  static const _generatorBit = 1;
  static const _instanceBit = 2;

  final int _flags;

  const FunctionFlags(
      {bool async = false, bool generator = false, bool instance = false})
      : _flags = (async ? (1 << _asyncBit) : 0) |
            (generator ? (1 << _generatorBit) : 0) |
            (instance ? (1 << _instanceBit) : 0);

  const FunctionFlags._(this._flags);

  @override
  int get hashCode => _flags.hashCode;

  /// True if the function was declared with `async` or `async*`.
  bool get isAsync => _flags & (1 << _asyncBit) != 0;

  /// True if the function was declared with `sync*` or `async*`.
  bool get isGenerator => _flags & (1 << _generatorBit) != 0;

  /// True if the function contains an implicit `this` parameter.
  bool get isInstance => _flags & (1 << _instanceBit) != 0;

  @override
  bool operator ==(other) => other is FunctionFlags && _flags == other._flags;

  String describe() {
    var parts = [
      if (isAsync) 'async',
      if (isGenerator) 'generator',
      if (isInstance) 'instance'
    ];
    return parts.isEmpty ? '0' : parts.join('|');
  }

  @override
  String toString() => _flags.toString();
}

/// Wrapper for an integer representing a simple Dart literal (Null, bool, int,
/// double, String, or Symbol).
///
/// The actual value of the literal isn't stored directly in the instruction
/// stream. This integer is an index into an auxiliary table stored in a subtype
/// of [BaseIRContainer].
///
/// TODO(paulberry): when extension types are supported, make this an extension
/// type.
class LiteralRef {
  final int index;

  LiteralRef(this.index);

  @override
  int get hashCode => index.hashCode;

  @override
  bool operator ==(other) => other is LiteralRef && index == other.index;

  @override
  String toString() => index.toString();
}

/// Interface used by generated code to read and decode instructions from
/// [BaseIRContainer].
abstract class RawIRContainerInterface {
  /// The first parameter of each encoded instruction.
  List<int> get _params0;

  /// The second parameter of each encoded instruction.
  List<int> get _params1;

  String functionFlagsToString(FunctionFlags flags);

  String literalRefToString(LiteralRef literal);

  Opcode opcodeAt(int address);

  String typeRefToString(TypeRef type);
}

/// Writer of an IR instruction stream.
///
/// This class contains methods to add each kind of instruction to the stream
/// (in [_RawIRWriterMixin]). To create an instruction stream, create an
/// instance of this class, call methods in [_RawIRWriterMixin] to add the
/// instructions, and then pass this object to [BaseIRContainer].
///
/// Subclasses provide the ability to create reference to other data structures
/// (e.g. types), which are stored in auxiliary tables.
class RawIRWriter with _RawIRWriterMixin {
  @override
  final _opcodes = <Opcode>[];
  @override
  final _params0 = <int>[];
  @override
  final _params1 = <int>[];

  int get nextInstructionAddress => _opcodes.length;
}

/// Wrapper for an integer representing a Dart type.
///
/// The actual type isn't stored directly in the instruction stream. This
/// integer is an index into an auxiliary table stored in a subtype of
/// [BaseIRContainer].
///
/// TODO(paulberry): when extension types are supported, make this an extension
/// type.
class TypeRef {
  final int index;

  TypeRef(this.index);

  @override
  int get hashCode => index.hashCode;

  @override
  bool operator ==(other) => other is TypeRef && index == other.index;

  @override
  String toString() => index.toString();
}

/// Interface used by generated code to write instructions into [RawIRWriter].
abstract class _RawIRWriterMixinInterface {
  List<Opcode> get _opcodes;
  List<int> get _params0;
  List<int> get _params1;
}
