// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:expect/config.dart';

main() {
  // Common libraries should appear on all backends.
  Expect.isTrue(const bool.fromEnvironment("dart.library.async"));
  Expect.isTrue(const bool.fromEnvironment("dart.library.collection"));
  Expect.isTrue(const bool.fromEnvironment("dart.library.convert"));
  Expect.isTrue(const bool.fromEnvironment("dart.library.core"));
  Expect.isTrue(const bool.fromEnvironment("dart.library.typed_data"));
  Expect.isTrue(const bool.fromEnvironment("dart.library.developer"));

  // Internal libraries should not be exposed.
  Expect.isFalse(const bool.fromEnvironment("dart.library._internal"));

  // `dart:html` is only supported on Dart2js and DDC.
  bool hasHtmlSupport = isDart2jsConfiguration || isDdcConfiguration;
  Expect.equals(
      hasHtmlSupport, const bool.fromEnvironment("dart.library.html"));
  Expect.equals(
      hasHtmlSupport, const bool.fromEnvironment("dart.library.indexed_db"));
  Expect.equals(hasHtmlSupport, const bool.fromEnvironment("dart.library.svg"));
  Expect.equals(
      hasHtmlSupport, const bool.fromEnvironment("dart.library.web_audio"));
  Expect.equals(
      hasHtmlSupport, const bool.fromEnvironment("dart.library.web_gl"));

  // All web backends support `dart:js_util`
  Expect.equals(
      isWebConfiguration, const bool.fromEnvironment("dart.library.js_util"));

  // Web platforms override 'dart.library.io' to return "false".
  // We don't test for the non-existence, but just make sure that
  // dart.library.io is not set to true.
  Expect.equals(
      isVmConfiguration, const bool.fromEnvironment("dart.library.io"));

  // `dart:mirrors` is only supported in JIT mode.
  Expect.equals(
      isVmJitConfiguration, const bool.fromEnvironment("dart.library.mirrors"));

  // `fromEnvironment` should return false for non-existing dart libraries.
  Expect.isFalse(const bool.fromEnvironment("dart.library.XYZ"));
  Expect.isFalse(const bool.fromEnvironment("dart.library.Collection"));
  Expect.isFalse(const bool.fromEnvironment("dart.library.converT"));
  Expect.isFalse(const bool.fromEnvironment("dart.library."));
  Expect.isFalse(const bool.fromEnvironment("dart.library.core "));
}
