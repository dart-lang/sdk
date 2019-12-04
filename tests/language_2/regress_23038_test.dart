// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  const
    factory
  C()
//^
// [cfe] Cyclic definition of factory 'C'.
    = C<C<T>>
    //^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.RECURSIVE_FACTORY_REDIRECT
    // [cfe] The constructor function type 'C<C<T>> Function()' isn't a subtype of 'C<T> Function()'.
  ;
}

main() {
  const C<int>();
}
