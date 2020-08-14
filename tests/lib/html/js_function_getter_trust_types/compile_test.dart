// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--trust-type-annotations
@JS()
library js_function_getter_trust_types_test;

import 'package:js/js.dart';
import 'package:expect/expect.dart';

import 'js_function_util.dart';

main() {
  injectJs();

  foo.bar.nonFunctionStatic();
//        ^
// [cfe] Error: 'nonFunctionStatic' isn't a function or method and can't be invoked.
//^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION

  foo.bar.nonFunctionStatic(0);
//        ^
// [cfe] Error: 'nonFunctionStatic' isn't a function or method and can't be invoked.
//^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION

  foo.bar.nonFunctionStatic(0, 0);
//        ^
// [cfe] Error: 'nonFunctionStatic' isn't a function or method and can't be invoked.
//^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION

  foo.bar.nonFunctionStatic(0, 0, 0, 0, 0, 0);
//        ^
// [cfe] Error: 'nonFunctionStatic' isn't a function or method and can't be invoked.
//^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION

  foo.bar.add(4);
  //         ^
  // [cfe] Error: Too few positional arguments: 2 required, 1 given.
  //         ^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS

  foo.bar.add(4, 5, 10);
  //         ^
  // [cfe] Error: Too many positional arguments: 2 allowed, but 3 found.
  //         ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
}
