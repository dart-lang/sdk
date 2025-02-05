// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



import "package:expect/expect.dart";

// Tests that `Classname.new` is allowed and works
// only as an alias for the unnamed constructor.
// It cannot be used to declare any other member.
// It's not allowed as a reference if there is no unnamed constructor.

// Not allowed without class prefix as constructor.
class C1 {
  const new();
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_INSTANCE_FIELD
  // [cfe] Only static fields can be declared as const.
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_NOT_INITIALIZED
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] 'new' can't be used as an identifier because it's a keyword.
  // [cfe] Expected ';' after this.
  // [cfe] The const variable 'new' must be initialized.
  //       ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  //       ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
  // [cfe] Expected an identifier, but got '('.
}

class C2 {
  factory new() => C2._();
  // [error column 3, length 7]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
  // [cfe] Expected ';' after this.
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
  //      ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_CLASS_MEMBER
  // [cfe] Expected a class member, but got 'new'.
  //         ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] Expected an identifier, but got '('.
  C2._();
}

// Not allowed as normal member.
class C3 {
  int new() => 1;
  //  ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'new' can't be used as an identifier because it's a keyword.
}

class C4 {
  int get new => 1;
  //      ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'new' can't be used as an identifier because it's a keyword.

  void set new(int value) {}
  //       ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'new' can't be used as an identifier because it's a keyword.
}

class C5 {
  int new = 1;
  //  ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'new' can't be used as an identifier because it's a keyword.
}

// Not allowed as static member.
class C6 {
  static void new() {}
  //          ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] 'new' can't be used as an identifier because it's a keyword.
  // [cfe] Expected ';' after this.
  //             ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] Expected an identifier, but got '('.
}

class C7 {
  static int get new => 42;
  //             ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'new' can't be used as an identifier because it's a keyword.

  static void set new(int x) {}
  //              ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'new' can't be used as an identifier because it's a keyword.
}

class C8 {
  static int new = 1;
  //         ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'new' can't be used as an identifier because it's a keyword.
}

// Not allowed as reference if there is no unnamed constructor.

// Class with no unnamed constructor.
class NoUnnamed<T> {
  NoUnnamed.named();

  NoUnnamed.genRedir() : this.new();
  //                     ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR
  //                          ^
  // [cfe] Couldn't find constructor 'NoUnnamed.new'.

  factory NoUnnamed.facRedir() = NoUnnamed.new;
  //                             ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_MISSING_CONSTRUCTOR
  // [cfe] Redirection constructor target not found: 'NoUnnamed.new'

  factory NoUnnamed.facRedir2() = NoUnnamed<T>.new;
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_MISSING_CONSTRUCTOR
  // [cfe] Couldn't find constructor 'NoUnnamed.new'.
  // [cfe] Redirection constructor target not found: 'NoUnnamed.new'
}

class SubNoUnnamed extends NoUnnamed<int> {
  SubNoUnnamed() : super.new();
  //               ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER
  // [cfe] Superclass has no constructor named 'NoUnnamed.new'.
}

void main() {
  NoUnnamed.new();
  //        ^^^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
  // [cfe] Member not found: 'NoUnnamed.new'.

  NoUnnamed<int>.new();
  //             ^^^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR
  // [cfe] Couldn't find constructor 'NoUnnamed.new'.
}
