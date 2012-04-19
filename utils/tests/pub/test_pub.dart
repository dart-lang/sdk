// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Test infrastructure for testing pub. Unlike typical unit tests, most pub
 * tests are integration tests that stage some stuff on the file system, run
 * pub, and then validate the results. This library provides an API to build
 * tests like that.
 */
#library('test_pub');

#import('dart:io');

#import('../../../lib/unittest/unittest.dart');
#import('../../lib/file_system.dart');

void testOutput(String description, List<String> pubArgs, String expected,
    [int exitCode = 0]) {
  asyncTest(description, 1, () {
    // Find a dart executable we can use to run pub. Uses the one that the
    // test infrastructure uses.
    final scriptDir = new File(new Options().script).directorySync().path;
    final platform = Platform.operatingSystem();
    final dartBin = joinPaths(scriptDir,
        '../../../tools/testing/bin/$platform/dart');

    // Find the main pub entrypoint.
    final pubPath = joinPaths(scriptDir, '../../pub/pub.dart');

    final args = [pubPath];
    args.addAll(pubArgs);

    final process = new Process.start(dartBin, args);
    final outStream = new StringInputStream(process.stdout);
    final output = <String>[];
    bool processDone = false;

    checkComplete() {
      if (!outStream.closed) return;
      if (!processDone) return;

      _validateOutput(expected, output);
      callbackDone();
    }

    process.stderr.pipe(stderr, close: false);

    outStream.onLine = () {
      output.add(outStream.readLine());
    };

    outStream.onClosed = checkComplete;

    process.onError = (error) {
      Expect.fail('Failed to run pub: $error');
      processDone = true;
    };

    process.onExit = (actualExitCode) {
      Expect.equals(actualExitCode, exitCode,
          'Pub returned exit code $actualExitCode, expected $exitCode.');
      processDone = true;
      checkComplete();
    };
  });
}

/**
 * Compares the [actual] output from running pub with [expectedText]. Ignores
 * leading and trailing whitespace differences and tries to report the
 * offending difference in a nice way.
 */
void _validateOutput(String expectedText, List<String> actual) {
  final expected = expectedText.split('\n');

  final length = Math.min(expected.length, actual.length);
  for (var i = 0; i < length; i++) {
    if (expected[i].trim() != actual[i].trim()) {
      Expect.fail(
        'Output line ${i + 1} was: ${actual[i]}\nexpected: ${expected[i]}');
    }
  }

  if (expected.length > actual.length) {
    final message = new StringBuffer();
    message.add('Missing expected output:\n');
    for (var i = actual.length; i < expected.length; i++) {
      message.add(expected[i]);
      message.add('\n');
    }

    Expect.fail(message.toString());
  }

  if (expected.length < actual.length) {
    final message = new StringBuffer();
    message.add('Unexpected output:\n');
    for (var i = expected.length; i < actual.length; i++) {
      message.add(actual[i]);
      message.add('\n');
    }

    Expect.fail(message.toString());
  }
}
