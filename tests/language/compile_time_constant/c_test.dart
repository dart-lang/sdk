// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const m0 = const {499: 400 + 99};
const m1 = const {
  "foo" + "bar": 42
};
const m2 = const {
//         ^
// [cfe] Constant evaluation error:
  "foo" * 4: 42
//^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_TYPE_NUM
};
const m3 = const {
  "foo".codeUnitAt(0): 42
//^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
//^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_MAP_KEY
//      ^
// [cfe] Method invocation is not a constant expression.
};

use(x) => x;

main() {
  use(m0);
  use(m1);
  use(m2);
  use(m3);
}
