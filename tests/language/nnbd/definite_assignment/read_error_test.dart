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
/// This test checks the the read component of the former.  That is, it tests
/// errors associated with reads of local variables based on definite
/// assignment.

void use(Object? x) {}

/// Test that a read of a definitely unassigned variable gives the correct error
/// for each kind of variable.
void testDefinitelyUnassignedReads<T>() {
  // It is a compile time error to read a local variable when the variable is
  // **definitely unassigned** unless the variable is non-`final`, and
  // non-`late`, and has nullable type.

  // Ok: non-final and nullably typed.
  {
    var x;
    use(x);
  }

  // Error: final.
  {
    final x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: not nullable.
  {
    int x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Ok: non-final and nullably typed.
  {
    int? x;
    use(x);
  }

  // Error: final and not nullable.
  {
    final int x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: final.
  {
    final int? x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: final and not nullable.
  {
    final T x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: late
  {
    late var x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: late and not nullable
  {
    late int x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: late
  {
    late int? x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: late and not nullable
  {
    late T x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: late and final
  {
    late final x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: late and final and not nullable
  {
    late final int x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: late and final
  {
    late final int? x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: late and final and not nullable
  {
    late final T x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

/// Test that a read of a potentially unassigned variable gives the correct
/// error for each kind of variable.
void testPotentiallyUnassignedReads<T>(bool b, T t) {
  //  It is a compile time error to read a local variable when the variable is
  //  **potentially unassigned** unless the variable is non-final and has
  //  nullable type, or is `late`.

  // Ok: non-final and nullable.
  {
    var x;
    int y = 3;
    if (b) {
      x = y;
    }
    use(x);
  }

  // Error: final.
  {
    final x;
    int y = 3;
    if (b) {
      x = y;
    }
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: not nullable.
  {
    int x;
    int y = 3;
    if (b) {
      x = y;
    }
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Ok: non-final and nullable.
  {
    int? x;
    int y = 3;
    if (b) {
      x = y;
    }
    use(x);
  }

  // Error: final and not nullable.
  {
    final int x;
    int y = 3;
    if (b) {
      x = y;
    }
    use(x);
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
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Error: final and not nullable.
  {
    final T x;
    T y = t;
    if (b) {
      x = y;
    }
    use(x);
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
    use(x);
  }

  // Ok: late.
  {
    late int x;
    int y = 3;
    if (b) {
      x = y;
    }
    use(x);
  }

  // Ok: late.
  {
    late int? x;
    int y = 3;
    if (b) {
      x = y;
    }
    use(x);
  }

  // Ok: late.
  {
    late T x;
    T y = t;
    if (b) {
      x = y;
    }
    use(x);
  }

  // Ok: late.
  {
    late final x;
    int y = 3;
    if (b) {
      x = y;
    }
    use(x);
  }

  // Ok: late.
  {
    late final int x;
    int y = 3;
    if (b) {
      x = y;
    }
    use(x);
  }

  // Ok: late.
  {
    late final int? x;
    int y = 3;
    if (b) {
      x = y;
    }
    use(x);
  }

  // Ok: late.
  {
    late final T x;
    T y = t;
    if (b) {
      x = y;
    }
    use(x);
  }
}

/// Test that reading a definitely assigned variable is not an error.
void testDefinitelyAssignedReads<T>(T t) {
  // It is never an error to read a definitely assigned variable.

  {
    var x;
    int y = 3;
    x = y;
    use(x);
  }

  {
    final x;
    int y = 3;
    x = y;
    use(x);
  }

  {
    int x;
    int y = 3;
    x = y;
    use(x);
  }

  {
    int? x;
    int y = 3;
    x = y;
    use(x);
  }

  {
    final int x;
    int y = 3;
    x = y;
    use(x);
  }

  {
    final int? x;
    int y = 3;
    x = y;
    use(x);
  }

  {
    final T x;
    T y = t;
    x = y;
    use(x);
  }

  {
    late var x;
    int y = 3;
    x = y;
    use(x);
  }

  {
    late int x;
    int y = 3;
    x = y;
    use(x);
  }

  {
    late int? x;
    int y = 3;
    x = y;
    use(x);
  }

  {
    late T x;
    T y = t;
    x = y;
    use(x);
  }

  {
    late final x;
    int y = 3;
    x = y;
    use(x);
  }

  {
    late final int x;
    int y = 3;
    x = y;
    use(x);
  }

  {
    late final int? x;
    int y = 3;
    x = y;
    use(x);
  }

  {
    late final T x;
    T y = t;
    x = y;
    use(x);
  }
}

/// Test that a read of a definitely unassigned variable gives the correct error
/// for a single choice of declaration form, across a range of read constructs.
///
/// These tests declare a `final` variable of type `dynamic` with no initializer
/// and no assignments, and test that it is an error to use the variable
/// in a variety of syntactic positions.
void testDefinitelyUnassignedReadForms() {
  {
    final dynamic x;
    x;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x(use);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x.foo;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x.foo();
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x.foo = 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x?.foo;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x..foo;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x[0];
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    ([3])[x];
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    (x as int);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    (x is int);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    (x == null);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    (null == x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    (3 == x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    (x == 3);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    (x == 3);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x++;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    ++x;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    -x;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x += 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x ??= 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    x ?? 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    3 ?? x;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

/// Test that a read of a potentially unassigned variable gives the correct
/// error for a single choice of declaration form, across a range of read
/// constructs.
///
/// These tests declare a `final` variable of type `dynamic` and assign to it in
/// one branch of a conditional such that the variable is potentially but not
/// definitely assigned.  The test then checks that it is an error to use the
/// variable in a variety of syntactic positions.
void testPotentiallyUnassignedReadForms(bool b) {
  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    x;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    x(use);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    x.foo;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    x.foo();
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    x.foo = 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    x?.foo;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    x..foo;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    x[0];
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    ([3])[x];
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    (x as int);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    (x is int);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    (x == null);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    (null == x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    (3 == x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    (x == 3);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    (x == 3);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
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
    -x;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
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
    x ??= 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    x ?? 3;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  {
    final dynamic x;
    if (b) {
      x = 3;
    }
    3 ?? x;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

/// Test that a read of a definitely assigned variable is not an error for a
/// single choice of declaration form, across a range of read constructs.
///
/// This test declares a final variable and then initializes it via an
/// assignment.  The test then verifies that it is not an error to read the
/// variable in a variety of syntactic positions.
void testDefinitelyAssignedReadForms() {
  {
    final dynamic x;
    x = 3;
    x;
  }

  {
    final dynamic x;
    x = 3;
    use(x);
  }

  {
    final dynamic x;
    x = 3;
    x(use);
  }

  {
    final dynamic x;
    x = 3;
    x.foo;
  }

  {
    final dynamic x;
    x = 3;
    x.foo();
  }

  {
    final dynamic x;
    x = 3;
    x.foo = 3;
  }

  {
    final dynamic x;
    x = 3;
    x?.foo;
  }

  {
    final dynamic x;
    x = 3;
    x..foo;
  }

  {
    final dynamic x;
    x = 3;
    x[0];
  }

  {
    final dynamic x;
    x = 3;
    ([3])[x];
  }

  {
    final dynamic x;
    x = 3;
    (x as int);
  }

  {
    final dynamic x;
    x = 3;
    (x is int);
  }

  {
    final dynamic x;
    x = 3;
    (x == null);
  }

  {
    final dynamic x;
    x = 3;
    (null == x);
  }

  {
    final dynamic x;
    x = 3;
    (3 == x);
  }

  {
    final dynamic x;
    x = 3;
    (x == 3);
  }

  {
    final dynamic x;
    x = 3;
    (x == 3);
  }

  {
    final dynamic x;
    x = 3;
    x++;
//  ^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
// [cfe] Final variable 'x' might already be assigned at this point.
  }

  {
    final dynamic x;
    x = 3;
    ++x;
//    ^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
// [cfe] Final variable 'x' might already be assigned at this point.
  }

  {
    final dynamic x;
    x = 3;
    -x;
  }

  {
    final dynamic x;
    x = 3;
    x += 3;
//  ^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
// [cfe] Final variable 'x' might already be assigned at this point.
  }

  {
    final dynamic x;
    x = 3;
    x ??= 3;
//  ^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
// [cfe] Final variable 'x' might already be assigned at this point.
  }

  {
    final dynamic x;
    x = 3;
    x ?? 3;
  }

  {
    final dynamic x;
    x = 3;
    3 ?? x;
//  ^
// [cfe] Operand of null-aware operation '??' has type 'int' which excludes null.
//       ^
// [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
  }
}

void main() {
  testDefinitelyUnassignedReads<int>();
  testPotentiallyUnassignedReads<int>(true, 0);
  testDefinitelyAssignedReads<int>(0);
  testDefinitelyUnassignedReadForms();
  testPotentiallyUnassignedReadForms(true);
  testDefinitelyAssignedReadForms();
}
