// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that used static consts are emitted.

import "package:expect/expect.dart";

class Guide {
  static const LTUAE = 42;
  static const TITLE = "Life, the Universe and Everything";
  static const EARTH = const {
    "Sector": "ZZ9 Plural Z Alpha",
    "Status": const ["Scheduled for demolition", "1978-03-08"],
    "Description": "Mostly harmless"
  };
}

main() {
  Expect.isTrue(42 == Guide.LTUAE);
  Expect.isTrue("1978-03-08" == Guide.EARTH["Status"][1]);
}
