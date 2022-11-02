// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:expect/config.dart';

main() {
  const NOT_PRESENT = false;

  Expect.isTrue(const bool.fromEnvironment("dart.library.async"));
  Expect.isTrue(const bool.fromEnvironment("dart.library.collection"));
  Expect.isTrue(const bool.fromEnvironment("dart.library.convert"));
  Expect.isTrue(const bool.fromEnvironment("dart.library.core"));
  Expect.isTrue(const bool.fromEnvironment("dart.library.typed_data"));
  Expect.isTrue(const bool.fromEnvironment("dart.library.developer"));

  // Internal libraries should not be exposed.
  Expect.equals(
      NOT_PRESENT,
      const bool.fromEnvironment("dart.library._internal",
          defaultValue: NOT_PRESENT));

  bool htmlSupportExpected = isDart2jsConfiguration || isDdcConfiguration;
  bool? hasHtmlSupport;
  hasHtmlSupport = htmlSupportExpected; //# has_html_support: ok

  if (hasHtmlSupport != null) {
    bool expectedResult = hasHtmlSupport ? true : NOT_PRESENT;

    Expect.equals(
        expectedResult,
        const bool.fromEnvironment("dart.library.html",
            defaultValue: NOT_PRESENT));
    Expect.equals(
        expectedResult,
        const bool.fromEnvironment("dart.library.indexed_db",
            defaultValue: NOT_PRESENT));
    Expect.equals(
        expectedResult,
        const bool.fromEnvironment("dart.library.svg",
            defaultValue: NOT_PRESENT));
    Expect.equals(
        expectedResult,
        const bool.fromEnvironment("dart.library.web_audio",
            defaultValue: NOT_PRESENT));
    Expect.equals(
        expectedResult,
        const bool.fromEnvironment("dart.library.web_gl",
            defaultValue: NOT_PRESENT));
  }

  bool ioSupportExpected = !isDart2jsConfiguration &&
      !isDdcConfiguration &&
      !isVmAotConfiguration &&
      !isDart2WasmConfiguration;
  bool? hasIoSupport;
  hasIoSupport =  ioSupportExpected; //# has_io_support: ok

  if (hasIoSupport != null) {
    // Web platforms override 'dart.library.io' to return "false".
    // We don't test for the non-existence, but just make sure that
    // dart.library.io is not set to true.
    Expect.equals(hasIoSupport,
        const bool.fromEnvironment("dart.library.io", defaultValue: false));
  }

  bool hasMirrorSupport = !isDart2jsConfiguration &&
      !isDdcConfiguration && !isVmAotConfiguration && !isDart2WasmConfiguration;
  Expect.equals(
      hasMirrorSupport,
      const bool.fromEnvironment("dart.library.mirrors",
          defaultValue: NOT_PRESENT));

  Expect.equals(
      NOT_PRESENT,
      const bool.fromEnvironment("dart.library.XYZ",
          defaultValue: NOT_PRESENT));
  Expect.equals(
      NOT_PRESENT,
      const bool.fromEnvironment("dart.library.Collection",
          defaultValue: NOT_PRESENT));
  Expect.equals(
      NOT_PRESENT,
      const bool.fromEnvironment("dart.library.converT",
          defaultValue: NOT_PRESENT));
  Expect.equals(NOT_PRESENT,
      const bool.fromEnvironment("dart.library.", defaultValue: NOT_PRESENT));
  Expect.equals(
      NOT_PRESENT,
      const bool.fromEnvironment("dart.library.core ",
          defaultValue: NOT_PRESENT));
}
