// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing the instanceof operation.

import "package:expect/expect.dart";

// Tests involving generics.

abstract class I<T> {}

class A implements I<bool> {}

class B<T> implements I<bool> {}

abstract class K<T> {}

abstract class L<T> extends K<bool> {}

class C implements L<String> {}

class D implements B<String> {}

main() {
  var a = new A();
  var b = new B<String>();
  var c = new C();
  var d = new D();
  // Repeat type checks so that inlined tests can be tested as well.
  for (int i = 0; i < 5; i++) {
    Expect.isFalse(a is I<String>);
    Expect.isTrue(a is I<bool>);
    Expect.isFalse(b is I<String>);
    Expect.isFalse(c is K<String>);
    Expect.isFalse(c is K<String>);
    Expect.isTrue(c is L<String>);
    Expect.isFalse(c is L<bool>);
    Expect.isTrue(c is K<bool>);
    Expect.isFalse(c is K<String>);
    Expect.isFalse(d is I<String>);
    Expect.isTrue(d is I<bool>);
  }
}
