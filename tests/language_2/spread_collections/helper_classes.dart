// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

class ConstIterable extends IterableBase<int> {
  const ConstIterable();

  Iterator<int> get iterator => <int>[].iterator;
}

class ConstMap implements Map<int, String> {
  const ConstMap();

  Iterable<MapEntry<int, String>> get entries => const [];

  bool get isEmpty => throw UnsupportedError("unsupported");
  bool get isNotEmpty => throw UnsupportedError("unsupported");
  Iterable<int> get keys => throw UnsupportedError("unsupported");
  int get length => throw UnsupportedError("unsupported");
  Iterable<String> get values => throw UnsupportedError("unsupported");
  String operator [](Object key) => throw UnsupportedError("unsupported");
  operator []=(int key, String value) => throw UnsupportedError("unsupported");
  bool add(Object value) => throw UnsupportedError("unsupported");
  void addAll(Map<int, String> map) => throw UnsupportedError("unsupported");
  void addEntries(Iterable<MapEntry<int, String>> entries) =>
      throw UnsupportedError("unsupported");
  Map<RK, RV> cast<RK, RV>() => throw UnsupportedError("unsupported");
  void clear() => throw UnsupportedError("unsupported");
  bool containsKey(Object key) => throw UnsupportedError("unsupported");
  bool containsValue(Object value) => throw UnsupportedError("unsupported");
  void forEach(void Function(int key, String value) f) =>
      throw UnsupportedError("unsupported");
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(int key, String value) f) =>
      throw UnsupportedError("unsupported");
  String putIfAbsent(int key, String Function() ifAbsent) =>
      throw UnsupportedError("unsupported");
  String remove(Object key) => throw UnsupportedError("unsupported");
  void removeWhere(bool Function(int key, String value) predicate) =>
      throw UnsupportedError("unsupported");
  String update(int key, String Function(String value) update,
          {String Function() ifAbsent}) =>
      throw UnsupportedError("unsupported");
  void updateAll(String Function(int key, String value) update) =>
      throw UnsupportedError("unsupported");
}

class CustomMap with MapMixin<int, String> {
  Iterable<int> get keys => [];
  String operator [](Object key) => "";
  operator []=(int key, String value) {}
  String remove(Object key) => throw UnsupportedError("unsupported");
  void clear() => throw UnsupportedError("unsupported");
}

class CustomSet extends SetBase<int> {
  bool add(int value) => throw UnsupportedError("unsupported");
  bool contains(Object value) => throw UnsupportedError("unsupported");
  Iterator<int> get iterator => <int>[].iterator;
  int get length => 0;
  int lookup(Object value) => throw UnsupportedError("unsupported");
  bool remove(Object value) => throw UnsupportedError("unsupported");
  Set<int> toSet() => this;
}

class Equality {
  final int id;
  final String name;
  const Equality(this.id, this.name);
  int get hashCode => id;
  bool operator ==(Object other) => other is Equality && id == other.id;
  String toString() => "$id:$name";
}
