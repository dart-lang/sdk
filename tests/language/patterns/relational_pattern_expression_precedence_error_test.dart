// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test certain expression types that are not allowed inside a relational
// pattern.

void usingEquals(x) {
  // relationalExpression
  if (x case == 1 < 2) {}
  //              ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case == 1 <= 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case == 1 > 2) {}
  //              ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case == 1 >= 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case == 1 is int) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case == 1 as int) {}
  //         ^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
  // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.

  // equalityExpression
  if (x case == 1 == 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case == 1 != 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.

  // ifNullExpression
  if (x case == 1 ?? 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.

  // conditionalExpression
  if (x case == true ? 1 : 2) {}
  //         ^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
  // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
  //                 ^
  // [analyzer] STATIC_WARNING.UNNECESSARY_NULL_CHECK_PATTERN
  //                   ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
}

void usingNotEquals(x) {
  // relationalExpression
  if (x case != 1 < 2) {}
  //              ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case != 1 <= 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case != 1 > 2) {}
  //              ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case != 1 >= 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case != 1 is int) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case != 1 as int) {}
  //         ^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
  // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.

  // equalityExpression
  if (x case != 1 == 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case != 1 != 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.

  // ifNullExpression
  if (x case != 1 ?? 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.

  // conditionalExpression
  if (x case != true ? 1 : 2) {}
  //         ^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
  // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
  //                 ^
  // [analyzer] STATIC_WARNING.UNNECESSARY_NULL_CHECK_PATTERN
  //                   ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
}

void usingLessThanOrEquals(x) {
  // relationalExpression
  if (x case <= 1 < 2) {}
  //              ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case <= 1 <= 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case <= 1 > 2) {}
  //              ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case <= 1 >= 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case <= 1 is int) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case <= 1 as int) {}
  //         ^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
  // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.

  // equalityExpression
  if (x case <= 1 == 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case <= 1 != 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.

  // ifNullExpression
  if (x case <= 1 ?? 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.

  // conditionalExpression
  if (x case <= true ? 1 : 2) {}
  //         ^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
  // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
  //            ^^^^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'bool' can't be assigned to the parameter type 'num'.
  //                 ^
  // [analyzer] STATIC_WARNING.UNNECESSARY_NULL_CHECK_PATTERN
  //                   ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
}

void usingLessThan(x) {
  // relationalExpression
  if (x case < 1 < 2) {}
  //             ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case < 1 <= 2) {}
  //             ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case < 1 > 2) {}
  //             ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case < 1 >= 2) {}
  //             ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case < 1 is int) {}
  //             ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case < 1 as int) {}
  //         ^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
  // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.

  // equalityExpression
  if (x case < 1 == 2) {}
  //             ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case < 1 != 2) {}
  //             ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.

  // ifNullExpression
  if (x case < 1 ?? 2) {}
  //             ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.

  // conditionalExpression
  if (x case < true ? 1 : 2) {}
  //         ^^^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
  // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
  //           ^^^^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'bool' can't be assigned to the parameter type 'num'.
  //                ^
  // [analyzer] STATIC_WARNING.UNNECESSARY_NULL_CHECK_PATTERN
  //                  ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
}

void usingGreaterThanOrEquals(x) {
  // relationalExpression
  if (x case >= 1 < 2) {}
  //              ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case >= 1 <= 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case >= 1 > 2) {}
  //              ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case >= 1 >= 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case >= 1 is int) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case >= 1 as int) {}
  //         ^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
  // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.

  // equalityExpression
  if (x case >= 1 == 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case >= 1 != 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.

  // ifNullExpression
  if (x case >= 1 ?? 2) {}
  //              ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.

  // conditionalExpression
  if (x case >= true ? 1 : 2) {}
  //         ^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
  // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
  //            ^^^^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'bool' can't be assigned to the parameter type 'num'.
  //                 ^
  // [analyzer] STATIC_WARNING.UNNECESSARY_NULL_CHECK_PATTERN
  //                   ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
}

void usingGreaterThan(x) {
  // relationalExpression
  if (x case > 1 < 2) {}
  //             ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case > 1 <= 2) {}
  //             ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case > 1 > 2) {}
  //             ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case > 1 >= 2) {}
  //             ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case > 1 is int) {}
  //             ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case > 1 as int) {}
  //         ^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
  // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.

  // equalityExpression
  if (x case > 1 == 2) {}
  //             ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
  if (x case > 1 != 2) {}
  //             ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.

  // ifNullExpression
  if (x case > 1 ?? 2) {}
  //             ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.

  // conditionalExpression
  if (x case > true ? 1 : 2) {}
  //         ^^^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
  // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
  //           ^^^^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'bool' can't be assigned to the parameter type 'num'.
  //                ^
  // [analyzer] STATIC_WARNING.UNNECESSARY_NULL_CHECK_PATTERN
  //                  ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.
}

main() {}
