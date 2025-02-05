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
    this.suiteName = 'hot_reload',
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
        'matches': matchedExpectations,
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

/// Encodes information provided in a hot_reload test's config.json file.
///
/// The following keys are supported:
///
/// - "exclude": A list of strings that specify the names of the platforms that
///   should not run this test. The runtime names must match the enum values in
///   [RuntimePlatforms].
/// - "expectedErrors": A map of strings to strings that specifies file
///   generations expected to be rejected as not viable for hot reload and the
///   error text associated with their rejection messages.
///
/// Example structure:
/// {
///   "exclude": ["vm", "chrome"]
///   "expectedErrors": {"1": "You wouldn't hot reload a car"}
/// }
class ReloadTestConfiguration {
  final Set<RuntimePlatforms> excludedPlatforms;
  final Map<int, String> expectedErrors;

  ReloadTestConfiguration._(this.excludedPlatforms, this.expectedErrors);

  factory ReloadTestConfiguration() => ReloadTestConfiguration._(
      const <RuntimePlatforms>{}, const <int, String>{});

  factory ReloadTestConfiguration.fromJsonFile(Uri file) {
    final Map<String, dynamic> jsonData =
        jsonDecode(File.fromUri(file).readAsStringSync());
    final excludedPlatforms = <RuntimePlatforms>{};
    final rawExcludedPlatforms = jsonData['exclude'];
    if (rawExcludedPlatforms != null) {
      for (final String platform in rawExcludedPlatforms) {
        final runtimePlatform = RuntimePlatforms.values.byName(platform);
        excludedPlatforms.add(runtimePlatform);
      }
    }
    final expectedErrors = <int, String>{};
    final rawExpectedErrors =
        jsonData['expectedErrors'] as Map<String, dynamic>?;
    if (rawExpectedErrors != null) {
      for (final entry in rawExpectedErrors.entries) {
        expectedErrors[int.parse(entry.key)] = entry.value as String;
      }
    }
    return ReloadTestConfiguration._(
      excludedPlatforms,
      expectedErrors,
    );
  }
}
