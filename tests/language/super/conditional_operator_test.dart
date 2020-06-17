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
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    super?.field += 1;
    //   ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    super?.field ??= 1;
    //   ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    //               ^
    // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
    super?.field;
    //   ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    1 * super?.field;
    //  ^^^^^^^^^^^^
    // [analyzer] STATIC_WARNING.ARGUMENT_TYPE_NOT_ASSIGNABLE
    //       ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //       ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    -super?.field;
    //    ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //    ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    ~super?.field;
    //    ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //    ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    !super?.field;
//   ^^^^^^^^^^^^
// [analyzer] STATIC_TYPE_WARNING.NON_BOOL_NEGATION_EXPRESSION
//        ^^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
// [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
//        ^^
// [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
//          ^
// [cfe] A value of type 'int' can't be assigned to a variable of type 'bool'.
    --super?.field;
    //     ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    ++super?.field;
    //     ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    super?.method();
    //   ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    1 * super?.method();
    //       ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //       ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    -super?.method();
    //    ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //    ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    ~super?.method();
    //    ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //    ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    !super?.method();
    //    ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //    ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    --super?.method();
    //     ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    //       ^
    // [cfe] Can't assign to this.
    //              ^
    // [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
    ++super?.method();
    //     ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    // [cfe] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
    //       ^
    // [cfe] Can't assign to this.
    //              ^
    // [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
  }
}

main() {
  new C().test();
}
