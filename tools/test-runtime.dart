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

#import("../tests/co19/test_config.dart");
#import("../tests/corelib/test_config.dart");
#import("../tests/isolate/test_config.dart");
#import("../tests/language/test_config.dart");
#import("../tests/standalone/test_config.dart");
#import("../tests/utils/test_config.dart");
#import("../runtime/tests/vm/test_config.dart");

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
    if (selectors.containsKey('corelib')) {
      queue.addTestSuite(new CorelibTestSuite(conf));
    }
    if (selectors.containsKey('co19')) {
      queue.addTestSuite(new Co19TestSuite(conf));
    }
    if (selectors.containsKey('language')) {
      queue.addTestSuite(new LanguageTestSuite(conf));
    }
    if (selectors.containsKey('isolate')) {
      queue.addTestSuite(new IsolateTestSuite(conf));
    }
    if (selectors.containsKey('utils')) {
      queue.addTestSuite(new UtilsTestSuite(conf));
    }
    if (conf['runtime'] == 'vm' && selectors.containsKey('vm')) {
      queue.addTestSuite(new VMTestSuite(conf));
      queue.addTestSuite(new VMDartTestSuite(conf));
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
