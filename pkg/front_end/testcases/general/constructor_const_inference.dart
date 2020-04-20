// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the type inference implementation correctly uses least
// closure of the inferred type arguments in invocations of 'const' constructors
// in case there are type variables in them.

class _Y<T> {
  const _Y();
}

class A<T> {
  _Y<T> x;
  A(this.x);
}

class B<T> extends A<T> {
  B() : super(const _Y());
}

main() {
  dynamic x = new B().x;
  if (x is! _Y<Null>) {
    throw "Unexpected run-time type: `new B().x` is ${x.runtimeType}, "
        "but `_Y<Null>` expected";
  }
}
