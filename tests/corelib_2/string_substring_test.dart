// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // Test that not providing an optional argument goes to the end.
  Expect.equals("".substring(0), "");
  Expect.throwsRangeError(() => "".substring(1));
  Expect.throwsRangeError(() => "".substring(-1));

  Expect.equals("abc".substring(0), "abc");
  Expect.equals("abc".substring(1), "bc");
  Expect.equals("abc".substring(2), "c");
  Expect.equals("abc".substring(3), "");
  Expect.throwsRangeError(() => "abc".substring(4));
  Expect.throwsRangeError(() => "abc".substring(-1));

  // Test that providing null goes to the end.
  Expect.equals("".substring(0, null), "");
  Expect.throwsRangeError(() => "".substring(1, null));
  Expect.throwsRangeError(() => "".substring(-1, null));

  Expect.equals("abc".substring(0, null), "abc");
  Expect.equals("abc".substring(1, null), "bc");
  Expect.equals("abc".substring(2, null), "c");
  Expect.equals("abc".substring(3, null), "");
  Expect.throwsRangeError(() => "abc".substring(4, null));
  Expect.throwsRangeError(() => "abc".substring(-1, null));
}
