// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Compares the test log of a build step with previous builds.
///
/// Use this to detect flakiness of failures, especially timeouts.

import 'dart:async';

import 'package:gardening/src/bot.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/buildbot_data.dart';
import 'package:gardening/src/util.dart';

Future mainInternal(Bot bot, List<String> args, {int runCount: 10}) async {
  printBuildResultsSummary(
      await loadBuildResults(bot, args, runCount: runCount), args);
}

/// Loads [BuildResult]s for the [runCount] last builds for the build(s) in
/// [args]. [args] can be a list of [BuildGroup] names or a list of log uris.
Future<Map<BuildUri, List<BuildResult>>> loadBuildResults(
    Bot bot, List<String> args,
    {int runCount: 10}) async {
  List<BuildUri> buildUriList = <BuildUri>[];
  for (BuildGroup buildGroup in buildGroups) {
    if (args.contains(buildGroup.groupName)) {
      buildUriList.addAll(buildGroup.createUris(bot.mostRecentBuildNumber));
    }
  }
  if (buildUriList.isEmpty) {
    for (String url in args) {
      buildUriList.add(new BuildUri.fromUrl(url));
    }
  }
  Map<BuildUri, List<BuildResult>> pastResultsMap =
      <BuildUri, List<BuildResult>>{};
  List<BuildResult> buildResults = await bot.readResults(buildUriList);
  for (int index = 0; index < buildUriList.length; index++) {
    BuildUri buildUri = buildUriList[index];
    BuildResult buildResult = buildResults[index];
    List<BuildResult> results =
        await readPastResults(bot, buildUri, buildResult, runCount);
    pastResultsMap[buildUri] = results;
  }
  return pastResultsMap;
}

/// Prints summaries for the [buildResults].
void printBuildResultsSummary(
    Map<BuildUri, List<BuildResult>> buildResults, List<String> args) {
  List<Summary> emptySummaries = <Summary>[];
  List<Summary> nonEmptySummaries = <Summary>[];
  buildResults.forEach((BuildUri buildUri, List<BuildResult> results) {
    Summary summary = new Summary(buildUri, results);
    if (summary.isEmpty) {
      emptySummaries.add(summary);
    } else {
      nonEmptySummaries.add(summary);
    }
  });
  StringBuffer sb = new StringBuffer();
  if (nonEmptySummaries.isEmpty) {
    if (emptySummaries.isNotEmpty) {
      if (LOG || emptySummaries.length < 3) {
        if (emptySummaries.length == 1) {
          sb.writeln('No errors found for build bot:');
          sb.write(emptySummaries.single.name);
        } else {
          sb.writeln('No errors found for any of these build bots:');
          for (Summary summary in emptySummaries) {
            sb.writeln('${summary.name}');
          }
        }
      } else {
        sb.write('No errors found for any of the '
            '${emptySummaries.length} bots.');
      }
    } else {
      sb.write('No build bot results found for args: ${args}');
    }
  } else {
    for (Summary summary in nonEmptySummaries) {
      summary.printOn(sb);
    }
    if (emptySummaries.isNotEmpty) {
      if (LOG || emptySummaries.length < 3) {
        sb.writeln('No errors found for the remaining build bots:');
        for (Summary summary in emptySummaries) {
          sb.writeln('${summary.name}');
        }
      } else {
        sb.write(
            'No errors found for the ${emptySummaries.length} remaining bots.');
      }
    }
  }
  print(sb);
}

/// Creates a [BuildResult] for [buildUri] and, if it contains failures, the
/// [BuildResult]s for the previous [runCount] builds.
Future<List<BuildResult>> readPastResults(
    Bot bot, BuildUri buildUri, BuildResult summary, int runCount) async {
  List<BuildResult> summaries = <BuildResult>[];
  if (summary == null) {
    print('No result found for $buildUri');
    return summaries;
  }
  summaries.add(summary);
  if (summary.hasFailures) {
    summaries.addAll(await bot.readHistoricResults(summary.buildUri.prev(),
        previousCount: runCount - 1));
  }
  return summaries;
}

class Summary {
  final BuildUri buildUri;
  final List<BuildResult> results;
  final Set<TestConfiguration> timeoutIds = new Set<TestConfiguration>();
  final Set<TestConfiguration> errorIds = new Set<TestConfiguration>();

  Summary(this.buildUri, this.results) {
    for (BuildResult result in results) {
      timeoutIds
          .addAll(result.timeouts.map((TestFailure failure) => failure.id));
      errorIds.addAll(result.errors.map((TestFailure failure) => failure.id));
    }
  }

  bool get isEmpty => timeoutIds.isEmpty && errorIds.isEmpty;

  /// Generate a summary of the timeouts and other failures in [results].
  void printOn(StringBuffer sb) {
    if (timeoutIds.isNotEmpty) {
      Map<TestConfiguration, Map<int, Map<String, Timing>>> map =
          <TestConfiguration, Map<int, Map<String, Timing>>>{};
      Set<String> stepNames = new Set<String>();
      for (BuildResult result in results) {
        for (Timing timing in result.timings) {
          Map<int, Map<String, Timing>> builds = map.putIfAbsent(
              timing.step.id, () => <int, Map<String, Timing>>{});
          stepNames.add(timing.step.stepName);
          builds.putIfAbsent(timing.uri.buildNumber, () => <String, Timing>{})[
              timing.step.stepName] = timing;
        }
      }
      sb.write('Timeouts for ${name} :\n');
      map.forEach(
          (TestConfiguration id, Map<int, Map<String, Timing>> timings) {
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
    if (errorIds.isNotEmpty) {
      Map<TestConfiguration, Map<int, TestFailure>> map =
          <TestConfiguration, Map<int, TestFailure>>{};
      for (BuildResult result in results) {
        for (TestFailure failure in result.errors) {
          map.putIfAbsent(failure.id, () => <int, TestFailure>{})[
              failure.uri.buildNumber] = failure;
        }
      }
      sb.write('Errors for ${name} :\n');
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
      sb.write('No errors found for ${name}');
    }
  }

  String get name => results.isNotEmpty
      // Use the first result as name since it most likely has an absolute build
      // number.
      ? results.first.buildUri.toString()
      : buildUri.toString();
}
