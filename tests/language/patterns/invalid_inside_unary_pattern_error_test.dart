// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that errors are generated if a unary pattern or a relational pattern
// appears inside a unary pattern.  This is prohibited by the patterns grammar,
// but accepted by the parser's precedence-based parsing logic (because it's not
// actually ambiguous), so the parser has special logic to detect the error
// condition.

test_cast_insideCast(x) {
  switch (x) {
    case _ as int as num:
    //   ^^^^^^^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
    // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}

test_cast_insideNullAssert(x) {
  switch (x) {
    case _ as int!:
    //   ^^^^^^^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
    // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}

test_cast_insideNullCheck(x) {
  switch (x) {
    case _ as int? ?:
    //   ^^^^^^^^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
    // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}

test_nullAssert_insideCast(x) {
  switch (x) {
    case _! as num?:
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
    // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}

test_nullAssert_insideNullAssert(x) {
  switch (x) {
    case _!!:
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
    // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}

test_nullAssert_insideNullCheck(x) {
  switch (x) {
    case _!?:
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
    // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}

test_nullCheck_insideCast(x) {
  switch (x) {
    case _? as num?:
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
    // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}

test_nullCheck_insideNullAssert(x) {
  switch (x) {
    case _?!:
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
    // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}

test_nullCheck_insideNullCheck(x) {
  switch (x) {
    case _? ?:
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
    // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}

test_relational_insideNullCheck_equal(x) {
  switch (x) {
    case == 1?:
    //   ^^^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
    // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}

test_relational_insideNullCheck_greaterThan(x) {
  switch (x) {
    case > 1?:
    //   ^^^
    // [analyzer] SYNTACTIC_ERROR.INVALID_INSIDE_UNARY_PATTERN
    // [cfe] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}

main() {}
