// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

class TestResultOutcome {
  // This encoder must generate each output element on its own line.
  final _encoder = JsonEncoder();
  final String configuration;
  final String suiteName;
  final String testName;
  late Duration elapsedTime;
  final String expectedResult;
  late bool matchedExpectations;
  String testOutput;

  TestResultOutcome({
    required this.configuration,
    this.suiteName = 'tests/reload',
    required this.testName,
    this.expectedResult = 'Pass',
    this.testOutput = '',
  });

  String toRecordJson() => _encoder.convert({
        'name': '$suiteName/$testName',
        'configuration': configuration,
        'suite': suiteName,
        'test_name': testName,
        'time_ms': elapsedTime.inMilliseconds,
        'expected': expectedResult,
        'result': matchedExpectations ? 'Pass' : 'Fail',
        'matches': expectedResult == expectedResult,
      });

  String toLogJson() => _encoder.convert({
        'name': '$suiteName/$testName',
        'configuration': configuration,
        'result': matchedExpectations ? 'Pass' : 'Fail',
        'log': testOutput,
      });
}

/// Escapes backslashes in [unescaped].
///
/// Used for wrapping Windows-style paths.
String escapedString(String unescaped) {
  return unescaped.replaceAll(r'\', r'\\');
}
