// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=records,patterns

import 'invalid_const_pattern_test.dart' as prefix;

const int value = 42;

void func() {}

class Class {
  const Class([a]);

  const Class.named();

  call() {}

  test(o) async {
    const dynamic local = 0;
    dynamic variable = 0;
    switch (o) {
      case true: // Ok
      case null: // Ok
      case this: // Error
      //   ^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      // [cfe] Not a constant expression.
      case this(): // Error
      //   ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      // [cfe] Not a constant expression.
      case super(): // Error
      //   ^^^^^
      // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
      //   ^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      // [cfe] Method invocation is not a constant expression.
      case 42: // Ok
      case -42: // Ok
      case 42.5: // Ok
      case -42.5: // Ok
      case 'foo': // Ok
      case 'foo' 'bar': // Ok
      case value: // Ok
      case value!: // Ok
      case value?: // Ok
      case value as int: // Ok
      case -value: // Error
      //    ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_NEGATION
      // [cfe] Only negation of a numeric literal is supported as a constant pattern.
      case local: // Ok
      case -local: // Error
      //    ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_NEGATION
      // [cfe] Only negation of a numeric literal is supported as a constant pattern.
      case func: // Ok
      case prefix.value: // Ok
      case -prefix.value: // Error
      //    ^^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_NEGATION
      // [cfe] Only negation of a numeric literal is supported as a constant pattern.
      //           ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_NEGATION
      // [cfe] Only negation of a numeric literal is supported as a constant pattern.
      case prefix.Class.named: // Ok
      case 1 + 2: // Error
      //     ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
      // [cfe] The binary operator + is not supported as a constant pattern.
      case 1 * 2: // Error
      //     ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
      // [cfe] The binary operator * is not supported as a constant pattern.
      case void fun() {}: // Error
      //           ^
      // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
      // [cfe] Expected ':' before this.
      //               ^
      // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
      // [cfe] Expected ';' after this.
      //                ^
      // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
      // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
      // [cfe] Expected an identifier, but got ':'.
      // [cfe] Unexpected token ':'.
      case assert(false): // Error
      //   ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
      //   ^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      // [cfe] `assert` can't be used as an expression.
      case switch (o) { _ => true }: // Error
      //   ^^^^^^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      // [cfe] Not a constant expression.
      //           ^
      // [cfe] Not a constant expression.
      case await 0: // Error
      //   ^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      // [cfe] Not a constant expression.
      case !false: // Error
      //   ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_UNARY
      // [cfe] The unary operator ! is not supported as a constant pattern.
      case ~0: // Error
      //   ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_UNARY
      // [cfe] The unary operator ~ is not supported as a constant pattern.
      case ++variable: // Error
      //   ^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      //     ^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      // [cfe] Not a constant expression.
      case const 0: // Error
      //         ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const 0x0: // Error
      //         ^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const 0.5: // Error
      //         ^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const true: // Error
      //         ^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const null: // Error
      //         ^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const -0: // Error
      //         ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const 'foo': // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const #a: // Error
      //         ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const value: // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const local: // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const prefix.value: // Error
      //                ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const -prefix.value: // Error
      //         ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const prefix.Class.named: // Error
      //                      ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const 1 + 2: // Error
      //         ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
      // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
      case const void fun() {}: // Error
      //         ^
      // [cfe] Not a constant expression.
      //              ^^^
      // [analyzer] SYNTACTIC_ERROR.NAMED_FUNCTION_EXPRESSION
      // [cfe] A function expression can't have a name.
      //                 ^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      case const assert(false): // Error
      //         ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
      //         ^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      // [cfe] `assert` can't be used as an expression.
      case const switch (o) { _ => true }: // Error
      //         ^^^^^^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      // [cfe] Not a constant expression.
      //                 ^
      // [cfe] Not a constant expression.
      case const await 0: // Error
      //         ^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      // [cfe] Not a constant expression.
      case const !false: // Error
      //         ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_UNARY
      // [cfe] The unary operator ! is not supported as a constant pattern.
      case const ~0: // Error
      //         ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_UNARY
      // [cfe] The unary operator ~ is not supported as a constant pattern.
      case const ++variable: // Error
      //         ^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      //           ^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      // [cfe] Not a constant expression.
      case const Class(): // Ok
      case const Class(0): // Ok
      case const GenericClass(): // Ok
      case const GenericClass(a: 0): // Ok
      case const GenericClass<int>(): // Ok
      case const GenericClass<int>(a: 0): // Ok
      case const GenericClass<int>.new(): // Ok
      case const GenericClass<int>.new(a: 1): // Ok
      case const []: // Ok
      case const <int>[]: // Ok
      case const {}: // Ok
      case const <int, String>{}: // Ok
      case const const Class(): // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_DUPLICATE_CONST
      // [cfe] Duplicate 'const' keyword in constant expression.
      case const const Class(0): // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_DUPLICATE_CONST
      // [cfe] Duplicate 'const' keyword in constant expression.
      case const const GenericClass(): // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_DUPLICATE_CONST
      // [cfe] Duplicate 'const' keyword in constant expression.
      case const const GenericClass(a: 0): // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_DUPLICATE_CONST
      // [cfe] Duplicate 'const' keyword in constant expression.
      case const const GenericClass<int>(): // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_DUPLICATE_CONST
      // [cfe] Duplicate 'const' keyword in constant expression.
      case const const GenericClass<int>(a: 0): // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_DUPLICATE_CONST
      // [cfe] Duplicate 'const' keyword in constant expression.
      case const const []: // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_DUPLICATE_CONST
      // [cfe] Duplicate 'const' keyword in constant expression.
      case const const <int>[]: // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_DUPLICATE_CONST
      // [cfe] Duplicate 'const' keyword in constant expression.
      case const const {}: // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_DUPLICATE_CONST
      // [cfe] Duplicate 'const' keyword in constant expression.
      case const const <int, String>{}: // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_DUPLICATE_CONST
      // [cfe] Duplicate 'const' keyword in constant expression.
      case const new Class(): // Error
      //         ^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      // [cfe] New expression is not a constant expression.
      //             ^
      // [cfe] New expression is not a constant expression.
      case new Class(): // Error
      //   ^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
      // [cfe] New expression is not a constant expression.
      //       ^
      // [cfe] New expression is not a constant expression.
      case const (): // Error
      //         ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_EMPTY_RECORD_LITERAL
      // [cfe] The empty record literal is not supported as a constant pattern.
      case const const (): // Error
      //         ^^^^^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_DUPLICATE_CONST
      // [cfe] Duplicate 'const' keyword in constant expression.
      case const (1): // Ok
      case const (-1): // Ok
      case const (value): // Ok
      case const (-value): // Ok
      case const (1 + 2): // Ok
      case GenericClass<int>: // Error
      //               ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_GENERIC
      // [cfe] This expression is not supported as a constant pattern.
      case prefix.GenericClass<int>: // Error
      //                      ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_GENERIC
      // [cfe] This expression is not supported as a constant pattern.
      case GenericClass<int>.new: // Error
      //               ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_GENERIC
      // [cfe] This expression is not supported as a constant pattern.
      case prefix.GenericClass<int>.new: // Error
      //                      ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_GENERIC
      // [cfe] This expression is not supported as a constant pattern.
      case const GenericClass<int>: // Error
      //                     ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_GENERIC
      // [cfe] This expression is not supported as a constant pattern.
      case const prefix.GenericClass<int>: // Error
      //                            ^
      // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_GENERIC
      // [cfe] This expression is not supported as a constant pattern.
      case const (GenericClass<int>): // Ok
      case const (prefix.GenericClass<int>): // Ok
      case const (GenericClass<int>.new): // Ok
      case const (prefix.GenericClass<int>.new): // Ok
       print(0);
    }
  }
}

class GenericClass<T> {
  const GenericClass({a});
}
