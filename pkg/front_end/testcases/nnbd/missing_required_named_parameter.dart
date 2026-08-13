// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void foo({required String s}) {}
void Function({required String s}) g = ({required String s}) {};

class A {
  A({required int x});
  foo({required int y}) {}
  void Function({required String s}) f = ({required String s}) {};
}

bar() {
  foo();
  new A();
  var a = new A(x: 42);
  a.foo();
  a.f();
  g();
}

main() {}
