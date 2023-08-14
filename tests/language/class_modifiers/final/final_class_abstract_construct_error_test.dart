// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when attempting to construct an abstract final class.

abstract final class NotConstructable {}

mixin M {}
abstract final class AlsoNotConstructable = Object with M;

main() {
  var error = NotConstructable();
//            ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
// [cfe] The class 'NotConstructable' is abstract and can't be instantiated.
  var error2 = AlsoNotConstructable();
//             ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
// [cfe] The class 'AlsoNotConstructable' is abstract and can't be instantiated.
}
