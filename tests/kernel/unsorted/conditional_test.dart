// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of conditional expressions and statements and negation.

import 'package:expect/expect.dart';

mkTrue() => true;
mkFalse() => false;

check(b) {
  Expect.isTrue(b);
  return b;
}

main() {
  // Check that ?: gets the right answer.
  Expect.isTrue((mkTrue() ? 0 : 1) == 0);
  Expect.isTrue((mkFalse() ? 0 : 1) == 1);
  // Check that it doesn't evaluate all subexpressions.
  mkTrue() ? Expect.isTrue(true) : Expect.isTrue(false);
  mkFalse() ? Expect.isTrue(false) : Expect.isTrue(true);

  // Check that && and || get the right answers.
  Expect.isTrue(mkTrue() && mkTrue());
  Expect.isTrue(!(mkTrue() && mkFalse()));
  Expect.isTrue(!(mkFalse() && mkTrue()));
  Expect.isTrue(!(mkFalse() && mkFalse()));
  Expect.isTrue(mkTrue() || mkTrue());
  Expect.isTrue(mkTrue() || mkFalse());
  Expect.isTrue(mkFalse() || mkTrue());
  Expect.isTrue(!(mkFalse() || mkFalse()));

  // Check that they don't evaluate both subexpressions.
  mkTrue() && check(true);
  mkFalse() && check(false);
  mkTrue() || check(true);
  mkFalse() || check(true);

  // Check that if works.
  if (mkTrue()) {
    Expect.isTrue(true);
  } else {
    Expect.isTrue(false);
  }
  if (mkFalse()) {
    Expect.isTrue(false);
  } else {
    Expect.isTrue(true);
  }
  if (!mkTrue()) {
    Expect.isTrue(false);
  } else {
    Expect.isTrue(true);
  }
  if (!mkFalse()) {
    Expect.isTrue(true);
  } else {
    Expect.isTrue(false);
  }

  // Check that ?:, &&, and || work for control flow.
  if (mkTrue() ? mkTrue() : mkFalse()) {
    Expect.isTrue(true);
  } else {
    Expect.isTrue(false);
  }
  if (mkTrue() ? mkFalse() : mkTrue()) {
    Expect.isTrue(false);
  } else {
    Expect.isTrue(true);
  }
  if (mkFalse() ? mkTrue() : mkFalse()) {
    Expect.isTrue(false);
  } else {
    Expect.isTrue(true);
  }
  if (mkFalse() ? mkFalse() : mkTrue()) {
    Expect.isTrue(true);
  } else {
    Expect.isTrue(false);
  }
  if (mkTrue() && mkTrue()) {
    Expect.isTrue(true);
  } else {
    Expect.isTrue(false);
  }
  if (mkTrue() && mkFalse()) {
    Expect.isTrue(false);
  } else {
    Expect.isTrue(true);
  }
  if (mkFalse() && mkTrue()) {
    Expect.isTrue(false);
  } else {
    Expect.isTrue(true);
  }
  if (mkFalse() && mkFalse()) {
    Expect.isTrue(false);
  } else {
    Expect.isTrue(true);
  }
  if (mkTrue() || mkTrue()) {
    Expect.isTrue(true);
  } else {
    Expect.isTrue(false);
  }
  if (mkTrue() || mkFalse()) {
    Expect.isTrue(true);
  } else {
    Expect.isTrue(false);
  }
  if (mkFalse() || mkTrue()) {
    Expect.isTrue(true);
  } else {
    Expect.isTrue(false);
  }
  if (mkFalse() || mkFalse()) {
    Expect.isTrue(false);
  } else {
    Expect.isTrue(true);
  }

  // Test empty else branches.
  if (mkTrue()) {
    Expect.isTrue(true);
  }
  if (mkFalse()) {
    Expect.isTrue(false);
  }

  var x = 0;
  if (mkTrue()) {
    x = 1;
  }
  Expect.isTrue(x == 1);
  if (mkFalse()) {
    x = 2;
  }
  Expect.isTrue(x == 1);
}
