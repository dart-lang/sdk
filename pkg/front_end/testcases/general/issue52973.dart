// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<T> {}

class C<T extends Object> {
  void something(T? Function() read) {
    var argumentValue = read();
    if (argumentValue is! Foo<String>) {
      return;
    }
    CheckType(argumentValue).expect<Exactly<T>>();
    var fooValue = argumentValue as Foo<String>;
    CheckType(fooValue).expect<Exactly<Foo<String>>>();
    CheckTypeArgumentOfFoo(fooValue).expect<Exactly<String>>();
  }
}

extension CheckType<T> on T {
  void expect<S extends Exactly<T>>() {}
}

extension CheckTypeArgumentOfFoo<T> on Foo<T> {
  void expect<S extends Exactly<T>>() {}
}

typedef Exactly<T> = T Function(T);

void main() {
  C<Foo<String>>().something(() => Foo<String>());
}
