// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Compares the test log of a build step with previous builds.
///
/// Use this to detect flakiness of failures, especially timeouts.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/client.dart';
import 'package:gardening/src/util.dart';

void help(ArgParser argParser) {
  print('Given a <log-uri> finds all failing tests in that stdout. Then ');
  print('fetches earlier runs of the same bot and compares the results.');
  print('This tool is particularly useful to detect flakes and their ');
  print('frequency.');
  print('Usage: compare_failures [options] <log-uri>');
  print('where <log-uri> is the uri the stdio output of a failing test step');
  print('and options are:');
  print(argParser.usage);
}

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  argParser.addOption("run-count",
      defaultsTo: "10", help: "How many previous runs should be fetched");
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);

  BuildbotClient client = argResults['logdog']
      ? new LogdogBuildbotClient()
      : new HttpBuildbotClient();

  var runCount = int.parse(argResults['run-count'], onError: (_) => null);

  if (argResults.rest.length != 1 || argResults['help'] || runCount == null) {
    help(argParser);
    if (argResults['help']) return;
    exit(1);
  }
  String url = argResults.rest.first;
  if (!url.endsWith('/text')) {
    // Use the text version of the stdio log.
    url += '/text';
  }
  Uri uri = Uri.parse(url);
  BuildUri buildUri = new BuildUri(uri);
  List<BuildResult> results =
      await readBuildResults(client, buildUri, runCount);
  print(generateBuildResultsSummary(buildUri, results));
  client.close();
}

/// Creates a [BuildResult] for [buildUri] and, if it contains failures, the
/// [BuildResult]s for the previous [runCount] builds.
Future<List<BuildResult>> readBuildResults(
    BuildbotClient client, BuildUri buildUri, int runCount) async {
  List<BuildResult> summaries = <BuildResult>[];
  BuildResult summary = await client.readResult(buildUri);
  summaries.add(summary);
  if (summary.hasFailures) {
    for (int i = 0; i < runCount; i++) {
      buildUri = summary.buildUri.prev();
      summary = await client.readResult(buildUri);
      summaries.add(summary);
    }
  }
  return summaries;
}

/// Generate a summary of the timeouts and other failures in [results].
String generateBuildResultsSummary(
    BuildUri buildUri, List<BuildResult> results) {
  StringBuffer sb = new StringBuffer();
  sb.write('Results for $buildUri:\n');
  Set<TestConfiguration> timeoutIds = new Set<TestConfiguration>();
  for (BuildResult result in results) {
    timeoutIds.addAll(result.timeouts.map((TestFailure failure) => failure.id));
  }
  if (timeoutIds.isNotEmpty) {
    Map<TestConfiguration, Map<int, Map<String, Timing>>> map =
        <TestConfiguration, Map<int, Map<String, Timing>>>{};
    Set<String> stepNames = new Set<String>();
    for (BuildResult result in results) {
      for (Timing timing in result.timings) {
        Map<int, Map<String, Timing>> builds =
            map.putIfAbsent(timing.step.id, () => <int, Map<String, Timing>>{});
        stepNames.add(timing.step.stepName);
        builds.putIfAbsent(timing.uri.buildNumber, () => <String, Timing>{})[
            timing.step.stepName] = timing;
      }
    }
    sb.write('Timeouts for ${buildUri} :\n');
    map.forEach((TestConfiguration id, Map<int, Map<String, Timing>> timings) {
      if (!timeoutIds.contains(id)) return;
      sb.write('$id\n');
      sb.write(
          '${' ' * 8} ${stepNames.map((t) => padRight(t, 14)).join(' ')}\n');
      for (BuildResult result in results) {
        int buildNumber = result.buildUri.buildNumber;
        Map<String, Timing> steps = timings[buildNumber] ?? const {};
        sb.write(padRight(' ${buildNumber}: ', 8));
        for (String stepName in stepNames) {
          Timing timing = steps[stepName];
          if (timing != null) {
            sb.write(' ${timing.time}');
          } else {
            sb.write(' --------------');
          }
        }
        sb.write('\n');
      }
      sb.write('\n');
    });
  }
  Set<TestConfiguration> errorIds = new Set<TestConfiguration>();
  for (BuildResult result in results) {
    errorIds.addAll(result.errors.map((TestFailure failure) => failure.id));
  }
  if (errorIds.isNotEmpty) {
    Map<TestConfiguration, Map<int, TestFailure>> map =
        <TestConfiguration, Map<int, TestFailure>>{};
    for (BuildResult result in results) {
      for (TestFailure failure in result.errors) {
        map.putIfAbsent(failure.id, () => <int, TestFailure>{})[
            failure.uri.buildNumber] = failure;
      }
    }
    sb.write('Errors for ${buildUri} :\n');
    // TODO(johnniwinther): Improve comparison of non-timeouts.
    map.forEach((TestConfiguration id, Map<int, TestFailure> failures) {
      if (!errorIds.contains(id)) return;
      sb.write('$id\n');
      for (BuildResult result in results) {
        int buildNumber = result.buildUri.buildNumber;
        TestFailure failure = failures[buildNumber];
        sb.write(padRight(' ${buildNumber}: ', 8));
        if (failure != null) {
          sb.write(padRight(failure.expected, 10));
          sb.write(' / ');
          sb.write(padRight(failure.actual, 10));
        } else {
          sb.write(' ' * 10);
          sb.write(' / ');
          sb.write(padRight('-- OK --', 10));
        }
        sb.write('\n');
      }
      sb.write('\n');
    });
  }
  return sb.toString();
}
