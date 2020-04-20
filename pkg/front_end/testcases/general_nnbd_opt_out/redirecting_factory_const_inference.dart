// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// This test checks that the type inference implementation correctly uses least
// closure of the inferred type arguments in invocations of 'const' redirecting
// factory constructors in case there are type variables in them.

class _X<T> {
  const factory _X() = _Y<T>;
}

class _Y<T> implements _X<T> {
  const _Y();
}

class A<T> {
  _X<T> x;
  A(this.x);
}

class B<T> extends A<T> {
  B() : super(const _X());
}

main() {
  dynamic x = new B().x;
  if (x is! _Y<Null>) {
    throw "Unexpected run-time type: `new B().x` is ${x.runtimeType}, "
        "but `_Y<Null>` expected";
  }
}
