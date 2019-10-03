// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.bytecode;

import 'package:kernel/ast.dart'
    show BinarySink, BinarySource, MetadataRepository, Node, TreeNode;
import '../bytecode/bytecode_serialization.dart'
    show BufferedWriter, BufferedReader, LinkWriter, LinkReader;
import '../bytecode/declarations.dart' show Component;

import 'dart:developer';

class BytecodeMetadata {
  final Component component;

  BytecodeMetadata(this.component);

  void write(BufferedWriter writer) {
    Timeline.timeSync("BytecodeMetadata.write", () {
      component.write(writer);
    });
  }

  factory BytecodeMetadata.read(BufferedReader reader) {
    return Timeline.timeSync("BytecodeMetadata.read", () {
      return new BytecodeMetadata(new Component.read(reader));
    });
  }

  @override
  String toString() => "\n"
      "BytecodeMetadata {\n"
      "$component\n"
      "}\n";
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
    final bytecodeComponent = metadata.component;
    final linkWriter = new LinkWriter();
    final writer = new BufferedWriter(
        bytecodeComponent.version,
        bytecodeComponent.stringTable,
        bytecodeComponent.objectTable,
        linkWriter,
        baseOffset: sink.getBufferOffset());
    metadata.write(writer);
    sink.writeBytes(writer.takeBytes());
  }

  @override
  BytecodeMetadata readFromBinary(Node node, BinarySource source) {
    final linkReader = new LinkReader();
    final reader = new BufferedReader(-1, null, null, linkReader, source.bytes,
        baseOffset: source.currentOffset);
    final bytecodeComponent = new Component.read(reader);
    return new BytecodeMetadata(bytecodeComponent);
  }
}

class BinaryCacheMetadataRepository extends MetadataRepository<List<int>> {
  static const repositoryTag = 'vm.bytecode.cache';

  @override
  String get tag => repositoryTag;

  @override
  final Map<TreeNode, List<int>> mapping = <TreeNode, List<int>>{};

  @override
  void writeToBinary(List<int> metadata, Node node, BinarySink sink) {
    sink.writeByteList(metadata);
  }

  @override
  List<int> readFromBinary(Node node, BinarySource source) {
    List<int> result = source.readByteList();
    _weakMap[node] = result;
    return result;
  }

  static List<int> lookup(Node node) => _weakMap[node];
  static void insert(Node node, List<int> metadata) {
    _weakMap[node] = metadata;
  }

  static final _weakMap = new Expando<List<int>>();
}
