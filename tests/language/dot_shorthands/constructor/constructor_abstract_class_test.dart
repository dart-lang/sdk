// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We allow shorthand syntax for factory constructors from abstract classes.

// SharedOptions=--enable-experiment=dot-shorthands

abstract class Foo<T> {
  factory Foo.a() = _Foo;
  Foo();
}

class _Foo<T> extends Foo<T> {
  _Foo();
}

Foo<T> noTypeArgsFactory<T>() => .a();

void main() async {
  var iter = [1, 2];
  await for (var x in .fromIterable(iter)) {
    print(x);
  }

  noTypeArgsFactory();
}
