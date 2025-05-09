// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  const factory C() = C<C<T>>;
  //            ^
  // [cfe] Cyclic definition of factory 'C'.
  //                  ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RECURSIVE_CONSTRUCTOR_REDIRECT
}

main() {
  const C<int>();
}
