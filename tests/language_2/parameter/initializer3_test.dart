// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Fails because this.x parameter is used in a factory.

class Foo {
  var x;
  factory Foo(this.x) => new Foo.named();
  //          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR
  // [cfe] Field formal parameters can only be used in a constructor.
  Foo.named() {}
}

main() {
  Foo(2);
}
