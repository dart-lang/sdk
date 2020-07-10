// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Bar<C> {
  final List<C> _one = new List<C>();

  final bool _two = Foo is C;
}

class Foo extends Object with Bar {}

abstract class A<E> {}

abstract class B<E> extends Object with A<E> {}

class C extends B<int> {
  final String _string;
  C(this._string);
}

abstract class D<T> {}

abstract class E<T> = Object with D<T>;

class F extends E<int> {
  final String _string;
  F(this._string);
}

main() {
  new Foo();
  new C('e');
  new F('e');
}
