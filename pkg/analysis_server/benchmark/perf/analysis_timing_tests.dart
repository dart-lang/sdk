// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library server.performance.analysis.timing;

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/protocol.dart';
import 'package:args/args.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../test/utils.dart';
import 'performance_tests.dart';

/**
 * Pass in the directory of the source to be analyzed as option `--source`,
 * optionally specify a priority file with `--priority` and the specific
 * test to run with `--test`.  If no test is specified, the default is
 * `analysis`.
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
  testName = args[TEST_NAME_OPTION] ?? DEFAULT_TEST;

  switch (testName) {
    case 'analysis':
      defineReflectiveTests(AnalysisTimingIntegrationTest);
      break;
    case 'navigation':
      defineReflectiveTests(NavigationTimingIntegrationTest);
      break;
    default:
      print('unrecognized test name $testName');
      exit(1);
  }
}

const DEFAULT_TEST = 'analysis';
const PRIORITY_FILE_OPTION = 'priority';
const SOURCE_OPTION = 'source';
const TEST_NAME_OPTION = 'test';

String priorityFile;
String source;
String testName;

ArgParser _createArgParser() => new ArgParser()
  ..addOption(TEST_NAME_OPTION, help: 'test name (defaults to `analysis`)')
  ..addOption(SOURCE_OPTION, help: 'full path to source directory for analysis')
  ..addOption(PRIORITY_FILE_OPTION,
      help: '(optional) full path to a priority file');

class AbstractTimingTest extends AbstractAnalysisServerPerformanceTest {
  @override
  Future setUp() => super.setUp().then((_) {
        sourceDirectory = new Directory(source);
        subscribeToStatusNotifications();
      });
}

@reflectiveTest
class AnalysisTimingIntegrationTest extends AbstractTimingTest {
  test_detect_analysis_done() {
    stopwatch.start();
    setAnalysisRoot();
    if (priorityFile != null) {
      sendAnalysisSetPriorityFiles([priorityFile]);
    }
    return analysisFinished.then((_) {
      print('analysis completed in ${stopwatch.elapsed}');
      stopwatch.reset();
    });
  }
}

@reflectiveTest
class NavigationTimingIntegrationTest extends AbstractTimingTest {
  Future test_detect_navigation_done() {
    expect(priorityFile, isNotNull);
    stopwatch.start();

    Duration elapsed;
    onAnalysisNavigation.listen((AnalysisNavigationParams params) {
      elapsed = stopwatch.elapsed;
    });

    setAnalysisRoot();
    sendAnalysisSetSubscriptions({
      AnalysisService.NAVIGATION: [priorityFile]
    });

    sendAnalysisSetPriorityFiles([priorityFile]);

    return analysisFinished.then((_) {
      print('navigation completed in ${elapsed}');
      stopwatch.reset();
    });
  }
}
