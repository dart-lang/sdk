// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Repository for persistent closure IDs.
class ClosureIdMetadataRepository extends MetadataRepository<int> {
  static const String repositoryTag = 'vm.closure-id';

  @override
  String get tag => repositoryTag;

  // For a LocalFunction: id within an enclosing Member,
  // with 0 reserved for the tear-off of the Member.
  //
  // For a Member: number of nested closures.
  @override
  final Map<TreeNode, int> mapping = {};

  @override
  void writeToBinary(int metadata, Node node, BinarySink sink) {
    sink.writeUInt30(metadata);
  }

  @override
  int readFromBinary(Node node, BinarySource source) {
    return source.readUInt30();
  }

  /// Return closure ID within the enclosing [Member], or -1
  /// if closure was not indexed.
  ///
  /// Closures should be indexed within enclosing [Member]
  /// using [indexClosures].
  int getClosureId(LocalFunction closure) => mapping[closure] ?? -1;

  /// Assign IDs for all closures within [member].
  void indexClosures(Member member) {
    if (mapping.containsKey(member)) {
      return;
    }
    _ClosureIndexer indexer = _ClosureIndexer(this, member);
    member.accept(indexer);
    mapping[member] = indexer.index - _ClosureIndexer.firstClosureIndex;
  }
}

class _ClosureIndexer extends RecursiveVisitor<void> {
  // Zero is reserved for tear-offs.
  static int firstClosureIndex = 1;

  final ClosureIdMetadataRepository _repository;
  final Member member;
  int index = firstClosureIndex;

  _ClosureIndexer(this._repository, this.member);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _visitLocalFunction(node);

  @override
  void visitFunctionExpression(FunctionExpression node) =>
      _visitLocalFunction(node);

  void _visitLocalFunction(LocalFunction node) {
    assert(index > 0);
    _repository.mapping[node] = index++;
    node.visitChildren(this);
  }
}
