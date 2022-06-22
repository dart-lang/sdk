// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<T> {
  final List<int> foo;
  const Foo(List x) : foo = x is List<T> ? const [1] : const [2];
}

main() {
  const Foo<int> foo = const Foo<int>(bool.fromEnvironment("foo") ? [1] : [2]);
  print(foo);
  print(foo);
}
