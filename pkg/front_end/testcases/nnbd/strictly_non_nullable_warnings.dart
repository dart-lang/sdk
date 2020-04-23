// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks for compile-time warnings about expressions of strictly
// non-nullable types being used in positions typically occupied by those of
// nullable types, that is, in various null-aware expressions.

extension E on String {
  int get foo => 42;
  void operator[]=(int index, int value) {}
  int operator[](int index) => 42;
}

class A {
  String operator[](int index) => "foo";
  void operator[]=(int index, String value) {}
}

class B extends A {
  void test() {
    super[42] ??= "bar"; // Warning.
  }
}

warning(String s, List<String> l, Map<String, int> m) {
  s?.length; // Warning.
  s?..length; // Warning.
  s ?? "foo"; // Warning.
  s ??= "foo"; // Warning.
  [...?l]; // Warning.
  var a = {...?l}; // Warning.
  <String>{...?l}; // Warning.
  var b = {...?m}; // Warning.
  <String, int>{...?m}; // Warning.
  s!; // Warning.
  s?.substring(0, 0); // Warning.
  l?.length = 42; // Warning.
  l?.length += 42; // Warning.
  l?.length ??= 42; // Warning.
  s?.foo; // Warning.
  E(s)[42] ??= 42; // Warning.
  l[42] ??= "foo"; // Warning.
  l.length ??= 42; // Warning.
  l?..length = 42; // Warning.
  l?..length ??= 42; // Warning.
}

main() {}
