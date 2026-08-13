// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  final String greeting;
  Foo._(this.greeting) {}

  // Const constructor must not redirect to non-const constructor.
  const Foo.hi() : this._('hi');
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_NON_CONST_CONSTRUCTOR
  // [cfe] A constant constructor can't call a non-constant constructor.
}

main() {
  const h = const Foo.hi();
}
