// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.binary_cache;

import 'package:kernel/ast.dart'
    show BinarySink, BinarySource, MetadataRepository, Node, TreeNode;

class BinaryCacheMetadataRepository extends MetadataRepository<List<int>> {
  static const repositoryTag = 'vm.binary_cache';

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
