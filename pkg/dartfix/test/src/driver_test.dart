// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server_client/protocol.dart';
import 'package:dartfix/src/driver.dart';
import 'package:test/test.dart';

import 'test_context.dart';

void main() {
  defineDriverTests(
    name: 'default',
    options: [
      '--fix',
      'prefer_int_literals',
      '--fix',
      'convert_class_to_mixin'
    ],
    expectedSuggestions: [
      'Convert MyMixin to a mixin',
      'Convert to an int literal',
    ],
  );
}

void defineDriverTests({
  String name,
  List<String> options,
  List<String> expectedSuggestions,
  bool debug = false,
  bool updateExample = false,
}) {
  var fixFileName = 'example_$name.dart';

  File exampleFile;
  File exampleFixedFile;
  Directory exampleDir;

  setUp(() {
    exampleFile = findFile('pkg/dartfix/example/example.dart');
    exampleFixedFile = findFile('pkg/dartfix/fixed/$fixFileName');
    exampleDir = exampleFile.parent;
  });

  test('fix example - $name', () async {
    final driver = Driver();
    final testContext = TestContext();
    final testLogger = TestLogger(debug: debug);
    String exampleSource = await exampleFile.readAsString();

    await driver.start([if (debug) '-v', ...options, exampleDir.path],
        testContext: testContext, testLogger: testLogger);
    if (debug) {
      print(testLogger.stderrBuffer.toString());
      print(testLogger.stdoutBuffer.toString());
      print('--- original example');
      print(exampleSource);
    }

    expect(driver.result.edits, hasLength(1));
    for (SourceEdit edit in driver.result.edits[0].edits) {
      exampleSource = edit.apply(exampleSource);
    }
    if (debug) {
      print('--- fixed example');
      print(exampleSource);
    }

    final suggestions = driver.result.suggestions;
    for (var expectedSuggestion in expectedSuggestions) {
      expectHasSuggestion(suggestions, expectedSuggestion);
    }
    expect(suggestions, hasLength(expectedSuggestions.length));

    exampleSource = replaceLeadingComment(exampleSource);
    if (updateExample) {
      await exampleFixedFile.writeAsString(exampleSource);
    } else {
      final expectedSource = await exampleFixedFile.readAsString();
      expect(exampleSource, expectedSource);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('run example - $name', () async {
    if (debug) print('--- launching original example');
    final futureResult1 =
        Process.run(Platform.resolvedExecutable, [exampleFile.path]);

    if (debug) print('--- launching fixed example');
    final futureResult2 =
        Process.run(Platform.resolvedExecutable, [exampleFixedFile.path]);

    if (debug) print('--- waiting for original example');
    final result1 = await futureResult1;

    if (debug) print('--- waiting for fixed example');
    final result2 = await futureResult2;

    final stdout1 = result1.stdout;
    final stdout2 = result2.stdout;
    if (debug) {
      print('--- original example output');
      print(stdout1);
      print('--- fixed example output');
      print(stdout2);
    }
    expect(stdout1, stdout2);
  });
}

String replaceLeadingComment(String source) => source.replaceAll(
    '''
// This file contains code that is modified by running dartfix.
// After running dartfix, this content matches a file in the "fixed" directory.
'''
        .trim(),
    '''
// This file contains code that has been modified by running dartfix.
// See example.dart for the original unmodified code.
  '''
        .trim());
