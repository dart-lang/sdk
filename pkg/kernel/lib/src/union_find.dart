// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implementation of a union-find algorithm.
///
/// See https://en.wikipedia.org/wiki/Disjoint-set_data_structure

import 'dart:collection';

class UnionFindNode<T> {
  final T value;
  UnionFindNode<T>? parent;

  UnionFindNode(this.value);
}

class UnionFind<T> {
  final Map<T, UnionFindNode<T>> _nodeMap;

  UnionFind({bool useIdentity = false})
      : _nodeMap = useIdentity ? new LinkedHashMap.identity() : {};

  UnionFindNode<T> operator [](T value) =>
      _nodeMap[value] ??= new UnionFindNode<T>(value);

  Iterable<UnionFindNode<T>> get nodes => _nodeMap.values;

  Iterable<T> get values => nodes.map((n) => n.value);

  UnionFindNode<T> findNode(UnionFindNode<T> node) {
    if (node.parent != null) {
      // Perform path compression by updating to the effective target.
      return node.parent = findNode(node.parent!);
    }
    return node;
  }

  void unionOfValues(T a, T b) {
    unionOfNodes(this[a], this[b]);
  }

  UnionFindNode<T> unionOfNodes(UnionFindNode<T> a, UnionFindNode<T> b) {
    UnionFindNode<T> rootA = findNode(a);
    UnionFindNode<T> rootB = findNode(b);
    if (rootA != rootB) {
      return rootB.parent = rootA;
    }
    return rootA;
  }

  bool valuesInSameSet(T a, T b) {
    UnionFindNode<T>? node1 = _nodeMap[a];
    UnionFindNode<T>? node2 = _nodeMap[b];
    return node1 != null && node2 != null && nodesInSameSet(node1, node2);
  }

  bool nodesInSameSet(UnionFindNode<T> a, UnionFindNode<T> b) {
    return findNode(a) == findNode(b);
  }
}
