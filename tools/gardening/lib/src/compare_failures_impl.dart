// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Compares the test log of a build step with previous builds.
///
/// Use this to detect flakiness of failures, especially timeouts.

import 'dart:async';

import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/buildbot_data.dart';
import 'package:gardening/src/client.dart';
import 'package:gardening/src/util.dart';

Future mainInternal(BuildbotClient client, List<String> args,
    {int runCount: 10}) async {
  printBuildResultsSummary(
      await loadBuildResults(client, args, runCount: runCount));
}

/// Loads [BuildResult]s for the [runCount] last builds for the build(s) in
/// [args]. [args] can be a list of [BuildGroup] names or a list of log uris.
Future<Map<BuildUri, List<BuildResult>>> loadBuildResults(
    BuildbotClient client, List<String> args,
    {int runCount: 10}) async {
  List<BuildUri> buildUriList = <BuildUri>[];
  for (BuildGroup buildGroup in buildGroups) {
    if (args.contains(buildGroup.groupName)) {
      buildUriList.addAll(buildGroup.createUris(client.mostRecentBuildNumber));
    }
  }
  if (buildUriList.isEmpty) {
    for (String url in args) {
      if (!url.endsWith('/text')) {
        // Use the text version of the stdio log.
        url += '/text';
      }
      Uri uri = Uri.parse(url);
      BuildUri buildUri = new BuildUri(uri);
      buildUriList.add(buildUri);
    }
  }
  Map<BuildUri, List<BuildResult>> buildResults =
      <BuildUri, List<BuildResult>>{};
  for (BuildUri buildUri in buildUriList) {
    List<BuildResult> results =
        await readBuildResults(client, buildUri, runCount);
    buildResults[buildUri] = results;
  }
  return buildResults;
}

/// Prints summaries for the [buildResults].
// TODO(johnniwinther): Improve printing of multiple [BuildUri] results.
void printBuildResultsSummary(Map<BuildUri, List<BuildResult>> buildResults) {
  buildResults.forEach((BuildUri buildUri, List<BuildResult> results) {
    print(generateBuildResultsSummary(buildUri, results));
  });
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
  if (timeoutIds.isEmpty && errorIds.isEmpty) {
    sb.write('No errors found.');
  }
  return sb.toString();
}
