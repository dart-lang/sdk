// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Loads the times it takes to run each test from the previous results.json in
/// [path] on the [configuration] for the tests matching the regular expression
/// for each suite in [selectors].
Map<String, int> loadTestTimes(
    String path, String configuration, Map<String, RegExp> selectors) {
  final times = <String, int>{};
  for (final line in File(path).readAsLinesSync()) {
    final result = jsonDecode(line) as Map<String, dynamic>;
    final suite = result['suite'] as String;
    final name = result['name'] as String;
    if (result['configuration'] == configuration &&
        selectors.containsKey(suite) &&
        selectors[suite]!.hasMatch(name)) {
      times[name] = result['time_ms'] as int;
    }
  }
  return times;
}

/// Balances the shards to have equal run time using the [testTimes] timings for
/// each test, across [shardCount] shards each able to run [taskCount] tasks
/// concurrently.
///
/// The previous test results are used for the timings, if a test is new and
/// doesn't have a timing, then it isn't allocated a shard. Instead the test
/// falls back on the traditional behavior of assigning it to a shard based on
/// the hash of the file path.
///
/// Returns a map of test name to its shard (zero based) and a list of how long
/// each shard is expected to take.
(Map<String, int>, List<Duration>) balanceShards(
    Map<String, int> testTimes, int shardCount, int taskCount) {
  final shardOfTests = <String, int>{};
  // Predict N shards with M cores each.
  final cores = shardCount * taskCount;
  final coreDurations = List.filled(cores, 0);
  // Greedily assign the longest running tests first.
  final sorted = testTimes.keys.toList()
    ..sort((a, b) => testTimes[b]!.compareTo(testTimes[a]!));
  for (final test in sorted) {
    final timeMs = testTimes[test]!;
    var minMs = 0;
    var minCore = 0;
    // Assign the test to the core that would finish the earliest with the test.
    for (var n = 0; n < cores; n++) {
      if (n == 0 || coreDurations[n] + timeMs < minMs) {
        minMs = coreDurations[n] + timeMs;
        minCore = n;
      }
    }
    // Assign the test to the shard associated with the core.
    coreDurations[minCore] += timeMs;
    shardOfTests[test] = minCore ~/ taskCount;
  }
  // Calculate how long each shard would run as its longest running core.
  final shardDurations = [
    for (var i = 0; i < shardCount; i++)
      Duration(
          milliseconds: coreDurations
              .sublist(i * taskCount, (i + 1) * taskCount)
              .reduce(max))
  ];
  return (shardOfTests, shardDurations);
}
