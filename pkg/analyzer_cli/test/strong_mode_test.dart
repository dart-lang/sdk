// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer_cli/src/driver.dart' show outSink;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_test.dart';

main() {
  defineReflectiveTests(StrongModeTest);
}

/// End-to-end test for strong checking.
///
/// Most strong mode tests are in Analyzer, but this verifies the option is
/// working and producing extra errors as expected.
///
/// Generally we don't want a lot of cases here as it requires spinning up a
/// full analysis context.
@reflectiveTest
class StrongModeTest extends BaseTest {
  test_producesStricterErrors() async {
    await drive('data/strong_example.dart');

    expect(exitCode, 3);
    var stdout = bulletToDash(outSink);
    expect(stdout, contains("isn't a valid override of"));
    expect(stdout, contains('error - The list literal type'));
    expect(stdout, contains('2 errors found'));
  }
}
