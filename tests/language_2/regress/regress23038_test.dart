// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

class C<T> {
  const
    factory
  C()
//^
// [cfe] Cyclic definition of factory 'C'.
    = C<C<T>>
    //^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.RECURSIVE_CONSTRUCTOR_REDIRECT
  ;
}

main() {
  const C<int>();
}
