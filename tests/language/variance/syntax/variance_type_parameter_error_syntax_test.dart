// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests variance modifiers where they aren't allowed: more than one modifier
// on a type parameter, a modifier outside a type parameter list, and a
// modifier on a type parameter of an extension, a generic function or
// method, a type alias, or a generic function type.

// SharedOptions=--enable-experiment=variance

void A(out int foo) {
//     ^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CLASS
// [cfe] 'out' isn't a type.
// [cfe] Type 'out' not found.
//             ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ')' before this.
  List<out String> bar;
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '<' isn't defined for the type 'Type'.
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_UNQUALIFIED_NAME_READ
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  // [cfe] Undefined name 'out'.
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '>' isn't defined for the type 'Type'.
  //               ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_UNQUALIFIED_NAME_READ
  // [cfe] Undefined name 'bar'.
}

void B(out foo) {}
//     ^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CLASS
// [cfe] 'out' isn't a type.
// [cfe] Type 'out' not found.

class C<in out X, out out Y> {}
//         ^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_VARIANCE_MODIFIERS
// [cfe] Each type parameter can have at most one variance modifier.
//                    ^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_VARIANCE_MODIFIERS
// [cfe] Each type parameter can have at most one variance modifier.

class D<in out inout in out X> {}
//         ^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_VARIANCE_MODIFIERS
// [cfe] Each type parameter can have at most one variance modifier.
//             ^^^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_VARIANCE_MODIFIERS
// [cfe] Each type parameter can have at most one variance modifier.
//                   ^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_VARIANCE_MODIFIERS
// [cfe] Each type parameter can have at most one variance modifier.
//                      ^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_VARIANCE_MODIFIERS
// [cfe] Each type parameter can have at most one variance modifier.

typedef E<out T> = T Function(T a);
//        ^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
//            ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.

extension Extension<out T> on List<T> {}
//                  ^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
//                      ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.

void topLevelFunction<in T>() {}
//                    ^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
// [cfe] 'in' can't be used as an identifier because it's a keyword.
//                       ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.

class Methods {
  static void staticMethod<inout T>() {}
  //                       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
  //                             ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ',' before this.

  void instanceMethod<out T>() {}
  //                  ^^^
  // [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
  //                      ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ',' before this.
}

typedef NonFunctionAlias<out T> = List<T>;
//                       ^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
//                           ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.

typedef FunctionAlias<in T> = void Function(T);
//                    ^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
// [cfe] 'in' can't be used as an identifier because it's a keyword.
//                       ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.
//                        ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//                          ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [analyzer] SYNTACTIC_ERROR.MISSING_TYPEDEF_PARAMETERS
// [cfe] A typedef needs an explicit list of parameters.
// [cfe] Expected a declaration, but got '='.
//                                            ^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
// [cfe] Expected a function body or '=>'.

typedef void OldStyleFunctionAlias<inout T>(T x);
//                                 ^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
//                                       ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.

void Function<out T>()? genericFunctionType;
//            ^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
//                ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.

void main() {
  void localFunction<in T>() {}
  //   ^^^^^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
  //                 ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TYPE_NAME
  // [cfe] Expected a type, but got 'in'.
  // [cfe] This couldn't be parsed.
  //                      ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected '[' before this.
  // [cfe] The method 'call' isn't defined for the type 'List<invalid-type>'.
  //                       ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.

  var functionLiteral = <out T>() {};
  //                     ^^^
  // [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
  //                         ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ',' before this.
}
