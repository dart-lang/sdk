// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.bytecode;

import 'package:kernel/ast.dart'
    show BinarySink, BinarySource, MetadataRepository, Node, TreeNode;
import 'package:kernel/ast.dart' as ast show Component;
import '../bytecode/bytecode_serialization.dart'
    show BufferedWriter, BufferedReader, LinkWriter, LinkReader;
import '../bytecode/declarations.dart' show Component, Members;

abstract class BytecodeMetadata {
  void write(BufferedWriter writer);
}

class MembersBytecodeMetadata extends BytecodeMetadata {
  final Members members;

  MembersBytecodeMetadata(this.members);

  @override
  void write(BufferedWriter writer) {
    writer.writeLinkOffset(members);
  }

  factory MembersBytecodeMetadata.read(BufferedReader reader) {
    return new MembersBytecodeMetadata(reader.readLinkOffset<Members>());
  }

  @override
  String toString() => "\n"
      "MembersBytecodeMetadata {\n"
      "$members\n"
      "}\n";
}

class ComponentBytecodeMetadata extends BytecodeMetadata {
  final Component component;

  ComponentBytecodeMetadata(this.component);

  @override
  void write(BufferedWriter writer) {
    component.write(writer);
  }

  factory ComponentBytecodeMetadata.read(BufferedReader reader) {
    return new ComponentBytecodeMetadata(new Component.read(reader));
  }

  @override
  String toString() => "\n"
      "ComponentBytecodeMetadata {\n"
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

  Component bytecodeComponent;
  LinkWriter linkWriter;
  LinkReader linkReader;

  @override
  void writeToBinary(BytecodeMetadata metadata, Node node, BinarySink sink) {
    if (node is ast.Component) {
      bytecodeComponent = (metadata as ComponentBytecodeMetadata).component;
      linkWriter = new LinkWriter();
    } else {
      assert(bytecodeComponent != null);
      assert(linkWriter != null);
    }
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
    if (node is ast.Component) {
      linkReader = new LinkReader();
      final reader = new BufferedReader(
          -1, null, null, linkReader, source.bytes,
          baseOffset: source.currentOffset);
      bytecodeComponent = new Component.read(reader);
      return new ComponentBytecodeMetadata(bytecodeComponent);
    } else {
      final reader = new BufferedReader(
          bytecodeComponent.version,
          bytecodeComponent.stringTable,
          bytecodeComponent.objectTable,
          linkReader,
          source.bytes,
          baseOffset: source.currentOffset);
      return new MembersBytecodeMetadata.read(reader);
    }
  }
}
