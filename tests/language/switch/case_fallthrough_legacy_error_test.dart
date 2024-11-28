// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test switch statement "fallthrough" behavior.
//
// Test behavior for Dart from version 2.12 until 3.0.
// @dart=2.19
//
// From Dart 2.12 until Dart 3.0, it's an error if control can reach the end
// of a case block. This is backed by a competent control flow analysis.
//
// From Dart 2.0 until Dart 2.12 there was a warning if a case block did
// not end with a control flow statement (like `break`).
//
// From Dart 3.0 and forward, there is no warning or error.

// These switch-case statements should not cause static warnings or errors,
// and also shouldn't in Dart 2.0 until Dart 2.12.
dynamic testSwitch(int x) {
  // Catch all control flow leaving the switch.
  // Run switch in catch clause to check that `rethrow` is control flow.
  TRY:
  try {
    throw x;
  } catch (_) {
    // Add loop as break/continue target.
    LOOP:
    do {
      switch (x) {
        case 0:
        case 1:
          nop(x);
          break; // Break switch.
        case 2:
          nop(x);
          break LOOP;
        case 3:
          nop(x);
          continue; // Continue loop.
        case 4:
          nop(x);
          continue LOOP;
        case 5:
          nop(x);
          continue LAST;
        case 6:
          nop(x);
          return;
        case 7:
          nop(x);
          return x;
        case 8:
          nop(x);
          throw x;
        case 9:
          nop(x);
          rethrow;
        case 10:
        case 11:
          {
            nop(x);
            break;
          }
        case 12:
          {
            nop(x);
            break LOOP;
          }
        case 13:
          {
            nop(x);
            continue; // Continue loop.
          }
        case 14:
          {
            nop(x);
            continue LOOP;
          }
        case 15:
          {
            nop(x);
            continue LAST;
          }
        case 16:
          {
            nop(x);
            return;
          }
        case 17:
          {
            nop(x);
            return x;
          }
        case 18:
          {
            nop(x);
            throw x;
          }
        case 19:
          {
            nop(x);
            rethrow;
          }
        LAST:
        case 20:
          {
            nop(x);
            // Fallthrough allowed on last statements.
          }
      }
    } while (false);
  } finally {
    // Catch all control flow leaving the switch and ignore it.
    // Use break instead of return to avoid warning for `return` and `return e`
    // in same function.
    break TRY;
  }
}

// In Dart 2.0, all of these switch cases should cause warnings because the
// fallthrough analysis was very limited and syntax-based. Null safety
// includes more precise flow analysis so most of these are now valid code
// because in fact no fallthrough will occur.
//
// The cases that are now recognized as not reaching the end of the case block,
// with the Dart 2.12 control flow analysis, are still included to ensure
// that they no longer cause warnings or errors.
// The ones that are still considered as being able to reach the end
// are now expected to cause an error.
//
// Return type `dynamic` to avoid a warning for either of
// `return;` or `return x;`.
dynamic testSwitchWarn(int x) {
  // Catch all control flow from the switch and ignore it.
  TRY:
  try {
    throw 0;
  } catch (_) {
    // Enable `rethrow` as control flow.
    // Wrap in loop as target for continue/break.
    LOOP:
    do {
      switch (x) {
        case 0: // Case for same statements as next case.
        case 1:
          {
            // Dart 2.0 looked inside a single nested block, but not two.
            {
              nop(x);
              break; // Break and exit switch.
            }
          }
        case 2:
          {
            {
              nop(x);
              break LOOP; // Break loop, exits switch (and loop).
            }
          }
        case 3:
          {
            {
              nop(x);
              continue; // Continue loop, exits switch.
            }
          }
        case 4:
          {
            {
              nop(x);
              continue LOOP; // Continue loop, exits switch.
            }
          }
        case 5:
          {
            {
              nop(x);
              continue LAST; // Exits case, goto other case.
            }
          }
        case 6:
          {
            {
              nop(x);
              return; // Exits function, loop and switch.
            }
          }
        case 7:
          {
            {
              nop(x);
              return x; // Exits function, loop and switch.
            }
          }
        case 8:
          {
            {
              nop(x);
              throw x; // Exits switch.
            }
          }
        case 9:
          {
            {
              nop(x);
              rethrow; // Exits switch.
            }
          }
        case 10:
        // [error column 9, length 4]
        // [analyzer] COMPILE_TIME_ERROR.SWITCH_CASE_COMPLETES_NORMALLY
        // [cfe] Switch case may fall through to the next case.
          while (true) break; // Breaks loop, reaches end.
        case 11:
        // [error column 9, length 4]
        // [analyzer] COMPILE_TIME_ERROR.SWITCH_CASE_COMPLETES_NORMALLY
        // [cfe] Switch case may fall through to the next case.
          do break; while (true); // Breaks loop, reaches end.
        case 12:
        // [error column 9, length 4]
        // [analyzer] COMPILE_TIME_ERROR.SWITCH_CASE_COMPLETES_NORMALLY
        // [cfe] Switch case may fall through to the next case.
          for (;;) break; // Breaks loop, reaches end.
        case 13:
        // [error column 9, length 4]
        // [analyzer] COMPILE_TIME_ERROR.SWITCH_CASE_COMPLETES_NORMALLY
        // [cfe] Switch case may fall through to the next case.
          for (var _ in []) break LOOP; // Can be empty, reaches end.
        case 14:
          if (x.isEven) {
            break; // Breaks and exits switch.
          } else {
            break LOOP; // Breaks loop and exits switch.
          }
        case 15:
          (throw 0); // Exits switch.
        case 16:
        // [error column 9, length 4]
        // [analyzer] COMPILE_TIME_ERROR.SWITCH_CASE_COMPLETES_NORMALLY
        // [cfe] Switch case may fall through to the next case.
          nop(x); // Reaches end.
        case 17:
          L:
          break; // Breaks and exits switch.
        case 18:
        // [error column 9, length 4]
        // [analyzer] COMPILE_TIME_ERROR.SWITCH_CASE_COMPLETES_NORMALLY
        // [cfe] Switch case may fall through to the next case.
          L:
          break L; // Breaks break statement only, reaches end.
        case 19:
        // [error column 9, length 4]
        // [cfe] Switch case may fall through to the next case.
        // [analyzer] COMPILE_TIME_ERROR.SWITCH_CASE_COMPLETES_NORMALLY
          L:
          if (x.isOdd) {
            break L; // Breaks if, reaches end.
          } else {
            break LOOP;
          }

        // The type `Never` is new in Dart 2.12. These would be warnings
        // with any pre-2.12 type.
        case 20:
          notEver(x); // Type Never implies not completing.
        case 21: {
          notEver(x);
        }
        case 22: {
          {
            notEver(x);
          }
        }
        case 23: {
          do {
            notEver(x);
          } while (true);
        }
        case 24: {
          if (x.isEven) {
            notEver(x);
          } else {
            notEver(-x);
          }
        }
        case 25:
          nop(x.isEven ? notEver(x) : notEver(-x));
        LAST:
        case 99:
        // Last case can't cause static warning.
      }
    } while (false);
  } finally {
    // Catch all control flow leaving the switch and ignore it.
    break TRY;
  }
}

Never notEver(int x) {
  if (x < 0) {
    notEver(x + 1);
  } else {
    throw AssertionError("Never");
  }
}

main() {
  // Don't let compiler optimize for a specific value.
  for (int i = 0; i <= 100; i++) {
    testSwitch(i);
    testSwitchWarn(i);
  }
}

/// Don't make it obvious that a switch case isn't doing anything.
void nop(Object? x) {}
