// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--generic-method-syntax

/// Dart test verifying that the parser can handle type parameterization of
/// function declarations and function invocations. Variant of code from
/// DEP #22, adjusted to use generic top level functions.

library generic_functions_test;

import "package:expect/expect.dart";

class BinaryTreeNode<K extends Comparable<K>, V> {
  final K _key;
  final V _value;
  final BinaryTreeNode<K, V> _left;
  final BinaryTreeNode<K, V> _right;

  BinaryTreeNode(this._key, this._value,
      {BinaryTreeNode<K, V> left: null, BinaryTreeNode<K, V> right: null})
      : _left = left,
        _right = right;

  BinaryTreeNode<K, V> insert(K key, V value) {
    int c = key.compareTo(_key);
    if (c == 0) return this;
    var _insert = (BinaryTreeNode<K, V> t, K key, V value) =>
        insertOpt<K, V>(t, key, value);
    BinaryTreeNode<K, V> left = _left;
    BinaryTreeNode<K, V> right = _right;
    if (c < 0) {
      left = _insert(_left, key, value);
    } else {
      right = _insert(_right, key, value);
    }
    return new BinaryTreeNode<K, V>(_key, _value, left: left, right: right);
  }

  BinaryTreeNode<K, U> map<U>(U f(V x)) {
    var _map = (BinaryTreeNode<K, V> t, U f(V x)) => mapOpt<K, V, U>(t, f);
    return new BinaryTreeNode<K, U>(_key, f(_value),
        left: _map(_left, f), right: _map(_right, f));
  }

  S foldPre<S>(S init, S f(V t, S s)) {
    var _fold = (BinaryTreeNode<K, V> t, S s, S f(V t, S s)) =>
        foldPreOpt<K, V, S>(t, s, f);
    S s = init;
    s = f(_value, s);
    s = _fold(_left, s, f);
    s = _fold(_right, s, f);
    return s;
  }
}

BinaryTreeNode<K2, V2> insertOpt<K2 extends Comparable<K2>, V2>(
    BinaryTreeNode<K2, V2> t, K2 key, V2 value) {
  return (t == null) ? new BinaryTreeNode(key, value) : t.insert(key, value);
}

BinaryTreeNode<K, U> mapOpt<K extends Comparable<K>, V, U>(
    BinaryTreeNode<K, V> t, U f(V x)) {
  return (t == null) ? null : t.map<U>(f);
}

S foldPreOpt<K2 extends Comparable<K2>, V, S>(
    BinaryTreeNode<K2, V> t, S init, S f(V t, S s)) {
  return (t == null) ? init : t.foldPre<S>(init, f);
}

class BinaryTree<K extends Comparable<K>, V> {
  final BinaryTreeNode<K, V> _root;

  BinaryTree._internal(this._root);
  BinaryTree.empty() : this._internal(null);

  BinaryTree<K, V> insert(K key, V value) {
    BinaryTreeNode<K, V> root = insertOpt<K, V>(_root, key, value);
    return new BinaryTree<K, V>._internal(root);
  }

  BinaryTree<K, U> map<U>(U f(V x)) {
    BinaryTreeNode<K, U> root = mapOpt<K, V, U>(_root, f);
    return new BinaryTree<K, U>._internal(root);
  }

  S foldPre<S>(S init, S f(V t, S s)) {
    return foldPreOpt<K, V, S>(_root, init, f);
  }
}

main() {
  BinaryTree<num, String> sT = new BinaryTree<num, String>.empty();

  sT = sT.insert(0, "");
  sT = sT.insert(1, " ");
  sT = sT.insert(2, "  ");
  sT = sT.insert(3, "   ");

  BinaryTree<num, num> iT = sT.map<num>((String s) => s.length);

  Expect.equals(iT.foldPre<num>(0, (num i, num s) => i + s), 6);
}
