// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class A {}

class C<T extends A> {
  T _field;

  foo(T x) {
    _field = x;
  }
}

class D extends C<B> {}

class Foo extends Object with C<B> {}

class B extends A {}

main() {
  var foo = new Foo();
  foo.foo(new B());
}
