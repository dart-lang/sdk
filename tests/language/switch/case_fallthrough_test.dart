// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test switch statement "fallthrough" behavior.
//
// Tests behavior for Dart from version 3.0, where there is no error or
// warning related to control reaching the end of switch cases.
// See `case_fallthrough_legacy_error_test.dart` for previous behavior.

// Return type `dynamic` to avoid a warning for either of
// `return;` or `return x;`.
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
        case 20:
          {
            {
              nop(x);
              break; // Break and exit switch.
            }
          }
        case 21:
          {
            {
              nop(x);
              break LOOP; // Break loop, exits switch (and loop).
            }
          }
        case 22:
          {
            {
              nop(x);
              continue; // Continue loop, exits switch.
            }
          }
        case 23:
          {
            {
              nop(x);
              continue LOOP; // Continue loop, exits switch.
            }
          }
        case 24:
          {
            {
              nop(x);
              continue LAST; // Exits case, goto other case.
            }
          }
        case 25:
          {
            {
              nop(x);
              return; // Exits function, loop and switch.
            }
          }
        case 26:
          {
            {
              nop(x);
              return x; // Exits function, loop and switch.
            }
          }
        case 27:
          {
            {
              nop(x);
              throw x; // Exits switch.
            }
          }
        case 28:
          {
            {
              nop(x);
              rethrow; // Exits switch.
            }
          }
        case 29:
          while (true) break; // Breaks loop, reaches end.
        case 30:
          do break; while (true); // Breaks loop, reaches end.
        case 31:
          for (;;) break; // Breaks loop, reaches end.
        case 32:
          for (var _ in []) break LOOP; // Can be empty, reaches end.
        case 33:
          if (x.isEven) {
            break; // Breaks and exits switch.
          } else {
            break LOOP; // Breaks loop and exits switch.
          }
        case 34:
          (throw 0); // Exits switch.
        case 35:
          nop(x); // Reaches end.
        case 36:
          L:
          break; // Breaks and exits switch.
        case 37:
          L:
          break L; // Breaks break statement only, reaches end.
        case 38:
          L:
          if (x.isOdd) {
            break L; // Breaks if, reaches end.
          } else {
            break LOOP;
          }
        case 39:
          notEver(x); // Type Never implies not completing.
        case 40: {
          notEver(x);
        }
        case 41: {
          {
            notEver(x);
          }
        }
        case 42: {
          do {
            notEver(x);
          } while (true);
        }
        case 43: {
          if (x.isEven) {
            notEver(x);
          } else {
            notEver(-x);
          }
        }
        case 44:
          nop(x.isEven ? notEver(x) : notEver(-x));
        LAST:
        case 99:
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
  }
}

/// Don't make it obvious that a switch case isn't doing anything.
void nop(Object? x) {}
