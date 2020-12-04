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
/// This test checks the latter.

void use(Object? x) {}

enum AorB { a, b }

AorB aOrB = AorB.a;

/// For two variable forms, test that definite un-assignment is correctly
/// tracked for a variety of control flow structures.  Each entry in this test
/// declares a variable `int x` and a variable `late int y`, arranges for `x`
/// and `y` to be in the definitely unassigned state, and then reads from
/// each of them.  It is expected that reading both `x` and `y` in this state
/// is an error.
///
/// Each entry is guarded by a condition to ensure that all entries are
/// reachable.
void testDefiniteUnassignment(bool b) {
  // Test unassignment in straightline code
  if (b) {
    int x;
    late int y;
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
    // [cfe] Late variable 'y' without initializer is definitely unassigned.
  }

  // Unreachable code inherits the state from the paths leading into it
  // as if it were reachable.
  if (b) {
    int x;
    late int y;
    return;
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
    // [cfe] Late variable 'y' without initializer is definitely unassigned.
  }

  // An empty conditional does not change unassignment state
  if (b) {
    int x;
    late int y;
    if (b) {}
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
    // [cfe] Late variable 'y' without initializer is definitely unassigned.
  }

  // Assignments in a branch that returns do not change unassignment state.
  if (b) {
    int x;
    late int y;
    if (b) {
      x = 3;
      y = 3;
      return;
    }
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
    // [cfe] Late variable 'y' without initializer is definitely unassigned.
  }

  //  Assignments in a different branch do not change unassignment state.
  if (b) {
    int x;
    late int y;
    if (b) {
      x = 3;
      y = 3;
    } else {
      use(x);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
      // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
      use(y);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
      // [cfe] Late variable 'y' without initializer is definitely unassigned.
    }
  }

  // Null-aware assignments are correctly recognized as unassigned.  This test
  // changes the pattern by using a final nullable variable to make the
  // assignment non-trivial.
  if (b) {
    final int? x;
    late int? y;
    x ??= 3;
//  ^
// [analyzer] unspecified
// [cfe] unspecified
    y ??= 3;
//  ^
// [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
// [cfe] Late variable 'y' without initializer is definitely unassigned.
  }

  // A while loop which does no assignments does not change unassignment state.
  if (b) {
    int x;
    late int y;
    while (b) {}
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
    // [cfe] Late variable 'y' without initializer is definitely unassigned.
  }

  // Uses inside a while loop which does no assignments are definitely
  // unassigned.
  if (b) {
    int x;
    late int y;
    while (b) {
      use(x);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
      // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
      use(y);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
      // [cfe] Late variable 'y' without initializer is definitely unassigned.
    }
  }

  // Uses inside a do while loop which does no assignments are definitely
  // unassigned.
  if (b) {
    int x;
    late int y;
    do {
      use(x);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
      // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
      use(y);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
      // [cfe] Late variable 'y' without initializer is definitely unassigned.
    } while (b);
  }

  // Uses inside a switch which assigns in a different branch are still
  // definitely unassigned.
  if (b) {
    int x;
    late int y;
    switch (aOrB) {
      case AorB.a:
        x = 3;
        y = 3;
        break;
      default:
        use(x);
        //  ^
        // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
        // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
        use(y);
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
      // [cfe] Late variable 'y' without initializer is definitely unassigned.
    }
  }

  // Assignments in a branch of a switch which returns do not affect definite
  // uassignment after the switch.
  if (b) {
    int x;
    late int y;
    switch (aOrB) {
      case AorB.a:
        x = 3;
        y = 3;
        return;
      case AorB.b:
        break;
    }
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
    // [cfe] Late variable 'y' without initializer is definitely unassigned.
  }

  // Assignments in a closure do not affect definite unassignment before the
  // closure is introduced.
  if (b) {
    int x;
    late int y;
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
    // [cfe] Late variable 'y' without initializer is definitely unassigned.
    var f = () {
      x = 3;
      y = 3;
    };
  }

  // Uses in a closure with no other assignments to the variables are recognized
  // as definitely unassigned.
  if (b) {
    int x;
    late int y;
    var f = () {
      use(x);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
      // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
      use(y);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
      // [cfe] Late variable 'y' without initializer is definitely unassigned.
    };
  }

  // Assignments in a late initializer do not affect definite unassignment
  // before the late initializer is introduced.
  if (b) {
    int x;
    late int y;
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
    // [cfe] Late variable 'y' without initializer is definitely unassigned.
    late int z1 = x = 3;
    late int z2 = y = 3;
  }

  // Uses in a for loop test which are not assigned before or in the loop are
  // definitely unassigned.
  if (b) {
    int x;
    late int y;
    for (; x < 0;) {}
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    for (; y < 0;) {}
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
    // [cfe] Late variable 'y' without initializer is definitely unassigned.
  }

  // Uses in a for loop element test which are not assigned before or in the
  // loop are definitely unassigned.
  if (b) {
    int x;
    late int y;
    [for (; x < 0;) 0];
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    [for (; y < 0;) 0];
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
    // [cfe] Late variable 'y' without initializer is definitely unassigned.
  }

  // Uses in a for loop increment which are not assigned before or in the loop
  // are definitely unassigned.
  if (b) {
    int x;
    late int y;
    for (;; x) {}
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    for (;; y) {}
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
    // [cfe] Late variable 'y' without initializer is definitely unassigned.
  }

  // Uses in a for loop element increment which are not assigned before or in
  // the loop are definitely unassigned.
  if (b) {
    int x;
    late int y;
    [for (;; x) 0];
    //       ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    [for (;; y) 0];
    //       ^
    // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
    // [cfe] Late variable 'y' without initializer is definitely unassigned.
  }
}

