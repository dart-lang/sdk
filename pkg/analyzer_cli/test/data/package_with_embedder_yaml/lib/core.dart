// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.core;

import 'dart:async';

class Object {
  bool operator ==(other) => identical(this, other);
  String toString() => 'a string';
  int get hashCode => 0;
}

class Function {}

class StackTrace {}

class Symbol {}

class Type {}

abstract class Comparable<T> {
  int compareTo(T other);
}

abstract class String implements Comparable<String> {
  external factory String.fromCharCodes(Iterable<int> charCodes,
      [int start = 0, int end]);
  bool get isEmpty => false;
  bool get isNotEmpty => false;
  int get length => 0;
  String toUpperCase();
  List<int> get codeUnits;
}

class bool extends Object {}

abstract class num implements Comparable<num> {
  bool operator <(num other);
  bool operator <=(num other);
  bool operator >(num other);
  bool operator >=(num other);
  num operator +(num other);
  num operator -(num other);
  num operator *(num other);
  num operator %(num other);
  num operator /(num other);
  int toInt();
  num abs();
  int round();
}

abstract class int extends num {
  bool get isEven => false;
  int operator -();
  external static int parse(String source,
      {int radix, int onError(String source)});
}

class double extends num {}

class DateTime extends Object {}

class Null extends Object {}

class Deprecated extends Object {
  final String expires;
  const Deprecated(this.expires);
}

const Object deprecated = const Deprecated("next release");

class Iterator<E> {
  bool moveNext();
  E get current;
}

abstract class Iterable<E> {
  Iterator<E> get iterator;
  bool get isEmpty;
}

abstract class List<E> implements Iterable<E> {
  void add(E value);
  E operator [](int index);
  void operator []=(int index, E value);
  Iterator<E> get iterator => null;
  void clear();
}

abstract class Map<K, V> extends Object {
  bool containsKey(Object key);
  Iterable<K> get keys;
}

external bool identical(Object a, Object b);

void print(Object object) {}

class Uri {
  static List<int> parseIPv6Address(String host, [int start = 0, int end]) {
    int parseHex(int start, int end) {
      return 0;
    }

    return null;
  }
}
