// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.obfuscation_prohibitions;

import 'package:kernel/ast.dart';

class ObfuscationProhibitionsMetadata {
  final Set<String> protectedNames = Set<String>();

  ObfuscationProhibitionsMetadata();

  @override
  String toString() => protectedNames.toString();
}

/// Repository for [ObfuscationProhibitionsMetadata].
class ObfuscationProhibitionsMetadataRepository
    extends MetadataRepository<ObfuscationProhibitionsMetadata> {
  static final repositoryTag = 'vm.obfuscation-prohibitions.metadata';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, ObfuscationProhibitionsMetadata> mapping =
      <TreeNode, ObfuscationProhibitionsMetadata>{};

  @override
  void writeToBinary(
      ObfuscationProhibitionsMetadata metadata, Node node, BinarySink sink) {
    sink.writeUInt32(metadata.protectedNames.length);
    for (String name in metadata.protectedNames) {
      sink.writeStringReference(name);
    }
  }

  @override
  ObfuscationProhibitionsMetadata readFromBinary(
      Node node, BinarySource source) {
    final metadata = ObfuscationProhibitionsMetadata();
    int length = source.readUint32();
    for (int i = 0; i < length; ++i) {
      metadata.protectedNames.add(source.readStringReference());
    }
    return metadata;
  }
}
