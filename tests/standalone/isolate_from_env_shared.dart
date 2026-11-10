// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void checkEnv() {
  // Test runtime lookups (non-const) in the calling isolate.
  Expect.isTrue(bool.hasEnvironment("testString"));
  Expect.equals(
    "testValue",
    String.fromEnvironment("testString", defaultValue: "nonce"),
  );

  Expect.isTrue(bool.hasEnvironment("testInt"));
  Expect.equals("-0xfeed", String.fromEnvironment("testInt"));
  Expect.equals(-0xfeed, int.fromEnvironment("testInt", defaultValue: 4));

  Expect.isTrue(bool.hasEnvironment("testBool"));
  Expect.equals("false", String.fromEnvironment("testBool"));
  Expect.equals(false, bool.fromEnvironment("testBool", defaultValue: true));

  Expect.isFalse(bool.hasEnvironment("noEntry"));
  Expect.equals(
    "nonce",
    String.fromEnvironment("noEntry", defaultValue: "nonce"),
  );
  Expect.equals(42, int.fromEnvironment("noEntry", defaultValue: 42));
  Expect.isTrue(bool.fromEnvironment("noEntry", defaultValue: true));
}
