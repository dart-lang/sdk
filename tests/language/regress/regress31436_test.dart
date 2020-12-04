// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void block_test() {
  List<Object> Function() g;
  g = () {
    return [3];
  };
  Expect.isTrue(g is List<Object> Function());
  Expect.isFalse(g is List<int> Function());
  g().add("hello"); // No runtime error
  List<int> l = [3];
  g = () {
    return l;
  };
  Expect.isTrue(g is List<Object> Function());
  Expect.isTrue(g is List<int> Function());
  Expect.throwsTypeError(() {
    g().add("hello"); // runtime error
  });
  dynamic o = l;
  g = () {
    return o;
  }; // No implicit downcast on the assignment, implicit downcast on the return
  Expect.isTrue(g is List<Object> Function());
  Expect.isFalse(g is List<int> Function());
  Expect.isTrue(g is Object Function());
  g(); // No runtime error;
  o = 3;
  Expect.throwsTypeError(() {
    g(); // Failed runtime cast on the return type of f
  });
}

void arrow_test() {
  List<Object> Function() g;
  g = () => [3];
  Expect.isTrue(g is List<Object> Function());
  Expect.isFalse(g is List<int> Function());
  g().add("hello"); // No runtime error
  List<int> l = [3];
  g = () => l;
  Expect.isTrue(g is List<Object> Function());
  Expect.isTrue(g is List<int> Function());
  Expect.throwsTypeError(() {
    g().add("hello"); // runtime error
  });
  dynamic o = l;
  g = () =>
      o; // No implicit downcast on the assignment, implicit downcast on the return
  Expect.isTrue(g is List<Object> Function());
  Expect.isFalse(g is List<int> Function());
  Expect.isTrue(g is Object Function());
  g(); // No runtime error;
  o = 3;
  Expect.throwsTypeError(() {
    g(); // Failed runtime cast on the return type of f
  });
}

main() {
  block_test();
  arrow_test();
}
