// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// To avoid having tests for the cross product of declaration forms and control
/// flow constructs, the tests in this directory are split into tests that check
/// that each different kind of variable declaration is treated appropriately
/// with respect to errors and warnings for a single control flow construct; and
/// tests that check that a reasonable subset of the possible control flow
/// patterns produce the expected definite (un)-assignment behavior.
///
/// This test checks the the write component of the former.  That is, it tests
/// errors associated with writes of local variables based on definite
/// assignment.

void use(Object? x) {}

/// Test that it is never an error to write to a definitely unassigned local
/// variable.
void testDefinitelyUnassignedWrites<T>(T t) {
  {
    var x;
    x = 3;
  }

  {
    final x;
    x = 3;
  }

  {
    int x;
    x = 3;
  }

  {
    int? x;
    x = 3;
  }

  {
    final int x;
    x = 3;
  }

  {
    final int? x;
    x = 3;
  }

  {
    final T x;
    x = t;
  }

  {
    late var x;
    x = 3;
  }

  {
    late int x;
    x = 3;
  }

  {
    late int? x;
    x = 3;
  }

  {
    late T x;
    x = t;
  }

  {
    late final x;
    x = 3;
  }

  {
    late final int x;
    x = 3;
  }

  {
    late final int? x;
    x = 3;
  }

  {
    late final T x;
    x = t;
  }
}

/// Test that writing to a potentially unassigned variable gives the correct
/// error for each kind of variable.
void testPotentiallyUnassignedWrites<T>(bool b, T t) {
  // It is a compile time error to assign a value to a `final`, non-`late` local
  // variable which is **potentially assigned**.  Thus, it is *not* a compile
  // time error to assign to a **definitely unassigned** `final` local variable.

  // Ok: not final.
  {
    var x;
    int y = 3;
    if (b) {
      x = y;
    }
    x = 3;
  }

  // Error: final.
  {
    final x;
    int y = 3;
    if (b) {
      x = y;
    }
    x = y;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Ok: not final.
  {
    int x;
    int y = 3;
    if (b) {
      x = y;
    }
    x = y;
  }

  // Ok: not final.
  {
    int? x;
    int y = 3;
    if (b) {
      x = y;
    }
    x = y;
  }

  // Error: final.
  {
    final int x;
    int y = 3;
    if (b) {
      x = y;
    }
    x = y;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: final.
  {
    final int? x;
    int y = 3;
    if (b) {
      x = y;
    }
    x = y;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: final.
  {
    final T x;
    T y = t;
    if (b) {
      x = y;
    }
    x = y;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Ok: late.
  {
    late var x;
    int y = 3;
    if (b) {
      x = y;
    }
    x = y;
  }

  // Ok: late.
  {
    late int x;
    int y = 3;
    if (b) {
      x = y;
    }
    x = y;
  }

  // Ok: late.
  {
    late int? x;
    int y = 3;
    if (b) {
      x = y;
    }
    x = y;
  }

  // Ok: late.
  {
    late T x;
    T y = t;
    if (b) {
      x = y;
    }
    x = y;
  }

  // Ok: late.
  {
    late final x;
    int y = 3;
    if (b) {
      x = y;
    }
    x = y;
  }

  // Ok: late.
  {
    late final int x;
    int y = 3;
    if (b) {
      x = y;
    }
    x = y;
  }

  // Ok: late.
  {
    late final int? x;
    int y = 3;
    if (b) {
      x = y;
    }
    x = y;
  }

  // Ok: late.
  {
    late final T x;
    T y = t;
    if (b) {
      x = y;
    }
    x = y;
  }
}

/// Test that writing to a definitely assigned variable gives the correct
/// error for each kind of variable.
void testDefinitelyAssignedWrites<T>(T t) {
  // It is a compile time error to assign a value to a `final`, non-`late` local
  // variable which is **potentially assigned**.  Thus, it is *not* a compile
  // time error to assign to a **definitely unassigned** `final` local variable.

  // It is a compile time error to assign a value to a `final`, `late` local
  // variable if it is **definitely assigned**. Thus, it is *not* a compile time
  // error to assign to a **potentially unassigned** `final`, `late` local
  // variable.

  // Ok: not final, not late.
  {
    var x;
    int y = 3;
    x = y;
    x = y;
  }

  // Error: final.
  {
    final x;
    int y = 3;
    x = y;
    x = y;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified

  }

  // Ok: not final, not late.
  {
    int x;
    int y = 3;
    x = y;
    x = y;
  }

  // Ok: not final, not late.
  {
    int? x;
    int y = 3;
    x = y;
    x = y;
  }

  // Error: final.
  {
    final int x;
    int y = 3;
    x = y;
    x = y;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: final.
  {
    final int? x;
    int y = 3;
    x = y;
    x = y;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: final.
  {
    final T x;
    T y = t;
    x = y;
    x = y;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Ok: not final.
  {
    late var x;
    int y = 3;
    x = y;
    x = y;
  }

  // Ok: not final.
  {
    late int x;
    int y = 3;
    x = y;
    x = y;
  }

  // Ok: not final.
  {
    late int? x;
    int y = 3;
    x = y;
    x = y;
  }

  // Ok: not final.
  {
    late T x;
    T y = t;
    x = y;
    x = y;
  }

  // Error: final and late.
  {
    late final x;
    int y = 3;
    x = y;
    x = y;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: final and late.
  {
    late final int x;
    int y = 3;
    x = y;
    x = y;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified

  }

  // Error: final and late.
  {
    late final int? x;
    int y = 3;
    x = y;
    x = y;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: final and late.
  {
    late final T x;
    T y = t;
    x = y;
    x = y;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

/// Test that a write to a definitely unassigned variable gives no error for a
/// single choice of declaration form, across a range of write constructs.  Note
/// that some constructs in this test also involve reads, and hence may generate
/// read errors.  The expectations should reflect this.
void testDefinitelyUnassignedWriteForms() {
  {
    final dynamic x;
    x = 3;
  }

  {
    final dynamic x;
    use(x = 3);
  }

  {
    final dynamic x;
    // Should be a read error only
    x++;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    // Should be a read error only
    ++x;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    // Should be a read error only
    x += 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    // Should be a read error only
    x ??= 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

/// Test that a write to a potentially unassigned variable gives the correct
/// error for a single choice of declaration form, across a range of write
/// constructs.
void testPotentiallyUnassignedWriteForms(bool b) {
  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    x = 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    use(x = 3);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    // Expect both a read and write error
    x++;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    // Expect both a read and write error
    ++x;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    // Expect both a read and write error
    x += 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    // Expect both a read and write error
    x ??= 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

/// Test that a write to a definitely assigned variable gives the correct
/// error for a single choice of declaration form, across a range of write
/// constructs.
void testDefinitelyAssignedWriteForms() {
  {
    final dynamic x;
    x = 3;
    x = 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x = 3;
    use(x = 3);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x = 3;
    x++;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x = 3;
    ++x;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x = 3;
    x += 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x = 3;
    x ??= 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

void main() {
  testDefinitelyUnassignedWrites<int>(0);
  testPotentiallyUnassignedWrites<int>(true, 0);
  testDefinitelyAssignedWrites<int>(0);
  testDefinitelyUnassignedWriteForms();
  testPotentiallyUnassignedWriteForms(true);
  testDefinitelyAssignedWriteForms();
}
