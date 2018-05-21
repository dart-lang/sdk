// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.bytecode;

import 'package:kernel/ast.dart';
import 'package:vm/bytecode/constant_pool.dart' show ConstantPool;
import 'package:vm/bytecode/disassembler.dart' show BytecodeDisassembler;
import 'package:vm/bytecode/exceptions.dart' show ExceptionsTable;

/// Metadata containing bytecode.
///
/// In kernel binary, bytecode metadata is encoded as following:
///
/// type BytecodeMetadata {
///   ConstantPool constantPool
///   List<Byte> bytecodes
///   ExceptionsTable exceptionsTable
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
  final ConstantPool constantPool;
  final List<int> bytecodes;
  final ExceptionsTable exceptionsTable;
  final List<ClosureBytecode> closures;

  BytecodeMetadata(
      this.constantPool, this.bytecodes, this.exceptionsTable, this.closures);

  // TODO(alexmarkov): Consider printing constant pool before bytecode.
  @override
  String toString() => "\n"
      "Bytecode {\n"
      "${new BytecodeDisassembler().disassemble(bytecodes, exceptionsTable)}}\n"
      "$exceptionsTable"
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
    metadata.constantPool.writeToBinary(node, sink);
    sink.writeByteList(metadata.bytecodes);
    metadata.exceptionsTable.writeToBinary(sink);
    sink.writeUInt30(metadata.closures.length);
    metadata.closures.forEach((c) => c.writeToBinary(sink));
  }

  @override
  BytecodeMetadata readFromBinary(Node node, BinarySource source) {
    final ConstantPool constantPool =
        new ConstantPool.readFromBinary(node, source);
    final List<int> bytecodes = source.readByteList();
    final exceptionsTable = new ExceptionsTable.readFromBinary(source);
    final List<ClosureBytecode> closures = new List<ClosureBytecode>.generate(
        source.readUInt(), (_) => new ClosureBytecode.readFromBinary(source));
    return new BytecodeMetadata(
        constantPool, bytecodes, exceptionsTable, closures);
  }
}
