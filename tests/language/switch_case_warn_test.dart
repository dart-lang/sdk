// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test switch statement.

// Tests some switch-case statements blocks that should and should not
// cause static warnings.
// This test is not testing runtime behavior, only static warnings.

// None of the cases blocks should cause a warning.
void testSwitch(int x) {
  // Catch all control flow leaving the switch.
  // Run switch in catch clause to check rethrow.
  TRY: try {
    throw x;
  } catch (x) {
    // Add loop as break/continue target.
    LOOP: do {
      switch (x) {
        case 0:
        case 1:
          nop(x);
          break;  // Break switch.
        case 2:
          nop(x);
          break LOOP;
        case 3:
          nop(x);
          continue;  // Continue loop.
        case 4:
          nop(x);
          continue LOOP;
        case 5:
          nop(x);
          continue LAST;
        // Avoid warning for "return;"" and "return e;" in same function.
        case 6:      /// retnon: ok
          nop(x);    /// retnon: continued
          return;    /// retnon: continued
        case 7:      /// retval: ok
          nop(x);    /// retval: continued
          return x;  /// retval: continued
        case 8:
          nop(x);
          throw x;
        case 9:
          nop(x);
          rethrow;
        case 10:
        case 11: {
          nop(x);
          break;  // Break switch.
        }
        case 12: {
          nop(x);
          break LOOP;
        }
        case 13: {
          nop(x);
          continue;  // Continue loop.
        }
        case 14: {
          nop(x);
          continue LOOP;
        }
        case 15: {
          nop(x);
          continue LAST;
        }
        case 16: {   /// retnon: continued
          nop(x);    /// retnon: continued
          return;    /// retnon: continued
        }            /// retnon: continued
        case 17: {   /// retval: continued
          nop(x);    /// retval: continued
          return x;  /// retval: continued
        }            /// retval: continued
        case 18: {
          nop(x);
          throw x;
        }
        case 19: {
          nop(x);
          rethrow;
        }
        LAST:
        case 20: {
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

// All these switch cases should cause warnings.
void testSwitchWarn(x) {
  // Catch all control flow from the switch and ignore it.
  TRY: try {
    throw 0;
  } catch (e) {
    // Wrap in loop as target for continue/break.
    LOOP: do {
      switch (x) {
        case 0:                          /// 01: static type warning
        case 1: {                        /// 01: continued
          {                              /// 01: continued
            nop(x);                      /// 01: continued
            break;  // Break switch.     /// 01: continued
          }                              /// 01: continued
        }                                /// 01: continued
        case 2: {                        /// 02: static type warning
          {                              /// 02: continued
            nop(x);                      /// 02: continued
            break LOOP;                  /// 02: continued
          }                              /// 02: continued
        }                                /// 02: continued
        case 3: {                        /// 03: static type warning
          {                              /// 03: continued
            nop(x);                      /// 03: continued
            continue;  // Continue loop. /// 03: continued
          }                              /// 03: continued
        }                                /// 03: continued
        case 4: {                        /// 04: static type warning
          {                              /// 04: continued
            nop(x);                      /// 04: continued
            continue LOOP;               /// 04: continued
          }                              /// 04: continued
        }                                /// 04: continued
        case 5: {                        /// 05: static type warning
          {                              /// 05: continued
            nop(x);                      /// 05: continued
            continue LAST;               /// 05: continued
          }                              /// 05: continued
        }                                /// 05: continued
        case 6: {                        /// 06: static type warning
          {                              /// 06: continued
            nop(x);                      /// 06: continued
            return;                      /// 06: continued
          }                              /// 06: continued
        }                                /// 06: continued
        case 7: {                        /// 07: static type warning
          {                              /// 07: continued
            nop(x);                      /// 07: continued
            return x;                    /// 07: continued
          }                              /// 07: continued
        }                                /// 07: continued
        case 8: {                        /// 08: static type warning
          {                              /// 08: continued
            nop(x);                      /// 08: continued
            throw x;                     /// 08: continued
          }                              /// 08: continued
        }                                /// 08: continued
        case 9: {                        /// 09: static type warning
          {                              /// 09: continued
            nop(x);                      /// 09: continued
            rethrow;                     /// 09: continued
          }                              /// 09: continued
        }                                /// 09: continued
        case 10:                         /// 10: static type warning
          while (true) break;            /// 10: continued
        case 11:                         /// 11: static type warning
          do break; while (true);        /// 11: continued
        case 12:                         /// 12: static type warning
          for (;;) break;                /// 12: continued
        case 13:                         /// 13: static type warning
          for (var _ in []) break;       /// 13: continued
        case 14:                         /// 14: static type warning
          if (x) break; else break;      /// 14: continued
        case 15:                         /// 15: static type warning
          (throw 0);                     /// 15: continued
        case 16:                         /// 16: static type warning
          nop(x);      // fallthrough.   /// 16: continued
        case 17:                         /// 17: static type warning
          L: break;                      /// 17: continued
        LAST:
        case 99:
          // Last case can't cause static warning.
      }
    } while (false);
  } finally {
    // Catch all control flow leaving the switch and ignore it.
    // Use break instead of return to avoid warning for `return` and `return e`
    // in same function.
    break TRY;
  }
}

main() {
  // Ensure that all the cases compile and run (even if they might throw).
  for (int i = 0; i <= 20; i++) {
    testSwitch(i);  // Just make sure it runs.
  }
  for (int i = 0; i <= 18; i++) {
    testSwitchWarn(i);
  }
}

/// Don't make it obvious that a switch case isn't doing anything.
void nop(x) {}
