// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that MirrorSystem.getName works correctly on symbols returned from
/// Invocation.memberName.  This is especially relevant when minifying.

import 'dart:mirrors' show MirrorSystem;

class Foo {
  String noSuchMethod(Invocation invocation) {
    return MirrorSystem.getName(invocation.memberName);
  }
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected: "$expected", but got "$actual"';
  }
}

main() {
  dynamic foo = new Foo();
  expect('foo', foo.foo);
  expect('foo', foo.foo());
  expect('foo', foo.foo(null));
  expect('foo', foo.foo(null, null));
  expect('foo', foo.foo(a: null, b: null));

  expect('baz', foo.baz);
  expect('baz', foo.baz());
  expect('baz', foo.baz(null));
  expect('baz', foo.baz(null, null));
  expect('baz', foo.baz(a: null, b: null));
}
