// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartfix/src/driver.dart';
import 'package:test/test.dart';

import 'test_context.dart';

const _debug = false;

main() {
  File exampleFile;
  Directory exampleDir;

  test('include fix', () async {
    exampleFile = findFile('pkg/dartfix/example/example.dart');
    exampleDir = exampleFile.parent;

    final driver = Driver();
    final testContext = TestContext();
    final testLogger = TestLogger();
    String exampleSource = await exampleFile.readAsString();

    await driver.start(['--fix', 'use-mixin', exampleDir.path],
        testContext: testContext, testLogger: testLogger);
    if (_debug) {
      print(testLogger.stderrBuffer.toString());
      print(testLogger.stdoutBuffer.toString());
      print('--- original example');
      print(exampleSource);
    }

    final suggestions = driver.result.suggestions;
    expect(suggestions, hasLength(1));
    expectHasSuggestion(suggestions, 'Convert MyMixin to a mixin');
    expectDoesNotHaveSuggestion(suggestions, 'Replace a double literal');
  });
}
