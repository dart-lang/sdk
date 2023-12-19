// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

typedef String F(String returns, String arguments, [Map<String, String> named]);

legacyMain() {}

class Xyzzy {
  static void foo() {}
  static String opt(String x, [String a, b]) => "";
  static String nam(String x, {String a, b}) => "";
  void intAdd(int x) {}
}

// Using 'MyList' instead of core lib 'List' keeps covariant parameter type of
// tear-offs 'Object' (legacy lib) instead of 'Object?' (opted-in lib).
class MyList<E> {
  void add(E value) {}
}

class G<U, V> {
  U foo(V x) => null;
  U moo(V f(U x)) => null;
  U higherOrder(int f(U x)) => null;
}