/// For two variable forms, test that potential un-assignment is correctly
/// tracked for a variety of control flow structures.  Each entry in this test
/// declares a variable `int x` and a variable `late int y`, arranges for `x`
/// and `y` to be in the potentially (but not definitely) unassigned state, and
/// then reads from each of them.  It is expected that reading `x` in this state
/// is an error, but reading `y` in this state is not an error.
///
/// Each entry is guarded by a condition to ensure that all entries are
/// reachable.
void testPotentialUnassignment(bool b) {
  // Assignments in an `if` with no else result in a potentially unassigned
  // state.
  if (b) {
    int x;
    late int y;
    if (b) {
      x = 3;
      y = 3;
    }
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
  }

  // Unreachable code inherits the state from the paths leading into it
  // as if it were reachable.
  if (b) {
    int x;
    late int y;
    if (b) {
      x = 3;
      y = 3;
    }
    return;
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
  }

  // Assignments in one branch of a conditional and not the other result in a
  // potentially unassigned state.
  if (b) {
    int x;
    late int y;
    if (b) {
      x = 3;
      y = 3;
    } else {}
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
  }

  // Assignments in one branch of a conditional expression leave a variable in a
  // potentially assigned state.
  if (b) {
    int x;
    late int y;
    b ? x = 3 : 3;
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    b ? y = 3 : 3;
    use(y);
  }

  // Assignments in one branch of a conditional element leave a variable in a
  // potentially assigned state.
  if (b) {
    int x;
    late int y;
    [if (b) x = 3];
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    [if (b) y = 3];
    use(y);
  }

  // Joining a branch in which a variable is potentially assigned to a branch in
  // which a variable is definitely assigned leave the variable in a potentially
  // assigned state.
  if (b) {
    int x;
    late int y;
    if (b) {
      if (b) {
        x = 3;
        y = 3;
      }
    } else {
      x = 3;
      y = 3;
    }
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
  }

  // Null-aware assignments leave a variable in a potentially assigned state.
  // For non-late variables, this is a non-issue since the variable must be
  // definitely assigned in order to perform the assignment.  For late
  // variables, we test this using a late final nullable variable in a
  // potentially nullable state in the null-aware assignment, and then checking
  // that both a use and an assignment are not erroneous, implying that the
  // null-aware assignment has left the variable neither definitely assigned
  // (since in this case the assignment would be erroneous), nor definitely
  // unassigned (since in this case the read would be erroneous).
  if (b) {
    late final int? x;
    late final int? y;
    if (b) {
      y = 3;
      x = 3;
    } // x and y are now potentially assigned.
    x ??= 3;
    y ??= 3;
    use(x);
    y = 3;
  }

  // Uses in a while loop which contains later assignments are treated as
  // potentially assigned.
  if (b) {
    int x;
    late int y;
    while (b) {
      use(x);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
      // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
      use(y);
      x = 3;
      y = 3;
    }
  }

  // Uses after a loop which contains assignments are treated as potentially
  // assigned.
  if (b) {
    int x;
    late int y;
    while (b) {
      x = 3;
      y = 3;
    }
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
  }

  // Uses in a loop with assignments guarded by a conditional are treated as
  // potentially assigned.
  if (b) {
    int x;
    late int y;
    while (b) {
      if (b) {
        x = 3;
        y = 3;
      }
      use(x);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
      // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
      use(y);
    }
  }

  // Uses in a do/while loop which contains assignment are treated as
  // potentially assigned.
  if (b) {
    int x;
    late int y;
    do {
      use(x);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
      // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
      use(y);
      x = 3;
      y = 3;
    } while (b);
  }

  // Uses in a do/while loop with assignments guarded by a condition are treated
  // as potentially assigned.
  if (b) {
    int x;
    late int y;
    do {
      if (b) {
        x = 3;
        y = 3;
      }
      use(x);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
      // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
      use(y);
    } while (b);
  }

  // Uses after a switch which assigns in some branches but not in the default
  // case are treated as potentially assigned.
  if (b) {
    int x;
    late int y;
    switch (aOrB) {
      case AorB.a:
        x = 3;
        y = 3;
        break;
      default:
    }
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
  }

  // Uses after a switch which assigns in one branch but not in the other case
  // are treated as potentially assigned.
  if (b) {
    int x;
    late int y;
    switch (aOrB) {
      case AorB.a:
        x = 3;
        y = 3;
        break;
      case AorB.b:
        break;
    }
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
  }

  // Uses in a closure when there are subsequent assignments in the enclosing
  // function body are treated as potentially assigned.
  if (b) {
    int x;
    late int y;
    var f = () {
      use(x);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
      // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
      use(y);
    };
    x = 3;
    y = 3;
  }

  // Uses in a closure when there are subsequent assignments in the closure body
  // are treated as potentially unassigned.
  if (b) {
    int x;
    late int y;
    var f = () {
      use(x);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
      // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
      use(y);
      x = 3;
      y = 3;
    };
  }

  // Uses in a closure when there are subsequent assignments in a subsequent
  // closure are treated as potentially assigned.
  if (b) {
    int x;
    late int y;
    var f = () {
      use(x);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
      // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
      use(y);
    };
    var g = () {
      x = 3;
      y = 3;
    };
  }

  // Uses in a closure when there are assignments in a previous closure are
  // treated as potentially assigned.
  if (b) {
    int x;
    late int y;
    var g = () {
      x = 3;
      y = 3;
    };
    var f = () {
      use(x);
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
      // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
      use(y);
    };
  }

  // Uses after a closure which contains assignments has been introduced are
  // treated as potentially assigned.
  if (b) {
    int x;
    late int y;
    var f = () {
      x = 3;
      y = 3;
    };
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
  }

  // Uses in a late initializer when there are subsequent assignments in the
  // enclosing function body are treated as potentially assigned.
  if (b) {
    int x;
    late int y;
    late int z0 = x;
    //            ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    late int z1 = y;
    x = 3;
    y = 3;
  }

  // Uses in a late initializer when there are subsequent assignments in the
  // late initializer are treated as potentially assigned, since late
  // initializers may be re-executed if a previous execution failed to complete
  // due to throwing an exception, or due to re-entering the initializer during
  // execution.
  if (b) {
    int x;
    late int y;
    late int z0 = x + (x = 3);
    //            ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    late int z1 = y + (y = 3);
  }

  // Uses in a late initializer when there are subsequent assignments in a
  // subsequent late initializer are treated as potentially assigned.
  if (b) {
    int x;
    late int y;
    late int z0 = x;
    //            ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    late int z1 = y;
    late int z3 = (x = 3) + (y = 3);
  }

  // Uses in a late initializer when there are assignments in a previous late
  // initializer are treated as potentially assigned.
  if (b) {
    int x;
    late int y;

    late int z3 = (x = 3) + (y = 3);

    late int z0 = x;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    late int z1 = y;
  }

  // Uses after a late initializer which contains assignments are treated as
  // potentially assigned.
  if (b) {
    int x;
    late int y;
    late int z0 = x = 3;
    late int z1 = y = 3;
    use(x);
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    use(y);
  }

  // Uses of a for in loop index variable after the loop are potentially
  // unassigned.
  if (b) {
    int x;
    late int y;
    for (x in []) {}
    for (y in []) {}
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
  }

  // Uses of a for in element index variable after the loop are potentially
  // unassigned.
  if (b) {
    int x;
    late int y;
    [for (x in []) 0];
    [for (y in []) 0];
    use(x);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    use(y);
  }

  // Uses in a for loop test which are assigned in the loop but not before it
  // are potentially unassigned.
  if (b) {
    int x;
    late int y;
    for (; x < 0;) {
      //   ^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
      // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
      x = 0;
    }
    for (; y < 0;) {
      y = 0;
    }
  }

  // Uses in a for loop element test which are assigned in the loop but not
  // before it in the loop are potentially unassigned
  if (b) {
    int x;
    late int y;
    [for (; x < 0;) x = 0];
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
    // [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    [for (; y < 0;) y = 0];
  }
}

