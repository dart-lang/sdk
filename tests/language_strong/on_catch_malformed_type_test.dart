// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that malformed types in on-catch are handled correctly, that is,
// throws a type error in both production and checked mode.

import 'package:expect/expect.dart';

catchUnresolvedBefore() {
  try {
    throw "foo";
    Expect.fail("This code shouldn't be executed");
  } on String catch (oks) {
    // This is tested before the catch block below.
  } on Unavailable catch (ex) {
    Expect.fail("This code shouldn't be executed");
  }
}

catchUnresolvedAfter() {
  Expect.throws(() {
    try {
      throw "foo";
      Expect.fail("This code shouldn't be executed");
    } on Unavailable catch (ex) {
      // This is tested before the catch block below.
      // In both production and checked mode the test causes a type error.
    } on String catch (oks) {
      Expect.fail("This code shouldn't be executed");
    }
  }, (e) => e is TypeError);
}

main() {
  catchUnresolvedBefore();
  catchUnresolvedAfter();
}
