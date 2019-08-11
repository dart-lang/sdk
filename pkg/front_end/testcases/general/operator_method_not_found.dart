// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
}

main() {
  Foo foo = new Foo();

  // Not defined, but given right arity.
  print(foo < 2);
  print(foo > 2);
  print(foo <= 2);
  print(foo >= 2);
  print(foo == 2);
  print(foo - 2);
  print(foo + 2);
  print(foo / 2);
  print(foo ~/ 2);
  print(foo * 2);
  print(foo % 2);
  print(foo | 2);
  print(foo ^ 2);
  print(foo & 2);
  print(foo << 2);
  print(foo >> 2);
  // print(foo >>> 2); // triple shift not enabled by default at the moment.
  print(foo[2] = 2);
  print(foo[2]);
  print(~foo);
  print(-foo);

  // Not defined, and given wrong arity.
  // Should be binary.
  print(<foo);
  print(>foo);
  print(<=foo);
  print(>=foo);
  print(==foo);
  print(+foo);
  print(/foo);
  print(~/foo);
  print(*foo);
  print(%foo);
  print(|foo);
  print(^foo);
  print(&foo);
  print(<<foo);
  print(>>foo);
  // print(>>>foo); // triple shift not enabled by default at the moment.

  // Should be unary.
  print(foo ~ 2);
}