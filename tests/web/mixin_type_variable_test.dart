// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(https://github.com/dart-lang/sdk/issues/51557): Decide if the mixins
// being applied in this test should be "mixin", "mixin class" or the test
// should be left at 2.19.
// @dart=2.19

abstract class Bar<C> {
  final List<C> _one = [];

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
  Foo();
  C('e');
  F('e');
}
