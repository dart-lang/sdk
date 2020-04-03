// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartfix/src/driver.dart';
import 'package:dartfix/src/options.dart';
import 'package:test/test.dart';

import 'test_context.dart';

void main() {
  test('help explicit', () async {
    final driver = Driver();
    final testContext = TestContext();
    final testLogger = TestLogger();
    try {
      await driver.start(
        ['--help'], // display help and list fixes
        testContext: testContext,
        testLogger: testLogger,
      );
      fail('expected exception');
    } on TestExit catch (e) {
      expect(e.code, 0);
    }
    final errText = testLogger.stderrBuffer.toString();
    final outText = testLogger.stdoutBuffer.toString();
    expect(errText, isEmpty);
    expect(outText, contains('--$excludeFixOption'));
    expect(outText, isNot(contains('Use --help to display the fixes')));
  });

  test('help implicit', () async {
    final driver = Driver();
    final testContext = TestContext();
    final testLogger = TestLogger();
    try {
      await driver.start(
        [], // no options or arguments should display help and list fixes
        testContext: testContext,
        testLogger: testLogger,
      );
      fail('expected exception');
    } on TestExit catch (e) {
      expect(e.code, 0);
    }
    final errText = testLogger.stderrBuffer.toString();
    final outText = testLogger.stdoutBuffer.toString();
    print(errText);
    print(outText);
    expect(errText, isEmpty);
    expect(outText, contains('--$excludeFixOption'));
    expect(outText, isNot(contains('Use --help to display the fixes')));
  });
}
