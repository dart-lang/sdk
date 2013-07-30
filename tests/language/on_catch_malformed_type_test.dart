// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that malformed types in on-catch are handled correctly, that is,
// are treated as dynamic and thus catches all in bith production and checked
// mode.

catchUnresolvedBefore() {
  try {
    throw "foo";
    Expect.fail("This code shouldn't be executed");
  } on String catch(oks) {
    // This is tested before the catch block below.
  } on Unavailable catch(ex) {
    Expect.fail("This code shouldn't be executed");
  }
}

catchUnresolvedAfter() {
  try {
    throw "foo";
    Expect.fail("This code shouldn't be executed");
  } on Unavailable catch(ex) {
    // This is tested before the catch block below.
    // In both production and checked mode the test is always true.
  } on String catch(oks) {
    Expect.fail("This code shouldn't be executed");
  }
}

main() {
  catchUnresolvedBefore();
  catchUnresolvedAfter();
}
