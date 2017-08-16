// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Compares the test log of a build step with previous builds.
///
/// Use this to detect flakiness of failures, especially timeouts.

import 'dart:async';

import 'package:args/args.dart';
import 'package:expect/expect.dart';
import 'package:gardening/src/bot.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/client.dart';
import 'package:gardening/src/compare_failures_impl.dart';
import 'package:gardening/src/util.dart';

import 'test_client.dart';

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  argParser.addFlag('force', abbr: 'f');
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);

  await runSingleTests(argResults);
  await runGroupTests(argResults);
}

Future runGroupTests(ArgResults argResults) async {
  BuildbotClient client = argResults['logdog']
      ? new LogdogBuildbotClient()
      : new HttpBuildbotClient();
  Bot bot = new Bot.internal(client);
  await runGroupTest(bot, 'vm-kernel');
  bot.close();
}

Future runGroupTest(Bot bot, String testGroup) async {
  print('Testing group compare-failures: $testGroup runCount=1');
  Map<BuildUri, List<BuildResult>> buildResults =
      await loadBuildResults(bot, [testGroup], runCount: 1);
  print('- checking results for ${buildResults.keys}');
  buildResults.forEach((BuildUri buildUri, List<BuildResult> results) {
    Expect.isTrue(buildUri.buildNumber < 0,
        "Expected relative build number for $buildUri");
    for (BuildResult result in results) {
      Expect.isTrue(
          result.buildUri.buildNumber > 0,
          "Expected absolute build number for build result "
          "${result.buildUri}.");
      for (TestFailure failure in result.failures) {
        Expect.equals(
            result.buildUri.buildNumber,
            failure.uri.buildNumber,
            "Expected absolute build number for test failure "
            "'${failure.id}' from ${failure.uri}.");
      }
    }
  });
}

Future runSingleTests(ArgResults argResults) async {
  bool force = argResults['force'];

  BuildbotClient client = argResults['logdog']
      ? new LogdogBuildbotClient()
      : new TestClient(force: force);
  Bot bot = new Bot.internal(client);

  await runSingleTest(
      bot,
      'https://build.chromium.org/p/client.dart/builders/'
      'vm-kernel-linux-debug-x64-be/builds/1884/steps/'
      'vm%20tests/logs/stdio',
      1,
      {
        1884: {
          'dartk-vm debug_x64 corelib_2/map_keys2_test': 'RuntimeError/Pass',
        },
        1883: {
          'dartk-vm debug_x64 corelib_2/map_keys2_test': 'RuntimeError/Pass',
          'dartk-vm debug_x64 corelib_2/package_resource_test':
              'Pass/CompileTimeError',
        },
      });

  bot.close();
}

testSingleResults(
    Map<int, Map<String, String>> expected, List<BuildResult> results) {
  Expect.equals(expected.length, results.length);
  int i = 0;
  expected.forEach((int buildNumber, Map<String, String> failures) {
    BuildResult result = results[i++];
    Expect.equals(failures.length, result.errors.length);
    failures.forEach((String testName, String resultText) {
      List<String> nameParts = split(testName, [' ', ' ']);
      TestConfiguration id =
          new TestConfiguration(nameParts[0], nameParts[1], nameParts[2]);
      List<String> resultParts = split(resultText, ['/']);
      TestFailure failure = result.errors.singleWhere((t) => t.id == id);
      Expect.equals(failure.expected, resultParts[0]);
      Expect.equals(failure.actual, resultParts[1]);
    });
  });
}

Future runSingleTest(Bot bot, String testUri, int runCount,
    Map<int, Map<String, String>> expectedResult) async {
  print('Testing single compare-failures: $testUri runCount=$runCount');
  Map<BuildUri, List<BuildResult>> buildResults =
      await loadBuildResults(bot, [testUri], runCount: runCount);
  print('- checking results for ${buildResults.keys}');
  if (LOG) {
    printBuildResultsSummary(buildResults, [testUri]);
  }
  Expect.equals(1, buildResults.length);
  testSingleResults(expectedResult, buildResults.values.first);
}
