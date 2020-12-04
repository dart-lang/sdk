// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  final double d;
  const C(this.d);
}

class D extends C {
  const D(var d) : super(d);
}

const intValue = 0;
const c = const C(0.0);
const d = const C(intValue);
//                ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
// [cfe] The argument type 'int' can't be assigned to the parameter type 'double'.
//                ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
const e = const D(0.0);
const f = const D(intValue);
//        ^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_THROWS_EXCEPTION
//              ^
// [cfe] Constant evaluation error:

main() {
  print(c);
  print(d);
  print(e);
  print(f);
}
