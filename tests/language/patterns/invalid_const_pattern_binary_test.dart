// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=records,patterns

import 'invalid_const_pattern_binary_test.dart' as prefix;

const value = 1;

class Class {
  static const value = 2;
}

method<T>(o) {
  switch (o) {
    case 1 || 2: // Ok
    case 1 && 2: // Ok
    case 1 as T: // Ok
    case const Object(): // Ok
    case 1 + 2: // Error
    //     ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator + is not supported as a constant pattern.
    case 1 - 2: // Error
    //     ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator - is not supported as a constant pattern.
    case 1 * 2: // Error
    //     ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator * is not supported as a constant pattern.
    case 1 / 2: // Error
    //     ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator / is not supported as a constant pattern.
    case 1 ~/ 2: // Error
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator ~/ is not supported as a constant pattern.
    case 1 % 2: // Error
    //     ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator % is not supported as a constant pattern.
    case 1 == 2: // Error
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator == is not supported as a constant pattern.
    case 1 != 2: // Error
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator != is not supported as a constant pattern.
    case 1 ^ 2: // Error
    //     ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator ^ is not supported as a constant pattern.
    case 1 & 2: // Error
    //     ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator & is not supported as a constant pattern.
    case 1 | 2: // Error
    //     ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator | is not supported as a constant pattern.
    case 1 < 2: // Error
    //     ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator < is not supported as a constant pattern.
    case 1 <= 2: // Error
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator <= is not supported as a constant pattern.
    case 1 > 2: // Error
    //     ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator > is not supported as a constant pattern.
    case 1 >= 2: // Error
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator >= is not supported as a constant pattern.
    case 1 << 2: // Error
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator << is not supported as a constant pattern.
    case 1 >> 2: // Error
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator >> is not supported as a constant pattern.
    case 1 >>> 2: // Error
    //     ^^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator >>> is not supported as a constant pattern.
    case 1 + 2 + 3: // Error
    //     ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_PATTERN_BINARY
    // [cfe] The binary operator + is not supported as a constant pattern.
    case prefix.value as T: // Ok
    case prefix.Class.value as T: // Ok
    case const 1 as int: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 + 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 - 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 * 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 / 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 ~/ 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 % 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 == 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 != 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 ^ 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 & 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 | 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 < 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 <= 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 > 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 >= 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 << 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 >> 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 >>> 2: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const 1 + 2 + 3: // Error
    //         ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const Object() == 2: // Error
    //                ^
    // [analyzer] SYNTACTIC_ERROR.INVALID_CONSTANT_CONST_PREFIX
    // [cfe] The expression can't be prefixed by 'const' to form a constant pattern.
    case const <int>[] as List<T>: // Ok
    case const (1 + 2): // Ok
    case const (1 - 2): // Ok
    case const (1 * 2): // Ok
    case const (1 / 2): // Ok
    case const (1 ~/ 2): // Ok
    case const (1 % 2): // Ok
    case const (1 == 2): // Ok
    case const (1 != 2): // Ok
    case const (1 ^ 2): // Ok
    case const (1 & 2): // Ok
    case const (1 | 2): // Ok
    case const (1 < 2): // Ok
    case const (1 <= 2): // Ok
    case const (1 > 2): // Ok
    case const (1 >= 2): // Ok
    case const (1 << 2): // Ok
    case const (1 >> 2): // Ok
    case const (1 >>> 2): // Ok
    case const (1 + 2 + 3): // Ok
    case 1 ?? 2: // Error
    //     ^^
    // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
    // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
    // [cfe] Expected ':' before this.
    // [cfe] Expected an identifier, but got '??'.
    //        ^
    // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
    // [cfe] Expected ';' after this.
    //         ^
    // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
    // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
    // [cfe] Expected an identifier, but got ':'.
    // [cfe] Unexpected token ':'.
    case o++: // Error
    //   ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    //   ^^^
    // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
    // [cfe] Not a constant expression.
    case o--: // Error
    //   ^^^
    // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
    // [cfe] Not a constant expression.
    //    ^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
    case ++o: // Error
    //   ^^^
    // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
    // [cfe] Not a constant expression.
    case --o: // Error
    //   ^^^
    // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION
    // [cfe] Not a constant expression.
  }
}
