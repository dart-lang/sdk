// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns

main() {
  // Error to assign to pattern variables in guard.
  switch (false) {
    case bool x when x = true:
      //             ^
      // [analyzer] COMPILE_TIME_ERROR.PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD
      // [cfe] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
      print(x);
    default:
  }

  print(switch (false) {
    bool x when x = true => x,
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD
    // [cfe] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
    _ => false
  });

  if (false case bool x when x = true) {
    //                       ^
    // [analyzer] COMPILE_TIME_ERROR.PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD
    // [cfe] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
    print(x);
  }

  print([
    if (false case bool x when x = true)
      //                       ^
      // [analyzer] COMPILE_TIME_ERROR.PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD
      // [cfe] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
      x
  ]);

  // Error even if assignment is nested inside closure.
  switch (false) {
    case var x
        when () {
          return x = true;
          //     ^
          // [analyzer] COMPILE_TIME_ERROR.PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD
          // [cfe] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
        }():
      print(x);
    default:
  }

  print(switch (false) {
    var x
        when (() {
          return x = true;
          //     ^
          // [analyzer] COMPILE_TIME_ERROR.PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD
          // [cfe] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
        })() =>
      x,
    _ => false
  });

  if (false case var x
      when (() {
        return x = true;
        //     ^
        // [analyzer] COMPILE_TIME_ERROR.PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD
        // [cfe] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
      })()) {
    print(x);
  }

  print([
    if (false case var x
        when (() {
          return x = true;
          //     ^
          // [analyzer] COMPILE_TIME_ERROR.PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD
          // [cfe] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
        })())
      x
  ]);

  // Not an error to assign to other variables.
  var local = false;
  switch (false) {
    case var x when local = true:
      // No error.
      print(x);
    default:
  }

  print(switch (false) {
    var x when local = true => x, // No error.
    _ => 0,
  });

  if (false case var x when local = true) {
    // No error.
    print(x);
  }

  print([
    if (false case var x when local = true) x // No error.
  ]);

  // Not an error to assign to pattern variables from other pattern.
  switch (false) {
    case bool x:
      switch (false) {
        case bool y when x = true:
          // No error.
          print(y);
        default:
      }

      print(switch (false) {
        bool y when x = true => y, // No error.
        _ => 0,
      });

      if (false case bool y when x = true) {
        // No error.
        print(y);
      }

      print([
        if (false case bool y when x = true) x // No error.
      ]);
  }
}
