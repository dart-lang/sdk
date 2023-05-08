// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Syntax errors such as using `sealed` keyword in a place other than a class or
// mixin.

abstract class SealedMembers {
  sealed int foo;
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'sealed' isn't a type.
//       ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//           ^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.

  int bar(sealed int x);
//^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'int' isn't a type.
//        ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'sealed' isn't a type.
//                   ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ')' before this.

  sealed void bar2();
//^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Expected ';' after this.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
}

sealed abstract class SealedAndAbstractClass {}
// [error column 1, length 6]
// [analyzer] SYNTACTIC_ERROR.ABSTRACT_SEALED_CLASS
// [cfe] A 'sealed' class can't be marked 'abstract' because it's already implicitly abstract.


abstract sealed class SealedAndAbstractClass2 {}
//       ^^^^^^
// [analyzer] SYNTACTIC_ERROR.ABSTRACT_SEALED_CLASS
// [cfe] A 'sealed' class can't be marked 'abstract' because it's already implicitly abstract.

sealed sealed class SealedDuplicateClass {}
// [error column 1, length 6]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'sealed' isn't a type.
// [cfe] Can't use 'sealed' because it is declared more than once.
//     ^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.

class SealedVariable {
  int foo() {
    sealed var x = 2;
//  ^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Can't use 'sealed' because it is declared more than once.
// [cfe] Expected ';' after this.
    return x;
  }
}

sealed extension StringExtension on String {}
// [error column 1, length 6]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] 'sealed' isn't a type.
// [cfe] Expected ';' after this.
//     ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got 'extension'.

sealed enum Enum { x }
// [error column 1, length 6]
// [analyzer] SYNTACTIC_ERROR.SEALED_ENUM
// [cfe] Enums can't be declared to be 'sealed'.

sealed typedef EnumTypedef = Enum;
// [error column 1, length 6]
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] 'sealed' is already declared in this scope.
// [cfe] Expected ';' after this.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
