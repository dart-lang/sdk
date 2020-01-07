// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  Foo();
  Foo();
//^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_CONSTRUCTOR
// [cfe] 'Foo' is already declared in this scope.
}

main() {
  new Foo();
  //  ^
  // [cfe] Can't use 'Foo' because it is declared more than once.
}
