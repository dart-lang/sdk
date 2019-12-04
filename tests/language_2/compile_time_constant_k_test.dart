// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

const x = const {
//        ^
// [cfe] Constant evaluation error:
  'a': 3,
  'a': 4
//^^^
// [analyzer] COMPILE_TIME_ERROR.EQUAL_KEYS_IN_CONST_MAP
};
const y = const {
//        ^
// [cfe] Constant evaluation error:
  'a': 10, 'b': 11, 'a': 12,
  //                ^^^
  // [analyzer] COMPILE_TIME_ERROR.EQUAL_KEYS_IN_CONST_MAP
  'b': 13, 'a': 14
//^^^
// [analyzer] COMPILE_TIME_ERROR.EQUAL_KEYS_IN_CONST_MAP
//         ^^^
// [analyzer] COMPILE_TIME_ERROR.EQUAL_KEYS_IN_CONST_MAP
};

const z = const {
//        ^
// [cfe] Constant evaluation error:
  '__proto__': 496,
  '__proto__': 497,
//^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EQUAL_KEYS_IN_CONST_MAP
  '__proto__': 498,
//^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EQUAL_KEYS_IN_CONST_MAP
  '__proto__': 499
//^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EQUAL_KEYS_IN_CONST_MAP
};

const x2 = const {'a': 4};
const y2 = const {'a': 14, 'b': 13};
const z2 = const {'__proto__': 499};

main() {
  Expect.identical(x2, x);
  Expect.identical(y2, y);
  Expect.identical(z2, z);
}
