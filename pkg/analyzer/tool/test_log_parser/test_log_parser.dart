// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// A simple command-line app that reads the content of a file containing the
/// output from `test.py` and performs some simple analysis of it.
main(List<String> args) async {
  if (args.length != 1) {
    print('Usage: dart test_log_parser logFilePath');
    return;
  }
  String filePath = args[0];
  List<String> output = new File(filePath).readAsLinesSync();
  int failureCount = 0;
  int index = 0;
  final int expectedPrefixLength = 'Expected: '.length;
  final int actualPrefixLength = 'Actual: '.length;
  TestResult currentResult;
  Map<String, List<TestResult>> testsByExpectedAndActual =
      <String, List<TestResult>>{};
  while (index < output.length) {
    String currentLine = output[index];
    if (currentLine.startsWith('FAILED:')) {
      failureCount++;
      String testName = currentLine.substring(currentLine.lastIndexOf(' ') + 1);
      String expected = output[index + 1].substring(expectedPrefixLength);
      String actual = output[index + 2].substring(actualPrefixLength);
      String key = '$expected-$actual';
      currentResult = new TestResult(testName, expected, actual);
      testsByExpectedAndActual
          .putIfAbsent(key, () => <TestResult>[])
          .add(currentResult);
      index += 3;
    } else if (currentLine.startsWith('stderr:')) {
      if (currentResult != null) {
        currentResult.message = output[index + 1];
        bool hasStackTrace = false;
        int endIndex = index + 1;
        while (endIndex < output.length) {
          String endLine = output[endIndex];
          if (endLine.startsWith('--- ')) {
            break;
          } else if (endLine.startsWith('#0')) {
            hasStackTrace = true;
          }
          endIndex++;
        }
        if (hasStackTrace) {
          currentResult.stackTrace = output.sublist(index + 1, endIndex - 2);
        }
        index = endIndex;
      }
    } else {
      index += 1;
    }
  }

  List<String> missingCodes = <String>[];
  for (List<TestResult> results in testsByExpectedAndActual.values) {
    for (TestResult result in results) {
      String message = result.message;
      if (message != null) {
        if (message.startsWith('Bad state: Unable to convert (')) {
          missingCodes.add(message);
        }
      }
    }
  }

  print('$failureCount failing tests:');
  print('');
  List<String> keys = testsByExpectedAndActual.keys.toList();
  keys.sort();
  for (String key in keys) {
    print(key);
    List<TestResult> results = testsByExpectedAndActual[key];
    results.sort((first, second) => first.testName.compareTo(second.testName));
    for (TestResult result in results) {
      if (result.message == null) {
        print('  ${result.testName}');
      } else {
        print('  ${result.testName} (${result.message})');
      }
    }
  }
  if (missingCodes.isNotEmpty) {
    missingCodes.sort();
    print('');
    print('Missing error codes (${missingCodes.length}):');
    for (String message in missingCodes) {
      print('  $message');
    }
  }
}

/// A representation of the result of a single test.
class TestResult {
  String testName;
  String expected;
  String actual;
  String message;
  List<String> stackTrace;

  TestResult(this.testName, this.expected, this.actual);
}
