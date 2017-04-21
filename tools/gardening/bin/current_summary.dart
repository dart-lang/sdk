// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Collects the test results for all build bots in [buildGroups] for tests
/// that mention one of the test names given as argument.
///
/// The results are currently pulled from the second to last build since the
/// last build might not have completed yet.

import 'dart:math';
import 'dart:io';

import 'package:gardening/src/buildbot_data.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/util.dart';

main(List<String> args) async {
  if (args.length == 0) {
    print('Usage: current_summary <test-name1> [<test-name2> ...]');
    exit(1);
  }
  int maxStatusWidth = 0;
  int maxConfigWidth = 0;

  HttpClient client = new HttpClient();
  Map<String, Map<BuildUri, TestStatus>> resultMap =
      <String, Map<BuildUri, TestStatus>>{};
  for (BuildGroup group in buildGroups) {
    // TODO(johnniwinther): Support reading a partially completed shard, i.e.
    // use build number `-1`.
    for (BuildUri buildUri in group.createUris(-2)) {
      print('Reading $buildUri');
      String text = await readUriAsText(client, buildUri.toUri());
      for (String line in text.split('\n')) {
        if (line.startsWith('Done ')) {
          List<String> parts = split(line, ['Done ', ' ', ' ', ': ']);
          String testName = parts[3];
          String configName = parts[1];
          String archName = parts[2];
          String status = parts[4];
          TestStatus testStatus = new TestStatus(
              new TestConfiguration(configName, archName, testName), status);
          for (String arg in args) {
            if (testName.contains(arg) || arg.contains(testName)) {
              resultMap.putIfAbsent(testName, () => {})[buildUri] = testStatus;
              maxStatusWidth = max(maxStatusWidth, status.length);
              maxConfigWidth = max(maxConfigWidth, configName.length);
            }
          }
        }
      }
    }
  }
  print('');
  resultMap.forEach((String testName, Map<BuildUri, TestStatus> statusMap) {
    print(testName);
    statusMap.forEach((BuildUri buildUri, TestStatus status) {
      print('  ${padRight(status.status, maxStatusWidth)}: '
          '${padRight(status.config.configName, maxConfigWidth)} '
          '${buildUri.shortBuildName}');
    });
  });
  client.close();
}

/// The result of a single test for a single test step.
class TestStatus {
  final TestConfiguration config;
  final String status;

  TestStatus(this.config, this.status);

  String toString() => '$config: $status';
}
