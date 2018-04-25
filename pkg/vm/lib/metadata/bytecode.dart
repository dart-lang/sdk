// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.bytecode;

import 'package:kernel/ast.dart';
import 'package:vm/bytecode/constant_pool.dart' show ConstantPool;
import 'package:vm/bytecode/disassembler.dart' show BytecodeDisassembler;

/// Metadata containing bytecode.
class BytecodeMetadata {
  final List<int> bytecodes;
  final ConstantPool constantPool;

  BytecodeMetadata(this.bytecodes, this.constantPool);

  @override
  String toString() =>
      "\nBytecode {\n${new BytecodeDisassembler().disassemble(bytecodes)}}\n$constantPool";
}

/// Repository for [BytecodeMetadata].
class BytecodeMetadataRepository extends MetadataRepository<BytecodeMetadata> {
  @override
  final String tag = 'vm.bytecode';

  @override
  final Map<TreeNode, BytecodeMetadata> mapping =
      <TreeNode, BytecodeMetadata>{};

  @override
  void writeToBinary(BytecodeMetadata metadata, BinarySink sink) {
    sink.writeByteList(metadata.bytecodes);
    metadata.constantPool.writeToBinary(sink);
  }

  @override
  BytecodeMetadata readFromBinary(BinarySource source) {
    final List<int> bytecodes = source.readByteList();
    final ConstantPool constantPool = new ConstantPool.readFromBinary(source);
    return new BytecodeMetadata(bytecodes, constantPool);
  }
}
