// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.bytecode;

import 'package:kernel/ast.dart';
import '../bytecode/constant_pool.dart' show ConstantPool;
import '../bytecode/disassembler.dart' show BytecodeDisassembler;
import '../bytecode/exceptions.dart' show ExceptionsTable;

/// Metadata containing bytecode.
///
/// In kernel binary, bytecode metadata is encoded as following:
///
/// type BytecodeMetadata {
///   UInt flags (HasExceptionsTable, HasNullableFields, HasClosures)
///
///   ConstantPool constantPool
///   List<Byte> bytecodes
///
///   (optional, present if HasExceptionsTable)
///   ExceptionsTable exceptionsTable
///
///   (optional, present if HasNullableFields)
///   List<CanonicalName> nullableFields
///
///   (optional, present if HasClosures)
///   List<ClosureBytecode> closures
/// }
///
/// type ClosureBytecode {
///   ConstantIndex closureFunction
///   List<Byte> bytecodes
///   ExceptionsTable exceptionsTable
/// }
///
/// Encoding of ExceptionsTable is described in
/// pkg/vm/lib/bytecode/exceptions.dart.
///
/// Encoding of ConstantPool is described in
/// pkg/vm/lib/bytecode/constant_pool.dart.
///
class BytecodeMetadata {
  static const hasExceptionsTableFlag = 1 << 0;
  static const hasNullableFieldsFlag = 1 << 1;
  static const hasClosuresFlag = 1 << 2;

  final ConstantPool constantPool;
  final List<int> bytecodes;
  final ExceptionsTable exceptionsTable;
  final List<Reference> nullableFields;
  final List<ClosureBytecode> closures;

  bool get hasExceptionsTable => exceptionsTable.blocks.isNotEmpty;
  bool get hasNullableFields => nullableFields.isNotEmpty;
  bool get hasClosures => closures.isNotEmpty;

  int get flags =>
      (hasExceptionsTable ? hasExceptionsTableFlag : 0) |
      (hasNullableFields ? hasNullableFieldsFlag : 0) |
      (hasClosures ? hasClosuresFlag : 0);

  BytecodeMetadata(this.constantPool, this.bytecodes, this.exceptionsTable,
      this.nullableFields, this.closures);

  // TODO(alexmarkov): Consider printing constant pool before bytecode.
  @override
  String toString() => "\n"
      "Bytecode {\n"
      "${new BytecodeDisassembler().disassemble(bytecodes, exceptionsTable)}}\n"
      "$exceptionsTable"
      "${nullableFields.isEmpty ? '' : 'Nullable fields: ${nullableFields.map((ref) => ref.asField).toList()}\n'}"
      "$constantPool"
      "${closures.join('\n')}";
}

/// Bytecode of a nested function (closure).
/// Closures share the constant pool of a top-level member.
class ClosureBytecode {
  final int closureFunctionConstantIndex;
  final List<int> bytecodes;
  final ExceptionsTable exceptionsTable;

  ClosureBytecode(
      this.closureFunctionConstantIndex, this.bytecodes, this.exceptionsTable);

  void writeToBinary(BinarySink sink) {
    sink.writeUInt30(closureFunctionConstantIndex);
    sink.writeByteList(bytecodes);
    exceptionsTable.writeToBinary(sink);
  }

  factory ClosureBytecode.readFromBinary(BinarySource source) {
    final closureFunctionConstantIndex = source.readUInt();
    final List<int> bytecodes = source.readByteList();
    final exceptionsTable = new ExceptionsTable.readFromBinary(source);
    return new ClosureBytecode(
        closureFunctionConstantIndex, bytecodes, exceptionsTable);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.writeln('Closure CP#$closureFunctionConstantIndex {');
    sb.writeln(
        new BytecodeDisassembler().disassemble(bytecodes, exceptionsTable));
    sb.writeln('}');
    return sb.toString();
  }
}

/// Repository for [BytecodeMetadata].
class BytecodeMetadataRepository extends MetadataRepository<BytecodeMetadata> {
  @override
  final String tag = 'vm.bytecode';

  @override
  final Map<TreeNode, BytecodeMetadata> mapping =
      <TreeNode, BytecodeMetadata>{};

  @override
  void writeToBinary(BytecodeMetadata metadata, Node node, BinarySink sink) {
    sink.writeUInt30(metadata.flags);
    metadata.constantPool.writeToBinary(node, sink);
    sink.writeByteList(metadata.bytecodes);
    if (metadata.hasExceptionsTable) {
      metadata.exceptionsTable.writeToBinary(sink);
    }
    if (metadata.hasNullableFields) {
      sink.writeUInt30(metadata.nullableFields.length);
      metadata.nullableFields.forEach((ref) => sink
          .writeCanonicalNameReference(getCanonicalNameOfMember(ref.asField)));
    }
    if (metadata.hasClosures) {
      sink.writeUInt30(metadata.closures.length);
      metadata.closures.forEach((c) => c.writeToBinary(sink));
    }
  }

  @override
  BytecodeMetadata readFromBinary(Node node, BinarySource source) {
    int flags = source.readUInt();
    final ConstantPool constantPool =
        new ConstantPool.readFromBinary(node, source);
    final List<int> bytecodes = source.readByteList();
    final exceptionsTable =
        ((flags & BytecodeMetadata.hasExceptionsTableFlag) != 0)
            ? new ExceptionsTable.readFromBinary(source)
            : new ExceptionsTable();
    final List<Reference> nullableFields =
        ((flags & BytecodeMetadata.hasNullableFieldsFlag) != 0)
            ? new List<Reference>.generate(source.readUInt(),
                (_) => source.readCanonicalNameReference().getReference())
            : const <Reference>[];
    final List<ClosureBytecode> closures =
        ((flags & BytecodeMetadata.hasClosuresFlag) != 0)
            ? new List<ClosureBytecode>.generate(source.readUInt(),
                (_) => new ClosureBytecode.readFromBinary(source))
            : const <ClosureBytecode>[];
    return new BytecodeMetadata(
        constantPool, bytecodes, exceptionsTable, nullableFields, closures);
  }
}
