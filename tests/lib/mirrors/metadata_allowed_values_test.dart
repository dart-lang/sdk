// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.metadata_allowed_values;

import 'dart:mirrors';
//     ^
// [web] Dart library 'dart:mirrors' is not available on this platform.
import 'package:expect/expect.dart';

import 'metadata_allowed_values_import.dart'; // Unprefixed.
import 'metadata_allowed_values_import.dart' as prefix;

   @A
// ^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_ANNOTATION_CONSTRUCTOR
//  ^
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
class A {}

   @E.NOT_CONSTANT
// ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ANNOTATION
//    ^
// [cfe] Constant evaluation error:
class E {
  static var NOT_CONSTANT = 3;
}

   @F(6)
// ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_ANNOTATION_CONSTRUCTOR
//  ^
// [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
class F {
  final field;
  F(this.field);
}

   @G.named(4)
// ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_ANNOTATION_CONSTRUCTOR
//  ^
// [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
class G {
  final field;
  G.named(this.field);
}

@I[0]
//^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got '['.
// ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got '0'.
//  ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got ']'.
class I {}

   @this.toString
// ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_ANNOTATION
//  ^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
// [cfe] 'this' can't be used as an identifier because it's a keyword.
//       ^
// [cfe] Member not found: 'this.toString'.
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
class J {}

   @super.toString
// ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_ANNOTATION
//  ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
// [cfe] 'super' can't be used as an identifier because it's a keyword.
//        ^
// [cfe] Member not found: 'super.toString'.
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
class K {}

   @L.func()
// ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ANNOTATION
//    ^
// [cfe] Couldn't find constructor 'L.func'.
class L {
  static func() => 6;
}

   @Imported
// ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS
//  ^
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
class M {}

   @prefix.Imported
// ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS
//         ^
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
class Q {}

   @U..toString()
//   ^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got '..'.
   class U {}
// ^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
// [cfe] Expected '{' before this.

   @V.tearOff
// ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ANNOTATION
//    ^
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
class V {
  static tearOff() {}
}

topLevelTearOff() => 4;

   @topLevelTearOff
// ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ANNOTATION
//  ^
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
class W {}

   @TypeParameter
// ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_ANNOTATION
//  ^
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
// [cfe] Undefined name 'TypeParameter'.
class X<TypeParameter> {}

   @TypeParameter.member
// ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_ANNOTATION
//                ^
// [cfe] Member not found: 'TypeParameter.member'.
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
class Y<TypeParameter> {}

   @1
// [error column 4]
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_ANNOTATION
//  ^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got '1'.
class Z {}

   @3.14
// [error column 4]
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_ANNOTATION
//  ^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got '3.14'.
class AA {}

   @'string'
// [error column 4]
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_ANNOTATION
//  ^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got ''string''.
class BB {}

   @#symbol
// ^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_ANNOTATION
//  ^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got '#'.
//   ^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Expected ';' after this.
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
// [cfe] This couldn't be parsed.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
class CC {}

   @['element']
//  ^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got '['.
//   ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got ''element''.
//            ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got ']'.
class DD {}

   @{'key': 'value'}
//  ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected a declaration, but got '{'.
// [cfe] Expected an identifier, but got '{'.
class EE {}

   @true
// ^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_ANNOTATION
//  ^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
// [cfe] 'true' can't be used as an identifier because it's a keyword.
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
// [cfe] Undefined name 'true'.
class FF {}

   @false
// ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_ANNOTATION
//  ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
// [cfe] 'false' can't be used as an identifier because it's a keyword.
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
// [cfe] Undefined name 'false'.
class GG {}

   @null
// ^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_ANNOTATION
//  ^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
// [cfe] 'null' can't be used as an identifier because it's a keyword.
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
// [cfe] Undefined name 'null'.
class HH {}

const a = const [1, 2, 3];

@a
class II {}

@a[0]
//^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got '['.
// ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got '0'.
//  ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got ']'.
class JJ {}

   @kk
// ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ANNOTATION
//  ^
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
class KK {
  const KK();
}

get kk => const KK();

@LL(() => 42)
//  ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [cfe] Not a constant expression.
class LL {
  final field;
  const LL(this.field);
}

@MM((x) => 42)
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [cfe] Not a constant expression.
class MM {
  final field;
  const MM(this.field);
}

@NN(() {})
//  ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [cfe] Not a constant expression.
class NN {
  final field;
  const NN(this.field);
}

@OO(() { () {} })
//  ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [cfe] Not a constant expression.
//       ^
// [cfe] Not a constant expression.
//           ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
class OO {
  final field;
  const OO(this.field);
}


main() {}

