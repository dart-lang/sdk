// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class UnicodeTest {
  static testMain() {
    var lowerStrasse = new String.fromCharCodes([115, 116, 114, 97, 223, 101]);
    Expect.equals("STRASSE", lowerStrasse.toUpperCase());
  }
}

main() {
  UnicodeTest.testMain();
}
