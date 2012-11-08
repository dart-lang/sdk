#!/usr/bin/env dart
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library string_encoding_run_tests;
import 'dunit.dart';
import 'unicode_test.dart' as u;
import 'unicode_core_test.dart' as uc;
import 'utf16_test.dart' as utf16;
import 'utf32_test.dart' as utf32;
import 'utf8_test.dart' as utf8;

void main() {
  TestSuite suite = new TestSuite();
  registerTests(suite);
  suite.run();
}

void registerTests(TestSuite suite) {
  suite.registerTestClass(new u.UnicodeTests());
  suite.registerTestClass(new uc.UnicodeCoreTests());
  suite.registerTestClass(new utf16.Utf16Tests());
  suite.registerTestClass(new utf32.Utf32Tests());
  suite.registerTestClass(new utf8.Utf8Tests());
}
