// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when we try to construct a sealed class or mixin because they should
// both be implicitly abstract.

sealed class NotConstructable {}

mixin M {}
sealed class NotConstructableWithMixin = Object with M;

main() {
  var error = NotConstructable();
  //          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
  // [cfe] The class 'NotConstructable' is abstract and can't be instantiated.
  var error3 = NotConstructableWithMixin();
  //           ^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
  // [cfe] The class 'NotConstructableWithMixin' is abstract and can't be instantiated.
}
