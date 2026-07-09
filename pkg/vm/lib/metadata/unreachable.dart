// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.unreachable;

import 'package:kernel/ast.dart';

/// Metadata for annotating unreachable nodes. Note that the arguments
/// of an unreachable node could still be reachable.
/// Used to annotate calls and functions.
class UnreachableNode {
  const UnreachableNode();

  @override
  String toString() => '';
}

/// Repository for [UnreachableNode].
class UnreachableNodeMetadataRepository
    extends MetadataRepository<UnreachableNode> {
  static const repositoryTag = 'vm.unreachable.metadata';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, UnreachableNode> mapping = <TreeNode, UnreachableNode>{};

  @override
  void writeToBinary(UnreachableNode metadata, Node node, BinarySink sink) {}

  @override
  UnreachableNode readFromBinary(Node node, BinarySource source) {
    return const UnreachableNode();
  }
}
