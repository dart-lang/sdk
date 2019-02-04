// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartfix/src/driver.dart';
import 'package:test/test.dart';

import 'test_context.dart';

main() {
  test('list fixes', () async {
    final driver = new Driver();
    final testContext = new TestContext();
    final testLogger = new TestLogger();
    await driver.start(['--list'], // list fixes
        testContext: testContext,
        testLogger: testLogger);
    final errText = testLogger.stderrBuffer.toString();
    final outText = testLogger.stdoutBuffer.toString();
    print(errText);
    print(outText);
    expect(outText, contains('use-mixin'));
  });
}
