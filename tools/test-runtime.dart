#!/usr/bin/env dart
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ager): Get rid of this version of test.dart when we don't have
// to worry about the special runtime checkout anymore.
// This file is identical to test.dart with test suites in the
// directories samples, client, compiler, frog, and utils removed.

#library("test");

#import("testing/dart/test_runner.dart");
#import("testing/dart/test_options.dart");
#import("testing/dart/test_suite.dart");

#import("../tests/co19/test_config.dart");
#import("../tests/lib/test_config.dart");
#import("../tests/standalone/test_config.dart");
#import("../tests/utils/test_config.dart");
#import("../runtime/tests/vm/test_config.dart");

/**
 * The directories that contain test suites which follow the conventions
 * required by [StandardTestSuite]'s forDirectory constructor.
 * New test suites should follow this convention because it makes it much
 * simpler to add them to test.dart.  Existing test suites should be
 * moved to here, if possible.
*/
final TEST_SUITE_DIRECTORIES = const [
  'tests/corelib',
  'tests/isolate',
  'tests/language',
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
  var keepGeneratedTests = firstConf['keep-generated-tests'];

  // Print the configurations being run by this execution of
  // test.dart. However, don't do it if the silent progress indicator
  // is used. This is only needed because of the junit tests.
  if (progressIndicator != 'silent') {
    StringBuffer sb = new StringBuffer('Test configuration');
    sb.add(configurations.length > 1 ? 's:' : ':');
    for (Map conf in configurations) {
      sb.add(' ${conf["compiler"]}_${conf["runtime"]}_${conf["mode"]}_' +
          '${conf["arch"]}');
      if (conf['checked']) sb.add('_checked');
    }
    print(sb);
  }

  var configurationIterator = configurations.iterator();
  bool enqueueConfiguration(ProcessQueue queue) {
    if (!configurationIterator.hasNext()) {
      return false;
    }

    var conf = configurationIterator.next();
    if (selectors.containsKey('standalone')) {
      queue.addTestSuite(new StandaloneTestSuite(conf));
    }
    if (selectors.containsKey('co19')) {
      queue.addTestSuite(new Co19TestSuite(conf));
    }
    if (selectors.containsKey('lib')) {
      queue.addTestSuite(new LibTestSuite(conf));
    }
    if (selectors.containsKey('utils')) {
      queue.addTestSuite(new UtilsTestSuite(conf));
    }
    if (conf['runtime'] == 'vm' && selectors.containsKey('vm')) {
      queue.addTestSuite(new VMTestSuite(conf));
      queue.addTestSuite(new VMDartTestSuite(conf));
    }

    for (final testSuiteDir in TEST_SUITE_DIRECTORIES) {
      final name = testSuiteDir.substring(testSuiteDir.lastIndexOf('/') + 1);
      if (selectors.containsKey(name)) {
        queue.addTestSuite(
            new StandardTestSuite.forDirectory(conf, testSuiteDir));
      }
    }

    return true;
  }

  // Start process queue.
  var queue = new ProcessQueue(maxProcesses,
                               progressIndicator,
                               startTime,
                               printTiming,
                               enqueueConfiguration,
                               verbose,
                               listTests,
                               keepGeneratedTests);
}
