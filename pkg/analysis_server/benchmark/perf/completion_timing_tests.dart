// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library server.performance.analysis.timing;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../test/utils.dart';
import 'performance_tests.dart';

/**
 * Pass in the directory of the source to be analyzed as option `--source`,
 * specify a priority file with `--priority` and an offset for completions
 * with a `--offset`.
 */
main(List<String> arguments) {
  initializeTestEnvironment();
  ArgParser parser = _createArgParser();
  var args = parser.parse(arguments);
  if (args[SOURCE_OPTION] == null) {
    print('path to source directory must be specified');
    exit(1);
  }
  source = args[SOURCE_OPTION];
  priorityFile = args[PRIORITY_FILE_OPTION];
  offset = args[COMPLETION_OFFSET];

  unittestConfiguration.timeout = new Duration(minutes: 20);

  defineReflectiveTests(CompletionTimingTest);
}

const PRIORITY_FILE_OPTION = 'priority';
const SOURCE_OPTION = 'source';
const COMPLETION_OFFSET = 'offset';

String priorityFile;
String source;
int offset;

ArgParser _createArgParser() => new ArgParser()
  ..addOption(SOURCE_OPTION, help: 'full path to source directory for analysis')
  ..addOption(PRIORITY_FILE_OPTION, help: 'full path to a priority file')
  ..addOption(COMPLETION_OFFSET, help: 'offset in file for code completions');

@reflectiveTest
class CompletionTimingTest extends AbstractAnalysisServerPerformanceTest {
  List<Duration> timings = <Duration>[];

  @override
  Future setUp() => super.setUp().then((_) {
        sourceDirectory = new Directory(source);
        subscribeToStatusNotifications();
      });

  Future test_timing() {
//    debugStdio();

    expect(priorityFile, isNotNull,
        reason: 'A priority file must be specified for completion testing.');
    expect(offset, isNotNull,
        reason: 'An offset must be specified for completion testing.');

    stopwatch.start();

    onCompletionResults.listen((_) {
      timings.add(new Duration(milliseconds: stopwatch.elapsed.inMilliseconds));
    });

    setAnalysisRoot();
    sendAnalysisSetPriorityFiles([priorityFile]);
    sendCompletionGetSuggestions(priorityFile, offset);

    return analysisFinished.then((_) {
      print('analysis completed in ${stopwatch.elapsed}');
      timings.forEach((timing) => print('notification at : ${timings}'));
      stopwatch.reset();
    });
  }
}
