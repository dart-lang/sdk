// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int get foo => 42;
}

extension E on A {
  double get bar => 3.14;
}

extension type ET on A {
  String get baz => "baz";
}

test(A a, E e, ET et) {
  a.foo; // Ok.
  a.bar; // Ok.
  a.baz; // Error.

  e.foo; // Error.
  e.bar; // Ok.
  e.baz; // Error.

  et.foo; // Error.
  et.bar; // Error.
  et.baz; // Ok.
}

main() {}
