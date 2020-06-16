// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Mock {
  noSuchMethod(i) => 1;
}

class Foo {
  int call() => 1;
}

class MockFoo extends Mock implements Foo {}

main() {
  var foo = new MockFoo();
  foo();
}
