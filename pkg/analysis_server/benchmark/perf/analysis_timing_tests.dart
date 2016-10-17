// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library server.performance.analysis.timing;

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:args/args.dart';
import 'package:test/test.dart';

import 'performance_tests.dart';

/**
 * Pass in the directory of the source to be analyzed as option `--source`,
 * optionally specify a priority file with `--priority` and the specific
 * test to run with `--metric`.  If no test is specified, the default is
 * `analysis`.
 */
main(List<String> arguments) {
  ArgParser parser = _createArgParser();
  var args = parser.parse(arguments);
  if (args[SOURCE_OPTION] == null) {
    print('path to source directory must be specified');
    exit(1);
  }
  source = args[SOURCE_OPTION];
  priorityFile = args[PRIORITY_FILE_OPTION];
  List names = args[METRIC_NAME_OPTION] as List;
  for (var name in names) {
    metricNames.add(name as String);
  }

  var test;

  if (metricNames.isEmpty) {
    test = new AnalysisTimingTest();
  } else {
    test = new SubscriptionTimingTest();
  }

  Future.wait(<Future>[test.test_timing()]);
}

const DEFAULT_METRIC = 'analysis';
const METRIC_NAME_OPTION = 'metric';
const PRIORITY_FILE_OPTION = 'priority';
const SOURCE_OPTION = 'source';

final metricNames = <String>[];
String priorityFile;
String source;

ArgParser _createArgParser() => new ArgParser()
  ..addOption(METRIC_NAME_OPTION,
      help: 'metric name (defaults to `analysis`)', allowMultiple: true)
  ..addOption(SOURCE_OPTION, help: 'full path to source directory for analysis')
  ..addOption(PRIORITY_FILE_OPTION,
      help: '(optional) full path to a priority file');

/**
 * AnalysisTimingTest measures the time taken by the analsyis server to fully analyze
 * the given directory. Measurement is started after setting the analysis root, and
 * analysis is considered complete on receiving the `"isAnalyzing": false` message
 * from the analysis server.
 */
class AnalysisTimingTest extends AbstractTimingTest {
  Future test_timing() async {
    // Set root after subscribing to avoid empty notifications.
    await init(source);

    setAnalysisRoot();
    stopwatch.start();
    await analysisFinished;
    print('analysis completed in ${stopwatch.elapsed}');

    await shutdown();
  }
}

class Metric {
  List<Duration> timings = <Duration>[];
  Stream eventStream;
  AnalysisService service;
  String name;
  Metric(this.name, this.service, this.eventStream);
  String toString() => '$name: $service, ${eventStream.runtimeType}, $timings';
}

/**
 * SubscriptionTimingTest measures the time taken by the analysis server to return
 * information for navigation, semantic highlighting, outline, get occurrences,
 * overrides, folding and implemented. These timings are wrt to the specified priority file
 * - the file that is currently opened and has focus in the editor. Measure the time from
 * when the client subscribes for the notifications till there is a response from the server.
 * Does not wait for analysis to be complete before subscribing for notifications.
 */
class SubscriptionTimingTest extends AbstractTimingTest {
  List<Metric> _metrics;

  List<Metric> get metrics => _metrics ??= metricNames.map(getMetric).toList();

  Metric getMetric(String name) {
    switch (name) {
      case 'folding':
        return new Metric(name, AnalysisService.FOLDING, onAnalysisFolding);
      case 'highlighting':
        return new Metric(
            name, AnalysisService.HIGHLIGHTS, onAnalysisHighlights);
      case 'implemented':
        return new Metric(
            name, AnalysisService.IMPLEMENTED, onAnalysisImplemented);
      case 'navigation':
        return new Metric(
            name, AnalysisService.NAVIGATION, onAnalysisNavigation);
      case 'outline':
        return new Metric(name, AnalysisService.OUTLINE, onAnalysisOutline);
      case 'occurences':
        return new Metric(
            name, AnalysisService.OCCURRENCES, onAnalysisOccurrences);
      case 'overrides':
        return new Metric(name, AnalysisService.OVERRIDES, onAnalysisOverrides);
    }
    print('no metric found for $name');
    exit(1);
    return null; // Won't get here.
  }

  Future test_timing() async {
//   debugStdio();

    expect(metrics, isNotEmpty);
    expect(priorityFile, isNotNull,
        reason: 'A priority file must be specified for '
            '${metrics.first.name} testing.');

    await init(source);
    stopwatch.start();

    metrics.forEach((Metric m) => m.eventStream.listen((_) {
          m.timings.add(
              new Duration(milliseconds: stopwatch.elapsed.inMilliseconds));
        }));

    var subscriptions = <AnalysisService, List<String>>{};
    metrics.forEach((Metric m) => subscriptions[m.service] = [priorityFile]);

    sendAnalysisSetSubscriptions(subscriptions);

    // Set root after subscribing to avoid empty notifications.
    setAnalysisRoot();

    sendAnalysisSetPriorityFiles([priorityFile]);

    await analysisFinished;
    print('analysis completed in ${stopwatch.elapsed}');
    metrics.forEach((Metric m) => print('${m.name} timings: ${m.timings}'));

    await shutdown();
  }
}
