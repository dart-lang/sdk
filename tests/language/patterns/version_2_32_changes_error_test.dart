// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test captures the changes introduced in 2.32 of the patterns proposal.

main() {
  // In a refutable context, it's an error for a variable in a variable pattern
  // to be named `when` or `as`.
  {
    switch (expr()) {
      case int when:
      //           ^
      // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
      // [cfe] Expected an identifier, but got ':'.
    }
    switch (expr()) {
      case int as:
      //         ^
      // [analyzer] SYNTACTIC_ERROR.EXPECTED_TYPE_NAME
      // [cfe] Expected a type, but got ':'.
      // [cfe] This couldn't be parsed.
    }
    switch (expr()) {
      case var when:
      //       ^^^^
      // [analyzer] SYNTACTIC_ERROR.ILLEGAL_PATTERN_VARIABLE_NAME
      // [cfe] The variable declared by a variable pattern can't be named 'when'.
    }
    switch (expr()) {
      case var as:
      //       ^^
      // [analyzer] SYNTACTIC_ERROR.ILLEGAL_PATTERN_VARIABLE_NAME
      // [cfe] The variable declared by a variable pattern can't be named 'as'.
    }
    switch (expr()) {
      case final int when:
      //                 ^
      // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
      // [cfe] Expected an identifier, but got ':'.
    }
    switch (expr()) {
      case final int as:
      //               ^
      // [analyzer] SYNTACTIC_ERROR.EXPECTED_TYPE_NAME
      // [cfe] Expected a type, but got ':'.
      // [cfe] This couldn't be parsed.
    }
    switch (expr()) {
      case final when:
      //         ^^^^
      // [analyzer] SYNTACTIC_ERROR.ILLEGAL_PATTERN_VARIABLE_NAME
      // [cfe] The variable declared by a variable pattern can't be named 'when'.
    }
    switch (expr()) {
      case final as:
      //         ^^
      // [analyzer] SYNTACTIC_ERROR.ILLEGAL_PATTERN_VARIABLE_NAME
      // [cfe] The variable declared by a variable pattern can't be named 'as'.
    }
  }

  // In a refutable context, it's an error for an identifier pattern to be named
  // `when` or `as`.
  {
    const when = 0;
    const as = 1;

    switch (expr()) {
      case when:
      //   ^^^^
      // [analyzer] SYNTACTIC_ERROR.ILLEGAL_PATTERN_IDENTIFIER_NAME
      // [cfe] A pattern can't refer to an identifier named 'when'.
    }
    switch (expr()) {
      case as:
      //   ^^
      // [analyzer] SYNTACTIC_ERROR.ILLEGAL_PATTERN_IDENTIFIER_NAME
      // [cfe] A pattern can't refer to an identifier named 'as'.
    }
  }

  // However, `const (when)` and `const (as)` are still permitted.
  {
    const when = 0;
    const as = 1;

    switch (expr()) {
      case const (when):
    }
    switch (expr()) {
      case const (as):
    }
  }

  // And `== when` and `== as` are still permitted.
  {
    const when = 0;
    const as = 1;

    switch (expr()) {
      case == when:
    }
    switch (expr()) {
      case == as:
    }
  }

  // In a pattern variable declaration, it's an error for a variable in a
  // variable pattern to be named `when` or `as`.
  {
    var (int when) = expr<int>();
    //       ^^^^
    // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
    // [cfe] Expected ')' before this.
    //                    ^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
    // [cfe] Local variable 'int' can't be referenced before it is declared.
  }
  {
    var (int as) = expr<int>();
    //         ^
    // [analyzer] SYNTACTIC_ERROR.EXPECTED_TYPE_NAME
    // [cfe] Expected a type, but got ')'.
    // [cfe] This couldn't be parsed.
    //                  ^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
    // [cfe] Local variable 'int' can't be referenced before it is declared.
  }

  // In a pattern variable declaration, it's an error for an identifier pattern
  // to be named `when` or `as`.
  {
    var (when) = expr();
    //   ^^^^
    // [analyzer] SYNTACTIC_ERROR.ILLEGAL_PATTERN_VARIABLE_NAME
    // [cfe] The variable declared by a variable pattern can't be named 'when'.
  }
  {
    var (as) = expr();
    //   ^^
    // [analyzer] SYNTACTIC_ERROR.ILLEGAL_PATTERN_VARIABLE_NAME
    // [cfe] The variable declared by a variable pattern can't be named 'as'.
  }

  // In a pattern assignment, it's an error for an identifier pattern to be
  // named `when` or `as`.
  {
    Object? when;
    Object? as;

    (when) = expr();
//   ^^^^
// [analyzer] SYNTACTIC_ERROR.ILLEGAL_PATTERN_ASSIGNMENT_VARIABLE_NAME
// [cfe] A variable assigned by a pattern assignment can't be named 'when'.
    (as) = expr();
//   ^^
// [analyzer] SYNTACTIC_ERROR.ILLEGAL_PATTERN_ASSIGNMENT_VARIABLE_NAME
// [cfe] A variable assigned by a pattern assignment can't be named 'as'.
  }

  // It is, however, ok for `when` or `as` to appear as part of a qualified name
  // in a constant pattern, provided it's not otherwise prohibited by the
  // grammar (e.g. `as` can't be used as a prefix because it's a builtin).
  {
    switch (expr()) {
      case C.when:
    }

    switch (expr()) {
      case when.as:
    }
  }

  // And it is ok for `when` to be used as the type of a variable or wildcard
  // pattern, or as the type of an object pattern.  (`as` can't be used in this
  // way because it's not the legal name of a type).
  {
    switch (expr()) {
      case when _:
    }

    switch (expr()) {
      case when w:
    }

    switch (expr()) {
      case when():
    }
  }
}

T expr<T>() => throw UnimplementedError();

class C {
  static const when = 0;
}

class when {
  static const as = 1;
}
