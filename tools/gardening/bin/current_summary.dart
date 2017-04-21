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

import 'package:args/args.dart';
import 'package:gardening/src/buildbot_data.dart';
import 'package:gardening/src/buildbot_loading.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/util.dart';

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);
  if (argResults.rest.length == 0) {
    print('Usage: current_summary [options] <test-name1> [<test-name2> ...]');
    print('where options are:');
    print(argParser.usage);
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
      BuildResult buildResult = await readBuildResult(client, buildUri);
      for (TestStatus testStatus in buildResult.results) {
        String testName = testStatus.config.testName;
        for (String arg in argResults.rest) {
          if (testName.contains(arg) || arg.contains(testName)) {
            resultMap.putIfAbsent(testName, () => {})[buildUri] = testStatus;
            maxStatusWidth = max(maxStatusWidth, testStatus.status.length);
            maxConfigWidth =
                max(maxConfigWidth, testStatus.config.configName.length);
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
