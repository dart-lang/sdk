// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

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

enum RuntimePlatforms {
  chrome('chrome', true),
  d8('d8', true),
  vm('vm', false);

  const RuntimePlatforms(this.text, this.emitsJS);
  final String text;
  final bool emitsJS;
}

/// Encodes information provided in a hot_reload test's configuration file.
///
/// Example structure:
/// {
///   "exclude": ["vm", "chrome"]
/// }
class ReloadTestConfiguration {
  final Map<String, dynamic> _values;
  final Set<RuntimePlatforms> excludedPlaforms;
  final String? expectedError;

  ReloadTestConfiguration._(
      this._values, this.excludedPlaforms, this.expectedError);

  factory ReloadTestConfiguration() => ReloadTestConfiguration._(
      const <String, dynamic>{}, <RuntimePlatforms>{}, null);

  factory ReloadTestConfiguration.fromJsonFile(Uri file) {
    final Map<String, dynamic> jsonData =
        jsonDecode(File.fromUri(file).readAsStringSync());
    final excludedPlaforms = <RuntimePlatforms>{};
    var rawExcludedPlatforms = jsonData['exclude'];
    if (rawExcludedPlatforms != null) {
      for (final String platform in rawExcludedPlatforms) {
        final runtimePlatform = RuntimePlatforms.values.byName(platform);
        excludedPlaforms.add(runtimePlatform);
      }
    }
    return ReloadTestConfiguration._(
        jsonData, excludedPlaforms, jsonData['expectedError']);
  }

  String toJson() {
    return JsonEncoder().convert(_values);
  }
}
