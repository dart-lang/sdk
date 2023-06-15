// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Syntax errors such as using `mixin` keyword in a place other than a class or
// mixin.

abstract class BaseMembers {
  mixin int foo;
//^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Expected ';' after this.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
//          ^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD
// [cfe] Field 'foo' should be initialized because its type 'int' doesn't allow null.

  int bar(mixin int x);
//              ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.

  mixin void bar2();
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] 'mixin' is already declared in this scope.
// [cfe] Expected ';' after this.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
}

mixin mixin class BaseDuplicateClass {}
//    ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A mixin declaration must have a body, even if it is empty.
// [cfe] Expected an identifier, but got 'mixin'.

mixin abstract class BaseAbstractClass {}
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] A mixin declaration must have a body, even if it is empty.
// [cfe] Can't use 'abstract' as a name here.

class BaseVariable {
  int foo() {
    mixin var x = 2;
//  ^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
// [cfe] The getter 'mixin' isn't defined for the class 'BaseVariable'.
    return x;
  }
}

mixin mixin MM {}
//    ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A mixin declaration must have a body, even if it is empty.
// [cfe] Expected an identifier, but got 'mixin'.

mixin enum E { value }
//    ^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A mixin declaration must have a body, even if it is empty.
// [cfe] Expected an identifier, but got 'enum'.

mixin typedef T = String;
//    ^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A mixin declaration must have a body, even if it is empty.
// [cfe] Expected an identifier, but got 'typedef'.

mixin extension StringExtension on String {}
//    ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A mixin declaration must have a body, even if it is empty.
// [cfe] Expected an identifier, but got 'extension'.
