// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';

const String TEST = r"""
class A {
  foo() => bar();
  bar() => 42;
}
class B extends A {
  bar() => 54;
}
class C implements A {
  bar() => 68;
}
main() {
  new A();
  new B();
  new C();
  new A().foo();
}
""";

void main() {
  String generated = compileAll(TEST);
  Expect.isTrue(generated.contains('return 42'));
  Expect.isTrue(generated.contains('return 54'));
  Expect.isFalse(generated.contains('return 68'));
}
