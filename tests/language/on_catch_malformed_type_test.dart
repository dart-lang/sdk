// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that malformed types in on-catch are handled correctly, that is
// catches all in production mode and throws a type error in checked mode.

isCheckedMode() {
  try {
    String s = 1;
    return false;
  } on TypeError catch(e) {
    return true;
  }
}

checkTypeError(f()) {
  if(isCheckedMode()) {
    try {
      f();
      Expect.fail("Type error expected in checking mode");
    } on TypeError catch(ok) {
    }
  } else {
    f();
  }
}

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
    // In production mode the test is always true, in checked mode
    // it throws a type error.
  } on String catch(oks) {
    Expect.fail("This code shouldn't be executed");
  }
}

main() {
  catchUnresolvedBefore();
  checkTypeError(catchUnresolvedAfter);
}