/// For a single variable form, test that definite assignment is correctly
/// tracked for a variety of control flow structures.  Each entry in this test
/// declares a variable `int x`, arranges for `x` to be in the definitely
/// assigned state, and then reads from `x`.  It is expected that reading `x` in
/// this state is not an error.
///
/// Each entry is guarded by a condition to ensure that all entries are
/// reachable.
void testDefiniteAssignment(bool b) {
  // A variable used after a straightline assignment is definitely assigned.
  if (b) {
    int x;
    x = 3;
    use(x);
  }

  // Unreachable code inherits the state from the paths leading into it
  // as if it were reachable.
  if (b) {
    int x;
    x = 3;
    return;
    use(x);
  }

  // A variable assigned in both branches of a conditional statement is
  // definitely assigned after the conditional.
  if (b) {
    int x;
    if (b) {
      x = 3;
    } else {
      x = 3;
    }
    use(x);
  }

  // A variable assigned in both branches of a conditional expression is
  // definitely assigned after the conditional.
  if (b) {
    int x;
    b ? x = 3 : x = 3;
    use(x);
  }

  // A variable assigned in both branches of a conditional element is
  // definitely assigned after the conditional.
  if (b) {
    int x;
    [if (b) x = 3 else x = 3];
    use(x);
  }

  // A variable assigned in the only completing branch of a conditional
  // statement is definitely assigned after the conditional.
  if (b) {
    int x;
    if (b) {
      x = 3;
    } else {
      return;
    }
    use(x);
  }

  // A variable assigned in the only completing branch of a conditional
  // expression is definitely assigned after the conditional.
  if (b) {
    int x;
    b ? x = 3 : throw "Return";
    use(x);
  }

  // A variable assigned in the only completing branch of a conditional element
  // is definitely assigned after the conditional.
  if (b) {
    int x;
    [if (b) x = 3 else throw "Return"];
    use(x);
  }

  // A variable assigned and used in a while loop is definitely assigned after
  // the assignment.
  if (b) {
    int x;
    while (b) {
      x = 3;
      use(x);
    }
  }

  // A variable assigned and used in a do while loop is definitely assigned
  // after the assignment, and after the loop.
  if (b) {
    int x;
    do {
      x = 3;
      use(x);
    } while (b);
    use(x);
  }

  // A variable assigned in both branches of an exhaustive switch is definitely
  // assigned after the switch.
  if (b) {
    int x;
    switch (aOrB) {
      case AorB.a:
        x = 3;
        break;
      case AorB.b:
        x = 3;
        break;
    }
    use(x);
  }

  // A variable used in a closure which is allocated after the variable has been
  // assigned is definitely assigned.
  if (b) {
    int x;
    x = 3;
    var f = () {
      use(x);
    };
  }

  // A variable used in a closure after being assigned in the closure is
  // definitely assigned.
  if (b) {
    int x;
    var f = () {
      x = 3;
      use(x);
    };
  }

  // A variable used in a late initializer which is declared after the variable
  // has been assigned is definitely assigned.
  if (b) {
    int x;
    x = 3;
    late int z = x;
  }

  // A variable used in a late initializer after being assigned in the
  // initializer is definitely assigned.
  if (b) {
    int x;
    late int z = (x = 3) + x;
  }

  // Uses of a for in loop index variable inside the loop are definitely
  // assigned.
  if (b) {
    int x;
    for (x in []) {
      use(x);
    }
  }

  // Uses of a for in element index variable inside the loop are definitely
  // assigned.
  if (b) {
    int x;
    [for (x in []) use(x)];
  }

  // Uses of a for in loop index variable inside the loop are definitely
  // assigned.
  if (b) {
    for (int x in []) {
      use(x);
    }
  }

  // Uses of a for in element index variable inside the loop are definitely
  // assigned.
  if (b) {
    [for (int x in []) use(x)];
  }

  // A variable which is assigned in the entry to a for loop is definitely
  // assigned in the loop test and increment sections, and after the loop.
  if (b) {
    int x;
    for (x = 0; x < 0; x++) {}
    use(x);
  }

  // A variable which is assigned in the entry to a for loop element is
  // definitely assigned in the loop test and increment sections, and after the
  // loop.
  if (b) {
    int x;
    [for (x = 0; x < 0; x++) 0];
    use(x);
  }

  // Uses in a for loop increment which are assigned in the loop are definitely
  // assigned.
  if (b) {
    int x;
    for (;; x) {
      x = 0;
    }
  }

  // Uses in a for loop element increment which are assigned in the loop are
  // definitely assigned.
  if (b) {
    int x;
    [for (;; x) x = 0];
  }
}

void main() {
  testDefiniteUnassignment(false);
  testPotentialUnassignment(false);
  testDefiniteAssignment(false);
}
