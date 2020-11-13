// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

class A {
  static late x1;
  //     ^^^^
  // [analyzer] unspecified
  //          ^
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
  static late x5 = 0;
  //     ^^^^
  // [analyzer] unspecified
  //          ^
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.

  static final late x9;
  //           ^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'late' should be before the modifier 'final'.
  static final late A x10;
  //           ^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'late' should be before the modifier 'final'.
  static final late x11 = 0;
  //           ^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'late' should be before the modifier 'final'.
  static final late A x12 = null;
  //           ^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'late' should be before the modifier 'final'.
  //                        ^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] The value 'null' can't be assigned to a variable of type 'A' because 'A' is not nullable.

  covariant late x15;
  //        ^^^^
  // [analyzer] unspecified
  //             ^
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
  covariant late x16 = '';
  //        ^^^^
  // [analyzer] unspecified
  //             ^
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.

  late covariant var x17;
  //   ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'covariant' should be before the modifier 'late'.
  late covariant var x18 = '';
  //   ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'covariant' should be before the modifier 'late'.
  late covariant x19;
  //   ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'covariant' should be before the modifier 'late'.
  //             ^^^
  // [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
  late covariant x20 = '';
  //   ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'covariant' should be before the modifier 'late'.
  //             ^^^
  // [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
  
  covariant var late x21;
  //            ^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'late' should be before the modifier 'var'.
  covariant var late x22 = '';
  //            ^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'late' should be before the modifier 'var'.

  covariant double late x23;
  //               ^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD
  // [cfe] Expected ';' after this.
  //               ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Field 'late' should be initialized because its type 'double' doesn't allow null.
  //                    ^^^
  // [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
  covariant String late x24 = '';
  //               ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'late' is already declared in this scope.
  //               ^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD
  // [cfe] Expected ';' after this.
  //               ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  //                    ^^^
  // [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.

  late x25;
  //   ^^^^
  // [analyzer] unspecified
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
  late x29 = 0;
  //   ^^^^
  // [analyzer] unspecified
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.

  final late x33;
  //    ^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'late' should be before the modifier 'final'.
  int late x34;
  //  ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'late' is already declared in this scope.
  //  ^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD
  // [cfe] Expected ';' after this.
  //  ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  //       ^^^
  // [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
  var late x35;
  //  ^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'late' should be before the modifier 'var'.
  final late A x36;
  //    ^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'late' should be before the modifier 'final'.
  final late x37 = 0;
  //    ^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'late' should be before the modifier 'final'.
  int late x38 = 0;
  //  ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'late' is already declared in this scope.
  //  ^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD
  // [cfe] Expected ';' after this.
  //  ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  //       ^^^
  // [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
  var late x39 = 0;
  //  ^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'late' should be before the modifier 'var'.
  final late A? x40 = null;
  //    ^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'late' should be before the modifier 'final'.

}

abstract class B {
  m1(int some, regular, covariant parameters, {
      required p1,
      required p2 = null,
      //       ^^
      // [analyzer] COMPILE_TIME_ERROR.DEFAULT_VALUE_ON_REQUIRED_PARAMETER
      // [cfe] Named parameter 'p2' is required and can't have a default value.
      required covariant p3,
      required covariant int p4,
  });
}

main() {
}
