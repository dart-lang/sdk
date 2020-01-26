// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartfix/src/driver.dart';
import 'package:test/test.dart';

import 'test_context.dart';

void main() {
  File exampleFile;
  Directory exampleDir;

  test('include fix', () async {
    exampleFile = findFile('pkg/dartfix/example/example.dart');
    exampleDir = exampleFile.parent;

    final driver = Driver();
    final testContext = TestContext();
    final testLogger = TestLogger(debug: _debug);
    String exampleSource = await exampleFile.readAsString();

    try {
      await driver.start([
        if (_debug) '-v',
        '--fix',
        'prefer_int_literals',
        exampleDir.path,
      ], testContext: testContext, testLogger: testLogger);
    } finally {
      if (_debug) {
        print(testLogger.stderrBuffer.toString());
        print(testLogger.stdoutBuffer.toString());
        print('--- original example');
        print(exampleSource);
      }
    }

    final suggestions = driver.result.suggestions;
    expect(suggestions, hasLength(1));
    expectHasSuggestion(suggestions, 'Convert to an int literal');
  }, timeout: const Timeout(Duration(minutes: 3)));
}

const _debug = true;
