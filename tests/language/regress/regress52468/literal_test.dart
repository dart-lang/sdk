// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Nest an unevaluated constant inside a non-const record literal.
//
// Regression test for https://github.com/dart-lang/sdk/issues/52468
class Foo {
  static const Foo foo = Foo._(const bool.fromEnvironment('flag') ? '' : 'foo');

  const Foo._(String n);
}

void main() {
  print((Foo.foo, Foo.foo));
}
