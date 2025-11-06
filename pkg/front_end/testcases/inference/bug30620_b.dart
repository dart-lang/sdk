// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class A {
  final String foo;

  A(this.foo);

  bool operator ==(Object other) =>
      other is A && other.foo == this.foo && other.foo == this.foo;
}

main() {
  print(new A("hello") == new A("hello"));
}
