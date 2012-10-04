#!/usr/bin/env dart
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ager): Get rid of this version of test.dart when we don't have
// to worry about the special runtime checkout anymore.
// This file is identical to test.dart with test suites in the
// directories samples, client, compiler, and utils removed.

#library("test");

#import("dart:io");
#import("testing/dart/test_runner.dart");
#import("testing/dart/test_options.dart");
#import("testing/dart/test_suite.dart");
#import("testing/dart/http_server.dart");

#import("../tests/co19/test_config.dart");
#import("../runtime/tests/vm/test_config.dart");

/**
 * The directories that contain test suites which follow the conventions
 * required by [StandardTestSuite]'s forDirectory constructor.
 * New test suites should follow this convention because it makes it much
 * simpler to add them to test.dart.  Existing test suites should be
 * moved to here, if possible.
*/
final TEST_SUITE_DIRECTORIES = [
  new Path('runtime/tests/vm'),
  new Path('tests/corelib'),
  new Path('tests/isolate'),
  new Path('tests/language'),
  new Path('tests/lib'),
  new Path('tests/standalone'),
  new Path('tests/utils'),
];

main() {
  var startTime = new Date.now();
  var optionsParser = new TestOptionsParser();
  List<Map> configurations = optionsParser.parse(new Options().arguments);
  if (configurations == null) return;

  // Extract global options from first configuration.
  var firstConf = configurations[0];
  Map<String, RegExp> selectors = firstConf['selectors'];
  var maxProcesses = firstConf['tasks'];
  var progressIndicator = firstConf['progress'];
  var verbose = firstConf['verbose'];
  var printTiming = firstConf['time'];
  var listTests = firstConf['list'];

  // Print the configurations being run by this execution of
  // test.dart. However, don't do it if the silent progress indicator
  // is used. This is only needed because of the junit tests.
  if (progressIndicator != 'silent') {
    List output_words = configurations.length > 1 ?
        ['Test configurations:'] : ['Test configuration:'];
    for (Map conf in configurations) {
      List settings =
          ['compiler', 'runtime', 'mode', 'arch'].map((name) => conf[name]);
      if (conf['checked']) settings.add('checked');
      output_words.add(Strings.join(settings, '_'));
    }
    print(Strings.join(output_words, ' '));
  }

  var configurationIterator = configurations.iterator();
  void enqueueConfiguration(ProcessQueue queue) {
    if (!configurationIterator.hasNext()) return;

    var conf = configurationIterator.next();
    if (selectors.containsKey('co19')) {
      queue.addTestSuite(new Co19TestSuite(conf));
    }
    if (conf['runtime'] == 'vm' && selectors.containsKey('vm')) {
      // vm tests contain both cc tests (added here) and dart tests (added in
      // [TEST_SUITE_DIRECTORIES]).
      queue.addTestSuite(new VMTestSuite(conf));
    }

    for (final testSuiteDir in TEST_SUITE_DIRECTORIES) {
      final name = testSuiteDir.filename;
      if (selectors.containsKey(name)) {
        queue.addTestSuite(
            new StandardTestSuite.forDirectory(conf, testSuiteDir));
      }
    }
  }

  // Start global http server that serves the entire dart repo.
  // The http server is available on localhost:9876 for any
  // test that needs to load resources from the repo over http.
  startHttpServer('127.0.0.1', 9876);

  // Start process queue.
  new ProcessQueue(
      maxProcesses,
      progressIndicator,
      startTime,
      printTiming,
      enqueueConfiguration,
      () => terminateHttpServer(),
      verbose,
      listTests);
}
