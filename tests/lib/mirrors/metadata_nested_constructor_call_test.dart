// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for Issue 17141.

import 'dart:mirrors';

class Box {
  final contents;
  const Box([this.contents]);
}

class MutableBox {
  var contents;
  MutableBox([this.contents]); // Not const.
}

@Box(const Box(const MutableBox()))
//             ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
//                   ^
// [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
class D {}

@Box(const MutableBox(const Box()))
//   ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
//         ^
// [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
class E {}

@Box(Box(const MutableBox()))
//       ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
//             ^
// [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
class H {}

@Box(MutableBox(const Box()))
//   ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
class I {}

final closure = () => 42;

@Box(closure())
//   ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [cfe] Method invocation is not a constant expression.
// [cfe] Not a constant expression.
class J {}

@Box(closure)
// [error column 2]
// [cfe] Constant evaluation error:
//   ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [cfe] Not a constant expression.
class K {}

function() => 42;

@Box(function())
//   ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Method invocation is not a constant expression.
class L {}

main() {}
