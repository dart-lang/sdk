// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that '??' binds tighter than '?:' and less tightly than '||'.

import "package:expect/expect.dart";

assertionError(e) => e is AssertionError;

// Determine whether the VM is running in checked mode.
bool get checkedMode {
  try {
    var x = 'foo';
    int y = x;
    return false;
  } catch (_) {
    return true;
  }
}

main() {
  // Make sure the "none" test fails if "??" is not implemented.  This makes
  // status files easier to maintain.
  var _ = null ?? null;

  // "a ?? b ?? c" should be legal, and should evaluate to the first non-null
  // value (or null if there are no non-null values).
  Expect.equals(1, 1 ?? 2 ?? 3); //# 01: ok
  Expect.equals(2, null ?? 2 ?? 3); //# 02: ok
  Expect.equals(3, null ?? null ?? 3); //# 03: ok
  Expect.equals(null, null ?? null ?? null); //# 04: ok

  // "a ?? b ? c : d" should parse as "(a ?? b) ? c : d", therefore provided
  // that a is true, b need not be a bool.  An incorrect parse of
  // "a ?? (b ? c : d)" would require b to be a bool to avoid a static type
  // warning.
  Expect.equals(2, true ?? 1 ? 2 : 3); //# 05: ok

  // "a ?? b || c" should parse as "a ?? (b || c)", therefore it's a static
  // type warning if b doesn't have type bool.  An incorrect parse of
  // "(a ?? b) || c" would allow b to have any type provided that a is bool.
  Expect.equals(false, false ?? 1 || true); //# 06: static type warning

  // "a || b ?? c" should parse as "(a || b) ?? c", therefore it is a static
  // type warning if b doesn't have type bool.  An incorrect parse of
  // "a || (b ?? c)" would allow b to have any type provided that c is bool.
  if (checkedMode) {
    Expect.throws(() => false || 1 ?? true, assertionError); //# 07: static type warning
  } else {
    Expect.equals(false, false || 1 ?? true); //               //# 07: continued
  }

  if (checkedMode) {
    // An incorrect parse of "a || (b ?? c)" would result in no checked-mode
    // error.
    Expect.throws(() => false || null ?? true, assertionError); //# 08: ok
  } else {
    // An incorrect parse of "a || (b ?? c)" would result in c being evaluated.
    int i = 0; //                                                 //# 08: continued
    Expect.equals(false, false || null ?? i++ == 0); //           //# 08: continued
    Expect.equals(0, i); //                                       //# 08: continued
  }
}
