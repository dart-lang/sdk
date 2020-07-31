// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that '??' binds tighter than '?:' and less tightly than '||'.

import "package:expect/expect.dart";

main() {
  // Make sure the "none" test fails if "??" is not implemented.  This makes
  // status files easier to maintain.
  var _ = null ?? null;

  dynamic falsity = false;
  dynamic truth = true;
  dynamic one = 1;
  dynamic two = 2;
  dynamic nil = null;

  // "a ?? b ?? c" should be legal, and should evaluate to the first non-null
  // value (or null if there are no non-null values).
  Expect.equals(1, one ?? 2 ?? 3);
  Expect.equals(2, null ?? two ?? 3);
  Expect.equals(3, null ?? null ?? 3);
  Expect.equals(null, null ?? null ?? null);

  // "a ?? b ? c : d" should parse as "(a ?? b) ? c : d", therefore provided
  // that a is true, b need not be a bool.  An incorrect parse of
  // "a ?? (b ? c : d)" would require b to be a bool to avoid a static type
  // warning.
  Expect.equals(2, truth ?? one ? 2 : 3);
}
