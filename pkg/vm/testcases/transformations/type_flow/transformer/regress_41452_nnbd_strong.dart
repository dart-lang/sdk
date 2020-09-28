// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/41452.
// Tests handling of null initializer of covariant field.
// This test requires non-nullable experiment and NNBD strong mode.

// @dart = 2.10

class _SplayTreeNode<Node extends _SplayTreeNode<Node>> {
  Node? left;
  _SplayTreeNode();
}

class _SplayTreeMapNode<V> extends _SplayTreeNode<_SplayTreeMapNode<V>> {
  _SplayTreeMapNode();
}

class _SplayTree<Node extends _SplayTreeNode<Node>> {
  Node? _root;

  add(Node n) {
    Node? root = _root;
    if (root == null) return;
    print(root.left); // Should be inferred as nullable.
  }
}

class SplayTreeMap<V> extends _SplayTree<_SplayTreeMapNode<V>> {
  _SplayTreeMapNode<V>? _root = _SplayTreeMapNode<V>();
}

void main() {
  SplayTreeMap().add(_SplayTreeMapNode());
}
