#!/usr/bin/env dart
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file is the entrypoint of the dart test suite.  This suite is used
 * to test:
 *
 *     1. the dart vm
 *     2. the frog compiler (compiles dart to js)
 *     3. the leg compiler (also compiles dart to js)
 *     4. the dartc static analyzer
 *     5. the dart core library
 *     6. other standard dart libraries (DOM bindings, ui libraries,
 *            io libraries etc.)
 *
 * This script is normally invoked by test.py.  (test.py finds the dart vm
 * and passses along all command line arguments to this script.)
 *
 * The command line args of this script are documented in
 * "tools/testing/test_options.dart".
 *
 */

#library("test");

#import("testing/dart/test_runner.dart");
#import("testing/dart/test_options.dart");
#import("testing/dart/test_suite.dart");

#import("../client/tests/dartc/test_config.dart");
#import("../compiler/tests/dartc/test_config.dart");
#import("../frog/tests/await/test_config.dart");
#import("../frog/tests/frog/test_config.dart");
#import("../frog/tests/leg/test_config.dart");
#import("../frog/tests/leg_only/test_config.dart");
#import("../frog/tests/native/test_config.dart");
#import("../runtime/tests/vm/test_config.dart");
#import("../samples/tests/samples/test_config.dart");
#import("../tests/co19/test_config.dart");
#import("../tests/corelib/test_config.dart");
#import("../tests/isolate/test_config.dart");
#import("../tests/language/test_config.dart");
#import("../tests/lib/test_config.dart");
#import("../tests/standalone/test_config.dart");
#import("../tests/utils/test_config.dart");

/**
 * The directories that contain test suites which follow the conventions
 * required by [StandardTestSuite]'s forDirectory constructor.
 * New test suites should follow this convention because it makes it much
 * simpler to add them to test.dart.  Existing test suites should be
 * moved to here, if possible.
*/
final TEST_SUITE_DIRECTORIES = const [
  'tests/benchmark_smoke',
  'tests/dom',
  'tests/html',
  'tests/json',
  'utils/tests/css',
  'utils/tests/peg',
  'utils/tests/pub',
];

main() {
  var startTime = new Date.now();
  var optionsParser = new TestOptionsParser();
  List<Map> configurations = optionsParser.parse(new Options().arguments);
  if (configurations == null || configurations.length == 0) return;

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
    for (String key in selectors.getKeys()) {
      if (key == 'samples') {
        queue.addTestSuite(new SamplesTestSuite(conf));
      } else if (key == 'standalone') {
        queue.addTestSuite(new StandaloneTestSuite(conf));
      } else if (key == 'corelib') {
        queue.addTestSuite(new CorelibTestSuite(conf));
      } else if (key == 'co19') {
        queue.addTestSuite(new Co19TestSuite(conf));
      } else if (key == 'language') {
        queue.addTestSuite(new LanguageTestSuite(conf));
      } else if (key == 'lib') {
        queue.addTestSuite(new LibTestSuite(conf));
      } else if (key == 'isolate') {
        queue.addTestSuite(new IsolateTestSuite(conf));
      } else if (key == 'utils') {
        queue.addTestSuite(new UtilsTestSuite(conf));
      } else if (conf['runtime'] == 'vm' && key == 'vm') {
        queue.addTestSuite(new VMTestSuite(conf));
        queue.addTestSuite(new VMDartTestSuite(conf));
      } else if (key == 'frog') {
        queue.addTestSuite(new FrogTestSuite(conf));
      } else if (key == 'leg') {
        queue.addTestSuite(new LegTestSuite(conf));
      } else if (key == 'leg_only') {
        queue.addTestSuite(new LegOnlyTestSuite(conf));
      } else if (key == 'frog_native') {
        queue.addTestSuite(new FrogNativeTestSuite(conf));
      } else if (conf['compiler'] == 'dartc' && key == 'dartc') {
        queue.addTestSuite(new ClientDartcTestSuite(conf));
      } else if (conf['compiler'] == 'dartc' && key == 'dartc') {
        queue.addTestSuite(new JUnitDartcTestSuite(conf));
      } else if (key == 'await') {
        queue.addTestSuite(new AwaitTestSuite(conf));
      }
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
