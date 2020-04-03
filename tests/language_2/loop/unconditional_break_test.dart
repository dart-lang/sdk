// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to ensure that we get don't exceptions in the SSA verifier when
// generating phi for the return value of an inlined function that contains a
// loop that always breaks.
doWhileBreak() {
  do {
    break;
  } while (true);
}

main() {
  doWhileBreak();
}
