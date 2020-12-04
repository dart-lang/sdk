// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that the ?. operator cannot be used with "super".

class B {
  B();
  B.namedConstructor();
  var field = 1;
  method() => 1;
}

class C extends B {
  C()
    : super?.namedConstructor()
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] Cannot use '?.' here.
    //     ^
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
  ;

  test() {
    super?.field = 1;
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    super?.field += 1;
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    super?.field ??= 1;
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //     ^
    // [cfe] Operand of null-aware operation '??=' has type 'int' which excludes null.
    //               ^
    // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
    super?.field;
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    1 * super?.field;
    //  ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    //       ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    -super?.field;
//   ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//        ^^
// [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
// [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    ~super?.field;
//   ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//        ^^
// [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
// [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    !super?.field;
//   ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_NEGATION_EXPRESSION
//        ^^
// [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
// [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
//          ^
// [cfe] A value of type 'int' can't be assigned to a variable of type 'bool'.
    --super?.field;
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    ++super?.field;
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    super?.method();
//  ^
// [cfe] The receiver 'this' cannot be null.
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    1 * super?.method();
    //  ^
    // [cfe] The receiver 'this' cannot be null.
    //       ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    -super?.method();
//   ^
// [cfe] The receiver 'this' cannot be null.
    //    ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    ~super?.method();
//   ^
// [cfe] The receiver 'this' cannot be null.
    //    ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    !super?.method();
//   ^
// [cfe] The receiver 'this' cannot be null.
    //    ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    --super?.method();
    //^
    // [cfe] The receiver 'this' cannot be null.
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //       ^
    // [cfe] Can't assign to this.
    //              ^
    // [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
    ++super?.method();
    //^
    // [cfe] The receiver 'this' cannot be null.
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //       ^
    // [cfe] Can't assign to this.
    //              ^
    // [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
  }
}

main() {
  new C().test();
}
