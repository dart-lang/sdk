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
import 'package:gardening/src/bot.dart';
import 'package:gardening/src/buildbot_data.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/util.dart';

void help(ArgParser argParser) {
  print('Displays the current status of specific tests on the buildbot');
  print('The test-names may be fully qualified (such as in ');
  print('"pkg/front_end/test/token_test") or just be a substring of the fully');
  print(' qualified name.');
  print('Usage: current_summary [options] <test-name1> [<test-name2> ...]');
  print('where options are:');
  print(argParser.usage);
}

Future main(List<String> args) async {
  ArgParser argParser = createArgParser();
  argParser.addOption('group',
      help: "Restricts the build groups\n"
          "to be searched for the results of the given test\n"
          "to those containing the given substring, case insensitive.");
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);

  Bot bot = new Bot(logdog: argResults['logdog']);

  if (argResults.rest.length == 0 || argResults['help']) {
    help(argParser);
    if (argResults['help']) return;
    exit(1);
  }
  int maxStatusWidth = 0;
  int maxConfigWidth = 0;

  Map<String, Map<BuildUri, TestStatus>> resultMap =
      <String, Map<BuildUri, TestStatus>>{};

  bool testsFound = false;
  List<BuildGroup> notFoundGroups = <BuildGroup>[];
  for (BuildGroup group in buildGroups) {
    if (argResults['group'] != null &&
        !containsIgnoreCase(group.groupName, argResults['group'])) {
      log('Skipping group $group');
      continue;
    }
    List<BuildUri> uriList = group.createUris(bot.mostRecentBuildNumber);
    if (uriList.isEmpty) continue;
    print('Fetching "${uriList.first}" + ${uriList.length - 1} more ...');
    List<BuildResult> results = await bot.readResults(uriList);
    bool testsFoundInGroup = false;
    for (BuildResult buildResult in results) {
      if (buildResult == null) continue;
      var buildUri = buildResult.buildUri;
      for (TestStatus testStatus in buildResult.results) {
        String testName = testStatus.config.testName;
        for (String arg in argResults.rest) {
          if (testName.contains(arg) || arg.contains(testName)) {
            testsFoundInGroup = true;
            resultMap.putIfAbsent(testName, () => {})[buildUri] = testStatus;
            maxStatusWidth = max(maxStatusWidth, testStatus.status.length);
            maxConfigWidth =
                max(maxConfigWidth, testStatus.config.configName.length);
          }
        }
      }
    }
    if (testsFoundInGroup) {
      testsFound = true;
    } else {
      notFoundGroups.add(group);
    }
  }
  print('');
  if (testsFound) {
    resultMap.forEach((String testName, Map<BuildUri, TestStatus> statusMap) {
      print(testName);
      statusMap.forEach((BuildUri buildUri, TestStatus status) {
        print('  ${padRight(status.status, maxStatusWidth)}: '
            '${padRight(status.config.configName, maxConfigWidth)} '
            '${buildUri.shortBuildName}');
      });
    });
    if (notFoundGroups.isNotEmpty) {
      if (argResults.rest.length == 1) {
        print("Test pattern '${argResults.rest.single}' not found "
            "in these build bot groups:");
      } else {
        print("Test patterns '${argResults.rest.join("', '")}' not found "
            "in these build bot groups:");
      }
      for (BuildGroup group in notFoundGroups) {
        print(' $group');
      }
    }
  } else {
    if (argResults.rest.length == 1) {
      print("Test pattern '${argResults.rest.single}' not found "
          "in any build bot groups.");
    } else {
      print("Test patterns '${argResults.rest.join("', '")}' not found "
          "in any build bot groups.");
    }
  }
  bot.close();
}
