// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from co19/src/LanguageFeatures/Patterns/invocation_keys_A04_t03.dart

import 'dart:collection';

class MyList<E> with ListMixin<E> {
  final List<E> list;
  StringBuffer sb = new StringBuffer();

  MyList(this.list);

  E operator [](int index) {
    sb.write('[$index];');
    return list[index];
  }

  void operator []=(int index, E value) {
    list[index] = value;
  }

  int get length => list.length;

  void set length(int value) {
    list.length = value;
  }

  String get log => sb.toString();

  void clearLog() {
    sb.clear();
  }
}

String test1(Object o) =>
    switch (o) { [var x, 2, var y] => "match-1", _ => "no match" };

String test2(Object o) =>
    switch (o) { [1, var x, var y] => "match-1", _ => "no match" };

String test3(Object o) => switch (o) {
      [var x!, 1] => "match-1",
      [1, var x!] => "match-2",
      _ => "no match"
    };

main() {
  final ml1 = MyList<int>([1, 2, 3]);
  expect("match-1", test1(ml1));
  expect("[0];[1];[2];", ml1.log);

  final ml2 = MyList<int>([1, 2, 3]);
  expect("match-1", test2(ml2));
  expect("[0];[1];[2];", ml2.log);

  final ml3 = MyList<int>([1, 2]);
  expect("match-2", test3(ml3));
  expect("[0];[1];", ml3.log);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
