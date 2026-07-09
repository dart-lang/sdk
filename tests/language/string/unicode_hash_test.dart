// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  Expect.equals("\u{10412}", "𐐒"); // Second string is literal U+10412.
  Expect.equals("\u{10412}".hashCode, "𐐒".hashCode);
}
