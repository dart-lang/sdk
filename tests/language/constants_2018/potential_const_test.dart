// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the correct places allows, and requires, potentially constant
// expressions.

bool get nonConst => true;

class C {
  final v;
  const C(this.v);

  // Redirecting generative constructor invocation parameters,
  // must be potenentially constant.
  const C.r1() : this(const C(null));

  // Only evaluates the true branch when passed `true` as argument.
  const C.r2(bool b) : this(b ? null : 1 ~/ 0);

  const C.rn1() : this(nonConst);
  //                   ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  // [cfe] Constant evaluation error:

  const C.rn2(bool b) : this(b ? null : nonConst);
  //                                    ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  // [cfe] Constant evaluation error:

  // Initializer list expressions must be potentially constant.
  const C.g1() : v = const C(null);

  const C.g2(bool b) : v = b ? null : 1 ~/ 0;

  const C.gn3() : v = nonConst;
  //                  ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  // [cfe] Constant evaluation error:

  const C.gn4(bool b) : v = b ? null : nonConst;
  //                                   ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  // [cfe] Constant evaluation error:

  // Constant constructor initializer list assert expressions
  // must be potentially constant (and boolean).
  const C.a1()
      : assert(const C(null) != null),
        v = null;

  const C.a2(bool b)
      : assert(b ? const C(null) != null : ((1 ~/ 0) as bool)),
        v = null;

  const C.an1()
      : assert(nonConst),
        //     ^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
        // [cfe] Constant evaluation error:
        v = null;

  const C.an2(bool b)
      : assert(b ? true : nonConst),
        //                ^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
        // [cfe] Constant evaluation error:
        v = null;
}

main() {
  var c = const C(null);
  var cc = const C(C(null));

  var r1 = const C.r1();
  var r2 = const C.r2(true);

  /// Const constructor invocation which would throw.
  /**/ const C.r2(false);
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_THROWS_EXCEPTION
  //         ^^^^^^^^^^^
  // [cfe] Constant evaluation error:

  var g1 = const C.g1();
  var g2 = const C.g2(true);
  /**/ const C.g2(false);
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_THROWS_EXCEPTION
  //         ^^^^^^^^^^^
  // [cfe] Constant evaluation error:

  var a1 = const C.a1();
  var a2 = const C.a2(true);
  /**/ const C.a2(false);
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_THROWS_EXCEPTION
  //         ^^^^^^^^^^^
  // [cfe] Constant evaluation error:
}
