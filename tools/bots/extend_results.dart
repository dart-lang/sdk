// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Add fields with data about the test run and the commit tested, and
// with the result on the last build tested, to the test results file.

// @dart = 2.9

import 'dart:convert';
import 'dart:io';

import 'package:test_runner/bot_results.dart';

const skipped = 'skipped';

main(List<String> args) async {
  final resultsPath = args[0];
  final priorResultsPath = args[1];
  final flakyPath = args[2];
  final priorFlakyPath = args[3];
  final builderName = args[4];
  final buildNumber = args[5];
  final commitTime = int.parse(args[6]);
  final commitHash = args[7];
  final newResultsPath = args[8];
  // Load the input and the flakiness data if specified.
  final results = await loadResultsMap(resultsPath);
  final priorResults = await loadResultsMap(priorResultsPath);
  final flakes = await loadResultsMap(flakyPath);
  final priorFlakes = await loadResultsMap(priorFlakyPath);
  final firstPriorResult =
      priorResults.isEmpty ? null : priorResults.values.first;

  priorResults.forEach((key, priorResult) {
    if (priorResult['result'] != skipped) {
      results.putIfAbsent(key, () => constructNotRunResult(priorResult));
    }
  });
  for (final String key in results.keys) {
    final Map<String, dynamic> result = results[key];
    final Map<String, dynamic> priorResult = priorResults[key];
    final Map<String, dynamic> flaky = flakes[key];
    final Map<String, dynamic> priorFlaky = priorFlakes[key];
    result['commit_hash'] = commitHash;
    result['commit_time'] = commitTime;
    result['build_number'] = buildNumber;
    result['builder_name'] = builderName;
    result['flaky'] = flaky != null && (flaky['active'] ?? true) == true;
    result['previous_flaky'] =
        priorFlaky != null && (priorFlaky['active'] ?? true) == true;
    if (firstPriorResult != null) {
      result['previous_commit_hash'] = firstPriorResult['commit_hash'];
      result['previous_commit_time'] = firstPriorResult['commit_time'];
      result['previous_build_number'] = firstPriorResult['build_number'];
    }
    if (priorResult != null) {
      result['previous_result'] = priorResult['result'];
    }
    result['changed'] = (result['result'] != result['previous_result'] ||
        result['flaky'] != result['previous_flaky']);
  }
  final sink = new File(newResultsPath).openWrite();
  final sorted = results.keys.toList()..sort();
  for (final key in sorted) {
    sink.writeln(jsonEncode(results[key]));
  }
  sink.close();
}

Map<String, dynamic> constructNotRunResult(Map<String, dynamic> previous) => {
      for (final key in [
        'name',
        'configuration',
        'suite',
        'test_name',
        'expected'
      ])
        key: previous[key],
      'time_ms': 0,
      'result': skipped,
      'matches': true,
      'bot_name': '',
    };
