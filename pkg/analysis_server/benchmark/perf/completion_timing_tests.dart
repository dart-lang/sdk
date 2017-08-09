// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:test/test.dart';

import 'performance_tests.dart';

const COMPLETION_OFFSET = 'offset';
const PRIORITY_FILE_OPTION = 'priority';
const SOURCE_OPTION = 'source';

/**
 * Pass in the directory of the source to be analyzed as option `--source`,
 * specify a priority file with `--priority` and an offset for completions
 * with a `--offset`.
 */
main(List<String> arguments) async {
  ArgParser parser = _createArgParser();
  var args = parser.parse(arguments);
  if (args[SOURCE_OPTION] == null) {
    print('path to source directory must be specified');
    exit(1);
  }

  int offset = int.parse(args[COMPLETION_OFFSET]);
  String priorityFile = args[PRIORITY_FILE_OPTION];
  String source = args[SOURCE_OPTION];

  CompletionTimingTest test =
      new CompletionTimingTest(offset, priorityFile, source);
  await test.test_timing();
}

ArgParser _createArgParser() => new ArgParser()
  ..addOption(SOURCE_OPTION, help: 'full path to source directory for analysis')
  ..addOption(PRIORITY_FILE_OPTION, help: 'full path to a priority file')
  ..addOption(COMPLETION_OFFSET, help: 'offset in file for code completions');

/**
 * CompletionTimingTest measures the time taken for the analysis server to respond with
 * completion suggestions for a given file and offset. The time measured starts when
 * the analysis root is set and is done when the completion suggestions are received
 * from the server. The test does not wait for analysis to be complete before asking for
 * completions.
 */
class CompletionTimingTest extends AbstractTimingTest {
  final int offset;
  final String priorityFile;
  final String source;

  List<Duration> timings = <Duration>[];

  CompletionTimingTest(this.offset, this.priorityFile, this.source);

  Future test_timing() async {
//    debugStdio();

    expect(priorityFile, isNotNull,
        reason: 'A priority file must be specified for completion testing.');
    expect(offset, isNotNull,
        reason: 'An offset must be specified for completion testing.');

    await init(source);
    stopwatch.start();

    onCompletionResults.listen((_) {
      timings.add(new Duration(milliseconds: stopwatch.elapsed.inMilliseconds));
    });

    setAnalysisRoot();
    sendAnalysisSetPriorityFiles([priorityFile]);
    sendCompletionGetSuggestions(priorityFile, offset);

    await analysisFinished;

    print('analysis completed in ${stopwatch.elapsed}');
    print('completion received at : $timings');
    await shutdown();
  }
}
