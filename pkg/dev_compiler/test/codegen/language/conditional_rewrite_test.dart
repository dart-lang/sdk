// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that dart2js does not rewrite conditional into logical operators
// in cases where it changes which falsy value is returned.

posFalse(x, y) => x != null ? y : false;
negFalse(x, y) => x != null ? !y : false;
posNull(x, y) => x != null ? y : null;
negNull(x, y) => x != null ? !y : null;

main() {
  bool isCheckedMode = false;
  assert((isCheckedMode = true));

  Expect.equals(false, posFalse(null, false));
  Expect.equals(false, negFalse(null, false));
  Expect.equals(null, posNull(null, false));
  Expect.equals(null, negNull(null, false));

  Expect.equals(false, posFalse(null, true));
  Expect.equals(false, negFalse(null, true));
  Expect.equals(null, posNull(null, true));
  Expect.equals(null, negNull(null, true));

  Expect.equals(false, posFalse([], false));
  Expect.equals(true, negFalse([], false));
  Expect.equals(false, posNull([], false));
  Expect.equals(true, negNull([], false));

  Expect.equals(true, posFalse([], true));
  Expect.equals(false, negFalse([], true));
  Expect.equals(true, posNull([], true));
  Expect.equals(false, negNull([], true));

  if (!isCheckedMode) {
    Expect.equals(null, posFalse([], null));
    Expect.equals(true, negFalse([], null));
    Expect.equals(null, posNull([], null));
    Expect.equals(true, negNull([], null));

    var y = {};
    Expect.identical(y, posFalse([], y));
    Expect.equals(true, negFalse([], y));
    Expect.identical(y, posNull([], y));
    Expect.equals(true, negNull([], y));
  }
}
