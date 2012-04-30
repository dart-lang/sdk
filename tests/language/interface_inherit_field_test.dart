// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that it is legal to override a field with a field in an interface.

interface IA {
  final int foo;
}

interface IB extends IA {
  final int foo;
}

class B implements IB {
  int _f = 123;
  int get foo() => _f;
}

main() {
  IB b = new B();
  print('b.foo = ${b.foo}');
}
