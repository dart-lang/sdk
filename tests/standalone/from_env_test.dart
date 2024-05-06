// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=-DtestFlag=testValue -DnumFlag=-0xfeed -DboolFlag=false

import "package:expect/expect.dart";

// Test that the `fromEnvironment`/`hasEnvironment` constructors
// agree between constant and runtime evaluation,
// both for platform-library detection entries and for normal entries.

main() {
  // User string entry, const.
  Expect.isTrue(const bool.hasEnvironment("testFlag"));
  Expect.equals("testValue",
      const String.fromEnvironment("testFlag", defaultValue: "nonce"));
  // User string entry, runtime.
  Expect.isTrue(bool.hasEnvironment("testFlag"));
  Expect.equals(
      "testValue", String.fromEnvironment("testFlag", defaultValue: "nonce"));

  // User number entry, const.
  Expect.isTrue(const bool.hasEnvironment("numFlag"));
  Expect.equals("-0xfeed", const String.fromEnvironment("numFlag"));
  Expect.equals(-0xfeed, const int.fromEnvironment("numFlag", defaultValue: 4));
  // User number entry, runtime.
  Expect.isTrue(bool.hasEnvironment("numFlag"));
  Expect.equals("-0xfeed", String.fromEnvironment("numFlag"));
  Expect.equals(-0xfeed, int.fromEnvironment("numFlag", defaultValue: 4));

  // User bool entry, const.
  Expect.isTrue(const bool.hasEnvironment("boolFlag"));
  Expect.equals("false", const String.fromEnvironment("boolFlag"));
  Expect.equals(
      false, const bool.fromEnvironment("boolFlag", defaultValue: true));
  // User bool entry, runtime.
  Expect.isTrue(bool.hasEnvironment("boolFlag"));
  Expect.equals("false", String.fromEnvironment("boolFlag"));
  Expect.equals(false, bool.fromEnvironment("boolFlag", defaultValue: true));

  // Missing user entry, const.
  Expect.isFalse(const bool.hasEnvironment("noEntry"));
  Expect.equals("", const String.fromEnvironment("noEntry"));
  Expect.equals(
      "nonce", const String.fromEnvironment("noEntry", defaultValue: "nonce"));
  Expect.equals(0, const int.fromEnvironment("noEntry"));
  Expect.equals(42, const int.fromEnvironment("noEntry", defaultValue: 42));
  Expect.isFalse(const bool.fromEnvironment("noEntry"));
  Expect.isTrue(const bool.fromEnvironment("noEntry", defaultValue: true));
  // Missing user entry, runtime.
  Expect.isFalse(bool.hasEnvironment("noEntry"));
  Expect.equals("", String.fromEnvironment("noEntry"));
  Expect.equals(
      "nonce", String.fromEnvironment("noEntry", defaultValue: "nonce"));
  Expect.equals(0, int.fromEnvironment("noEntry"));
  Expect.equals(42, int.fromEnvironment("noEntry", defaultValue: 42));
  Expect.isFalse(bool.fromEnvironment("noEntry"));
  Expect.isTrue(bool.fromEnvironment("noEntry", defaultValue: true));

  // General platform library entry, const.
  Expect.isTrue(const bool.hasEnvironment("dart.library.core"));
  Expect.equals("true",
      const String.fromEnvironment("dart.library.core", defaultValue: "nonce"));
  Expect.isTrue(
      const bool.fromEnvironment("dart.library.core", defaultValue: false));
  // General platform library entry, runtime.
  Expect.isTrue(bool.hasEnvironment("dart.library.core"));
  Expect.equals("true",
      String.fromEnvironment("dart.library.core", defaultValue: "nonce"));
  Expect.isTrue(bool.fromEnvironment("dart.library.core", defaultValue: false));

  // Standalone VM-specific library, const.
  Expect.isTrue(const bool.hasEnvironment("dart.library.io"));
  Expect.equals("true",
      const String.fromEnvironment("dart.library.io", defaultValue: "nonce"));
  Expect.isTrue(
      const bool.fromEnvironment("dart.library.io", defaultValue: false));
  // Standalone VM-specific library, runtime.
  Expect.isTrue(bool.hasEnvironment("dart.library.io"));
  Expect.equals(
      "true", String.fromEnvironment("dart.library.io", defaultValue: "nonce"));
  Expect.isTrue(bool.fromEnvironment("dart.library.io", defaultValue: false));

  // Web-specific library, not available here, const.
  Expect.isFalse(const bool.hasEnvironment("dart.library.html"));
  Expect.equals("", const String.fromEnvironment("dart.library.html"));
  Expect.equals("nonce",
      const String.fromEnvironment("dart.library.html", defaultValue: "nonce"));
  Expect.isFalse(const bool.fromEnvironment("dart.library.html"));
  Expect.isTrue(
      const bool.fromEnvironment("dart.library.html", defaultValue: true));
  // Web-specific library, not available here, runtime.
  Expect.isFalse(bool.hasEnvironment("dart.library.html"));
  Expect.equals("", String.fromEnvironment("dart.library.html"));
  Expect.equals("nonce",
      String.fromEnvironment("dart.library.html", defaultValue: "nonce"));
  Expect.isFalse(bool.fromEnvironment("dart.library.html"));
  Expect.isTrue(bool.fromEnvironment("dart.library.html", defaultValue: true));

  // Non-existing library, const.
  Expect.isFalse(const bool.hasEnvironment("dart.library.not"));
  Expect.equals("", const String.fromEnvironment("dart.library.not"));
  Expect.equals("nonce",
      const String.fromEnvironment("dart.library.not", defaultValue: "nonce"));
  Expect.isFalse(const bool.fromEnvironment("dart.library.not"));
  Expect.isTrue(
      const bool.fromEnvironment("dart.library.not", defaultValue: true));
  // Non-existing library, runtime.
  Expect.isFalse(bool.hasEnvironment("dart.library.not"));
  Expect.equals("", String.fromEnvironment("dart.library.not"));
  Expect.equals("nonce",
      String.fromEnvironment("dart.library.not", defaultValue: "nonce"));
  Expect.isFalse(bool.fromEnvironment("dart.library.not"));
  Expect.isTrue(bool.fromEnvironment("dart.library.not", defaultValue: true));
}
