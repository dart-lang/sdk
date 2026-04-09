// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A compile-time error occurs if a mixin class declaration has a primary
// constructor which is not trivial, that is, it declares one or more
// parameters, or it has a body part that has an initializer list or a body.

// SharedOptions=--enable-experiment=primary-constructors

mixin class M1(int x);
//          ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_NON_TRIVIAL_GENERATIVE_CONSTRUCTOR
//            ^
// [cfe] Can't use 'M1' as a mixin because it has constructors.

mixin class M2(int x) {
//          ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_NON_TRIVIAL_GENERATIVE_CONSTRUCTOR
//            ^
// [cfe] Can't use 'M2' as a mixin because it has constructors.
}

mixin class M3() {
  this : assert(true);
//     ^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_NON_TRIVIAL_GENERATIVE_CONSTRUCTOR
//       ^
// [cfe] Can't use 'M3' as a mixin because it has constructors.
}

mixin class M4() {
  this; // Trivial constructor. This is OK.
}

mixin class M5() {
  this {}
//     ^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_NON_TRIVIAL_GENERATIVE_CONSTRUCTOR
// [cfe] Can't use 'M5' as a mixin because it has constructors.
}
