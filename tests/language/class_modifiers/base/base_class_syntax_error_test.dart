// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Syntax errors such as using `base` keyword in a place other than a class or
// mixin.

abstract class BaseMembers {
  base int foo;
//^^^^
// [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'base' isn't a type.
//     ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//         ^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.

  int bar(base int x);
//^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'int' isn't a type.
//        ^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'base' isn't a type.
//                 ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ')' before this.

  base void bar2();
//^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Expected ';' after this.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
}

base base class BaseDuplicateClass {}
// [error column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'base' isn't a type.
// [cfe] Can't use 'base' because it is declared more than once.
//   ^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.

base abstract class BaseAbstractClass {}
// [error column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'base' isn't a type.
// [cfe] Can't use 'base' because it is declared more than once.
//   ^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.

class BaseVariable {
  int foo() {
    base var x = 2;
//  ^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Can't use 'base' because it is declared more than once.
// [cfe] Expected ';' after this.
    return x;
  }
}

base extension StringExtension on String {}
// [error column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] 'base' isn't a type.
// [cfe] Expected ';' after this.
//   ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got 'extension'.

base enum Enum { x }
// [error column 1, length 4]
// [analyzer] SYNTACTIC_ERROR.BASE_ENUM
// [cfe] Enums can't be declared to be 'base'.

base typedef EnumTypedef = Enum;
// [error column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] 'base' is already declared in this scope.
// [cfe] Expected ';' after this.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
