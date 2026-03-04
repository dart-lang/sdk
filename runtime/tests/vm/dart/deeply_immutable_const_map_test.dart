// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_compact_hash" show createConstMapFromMapOfDeeplyImmutables;

import "package:expect/expect.dart";

@pragma('vm:deeply-immutable')
final class Foo {
  final Map<String, Object> bar;

  Foo(this.bar);
}

main() {
  final foo = Foo(const {"abc": "def"});
  Expect.equals(1, foo.bar.length);

  Expect.throws(() => Foo({"abc": "def"}), (e) => e is ArgumentError);

  final foo1 = Foo(createConstMapFromMapOfDeeplyImmutables({"abc": "def"}));
  Expect.equals(1, foo1.bar.length);

  Expect.throws(
    () => Foo({"ghi": foo, "jkl": foo1}),
    (e) => e is ArgumentError,
  );

  final foo2 = Foo(
    createConstMapFromMapOfDeeplyImmutables({"ghi": foo, "jkl": foo1}),
  );
  Expect.equals(2, foo2.bar.length);
}
