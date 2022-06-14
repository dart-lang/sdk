// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<T> {
  const Foo(T Function(String)? foo) : _foo = foo ?? bar;
  final T Function(String) _foo;
}

T bar<T>(String o) => o as T;

void main() {
  const Foo<int> myValue = Foo<int>(
    bool.fromEnvironment("baz") ? int.parse : null,
  );
}
