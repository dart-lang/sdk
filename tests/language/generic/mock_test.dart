// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/38384

class Built<X, Y> {}

class Foo {
  foo<S extends Built<S, B>, B extends Built<S, B>>() {}
}

class Mock {
  noSuchMethod(Invocation i) {}
}

class MockFoo extends Mock implements Foo {}

main() {}
