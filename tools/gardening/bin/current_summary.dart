// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Collects the test results for all build bots in [buildGroups] for tests
/// that mention one of the test names given as argument.
///
/// The results are currently pulled from the second to last build since the
/// last build might not have completed yet.

import 'dart:async';
import 'dart:math' hide log;
import 'dart:io';

import 'package:args/args.dart';
import 'package:gardening/src/buildbot_data.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/client.dart';
import 'package:gardening/src/util.dart';

void help(ArgParser argParser) {
  print('Displays the current status of specific tests on the buildbot');
  print('Only prints output for failing tests.');
  print('The test-names may be fully qualified (such as in ');
  print('"pkg/front_end/test/token_test") or just be a substring of the fully');
  print(' qualified name.');
  print('Usage: current_summary [options] <test-name1> [<test-name2> ...]');
  print('where options are:');
  print(argParser.usage);
}

/// Checks that [haystack] contains substring [needle], case insensitive.
/// Throws an exception if either parameter is `null`.
bool containsIgnoreCase(String haystack, String needle) {
  if (haystack == null) {
    throw "Unexpected null as the first paramter value of containsIgnoreCase";
  }
  if (needle == null) {
    throw "Unexpected null as the second parameter value of containsIgnoreCase";
  }
  return haystack.toLowerCase().contains(needle.toLowerCase());
}

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  argParser.addOption('group',
      help: "Restricts the build groups\n"
          "to be searched for the results of the given test\n"
          "to those containing the given substring, case insensitive.");
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);

  BuildbotClient client = argResults['logdog']
      ? new LogdogBuildbotClient()
      : new HttpBuildbotClient();

  if (argResults.rest.length == 0 || argResults['help']) {
    help(argParser);
    if (argResults['help']) return;
    exit(1);
  }
  int maxStatusWidth = 0;
  int maxConfigWidth = 0;

  Map<String, Map<BuildUri, TestStatus>> resultMap =
      <String, Map<BuildUri, TestStatus>>{};
  for (BuildGroup group in buildGroups) {
    if (argResults['group'] != null &&
        !containsIgnoreCase(group.groupName, argResults['group'])) {
      continue;
    }
    // TODO(johnniwinther): Support reading a partially completed shard from
    // http, i.e. always use build number `-1`.
    var resultFutures =
        group.createUris(client.mostRecentBuildNumber).map((uri) {
      log('Fetching $uri');
      return client.readResult(uri);
    }).toList();
    var results = await Future.wait(resultFutures);
    for (BuildResult buildResult in results) {
      bool havePrintedUri = false;
      var buildUri = buildResult.buildUri;
      if (argResults['verbose']) {
        havePrintedUri = true;
        print('Reading $buildUri');
      }
      for (TestStatus testStatus in buildResult.results) {
        String testName = testStatus.config.testName;
        for (String arg in argResults.rest) {
          if (testName.contains(arg) || arg.contains(testName)) {
            if (!havePrintedUri) {
              havePrintedUri = true;
              print("$buildUri:");
            }
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
