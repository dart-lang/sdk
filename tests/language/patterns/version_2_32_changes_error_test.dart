// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns

// This test captures the changes introduced in 2.32 of the patterns proposal.

main() {
  // In a refutable context, it's an error for a variable in a variable pattern
  // to be named `when` or `as`.
  {
    switch (expr()) {
      case int when:
      //       ^^^^
      // [analyzer] unspecified
      // [cfe] unspecified
    }
    switch (expr()) {
      case int as:
      //       ^^
      // [analyzer] unspecified
      // [cfe] unspecified
    }
    switch (expr()) {
      case var when:
      //       ^^^^
      // [analyzer] unspecified
      // [cfe] unspecified
    }
    switch (expr()) {
      case var as:
      //       ^^
      // [analyzer] unspecified
      // [cfe] unspecified
    }
    switch (expr()) {
      case final int when:
      //             ^^^^
      // [analyzer] unspecified
      // [cfe] unspecified
    }
    switch (expr()) {
      case final int as:
      //             ^^
      // [analyzer] unspecified
      // [cfe] unspecified
    }
    switch (expr()) {
      case final when:
      //         ^^^^
      // [analyzer] unspecified
      // [cfe] unspecified
    }
    switch (expr()) {
      case final as:
      //         ^^
      // [analyzer] unspecified
      // [cfe] unspecified
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
      // [analyzer] unspecified
      // [cfe] unspecified
    }
    switch (expr()) {
      case as:
      //   ^^
      // [analyzer] unspecified
      // [cfe] unspecified
    }
  }

  // In a pattern variable declaration, it's an error for a variable in a
  // variable pattern to be named `when` or `as`.
  {
    var (int when) = expr<int>();
    //       ^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
  {
    var (int as) = expr<int>();
    //       ^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // In a pattern variable declaration, it's an error for an identifier pattern
  // to be named `when` or `as`.
  {
    var (when) = expr();
    //   ^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
  {
    var (as) = expr();
    //   ^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // In a pattern assignment, it's an error for an identifier pattern to be
  // named `when` or `as`.
  {
    Object? when;
    Object? as;

    (when) = expr();
//   ^^^^
// [analyzer] unspecified
// [cfe] unspecified
    (as) = expr();
//   ^^
// [analyzer] unspecified
// [cfe] unspecified
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
