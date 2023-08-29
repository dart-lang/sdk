// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List<(int,)> records = [(1,), (2,)];

// Library field initializer
Map<int, int> topLevel = {for (final (int x,) in records) x: x};

class Bar {
  final Map<int, int> bar;

  Bar(this.bar);
}

class Foo extends Bar {
  // Class field initializer
  final Map<int, int> foo1 = {for (final (int x,) in records) x: x};
  final Map<int, int> foo2;
  Foo()
      // Constructor field initializer
      : foo2 = {for (final (int x,) in records) x: x},
        // Super initializer
        super({for (final (int x,) in records) x: x});
}

void main() {
  print(topLevel);
  final foo = Foo();
  print(foo.foo1);
  print(foo.foo2);
  print(foo.bar);
}
