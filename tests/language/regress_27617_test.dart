// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  final String greeting;
  Foo._(this.greeting) {}

  // Const constructor must not redirect to non-const constructor.
  const Foo.hi() : this._('hi'); // //# 1: compile-time error
}

main() {
  const h = const Foo.hi(); // //# 1: continued
}
