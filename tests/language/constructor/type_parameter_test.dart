// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  Foo<A>() {}
  // ^^^
  // [analyzer] SYNTACTIC_ERROR.TYPE_PARAMETER_ON_CONSTRUCTOR
  // [cfe] Constructors can't have type parameters.
}

main() {
  new Foo();
}
