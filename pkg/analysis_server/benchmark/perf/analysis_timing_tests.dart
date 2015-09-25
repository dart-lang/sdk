// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library server.performance.analysis.timing;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../test/utils.dart';
import 'performance_tests.dart';

const String SOURCE_OPTION = 'source';

/**
 * Pass in the directory of the source to be analyzed as option --source
 */
main(List<String> arguements) {
  initializeTestEnvironment();
  ArgParser parser = _createArgParser();
  var args = parser.parse(arguements);
  if (args[SOURCE_OPTION] == null) {
    print('path to source directory must be specified');
    exit(1);
  }
  source = args[SOURCE_OPTION];
  defineReflectiveTests(AnalysisTimingIntegrationTest);
}

String source;

@reflectiveTest
class AnalysisTimingIntegrationTest
    extends AbstractAnalysisServerPerformanceTest {
  test_detect_analysis_done() {
    sourceDirectory = new Directory(source);
    subscribeToStatusNotifications();
    return _runAndTimeAnalysis();
  }

  Future _runAndTimeAnalysis() {
    stopwatch.start();
    setAnalysisRoot();
    return analysisFinished.then((_) {
      print('analysis completed in ${stopwatch.elapsed}');
      stopwatch.reset();
    });
  }
}

ArgParser _createArgParser() {
  ArgParser parser = new ArgParser();
  parser.addOption('source',
      help: 'full path to source directory for analysis');
  return parser;
}
