// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class C {
  static void test1(v, [A a]) {}

  static void test2(v, {A a}) {}

  void test11(v, [A a]) {}

  void test22(v, {A a}) {}
}

void test1(v, [A a]) {}

void test2(v, {A a}) {}

main() {}
