#!/usr/bin/env dart
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test");

#import("testing/dart/test_runner.dart");
#import("testing/dart/test_options.dart");

#import("../tests/co19/test_config.dart");
#import("../tests/corelib/test_config.dart");
#import("../tests/isolate/test_config.dart");
#import("../tests/language/test_config.dart");
#import("../tests/standalone/test_config.dart");
#import("../tests/stub-generator/test_config.dart");
#import("../runtime/tests/vm/test_config.dart");
#import("../samples/tests/samples/test_config.dart");
#import("../frog/tests/frog/test_config.dart");
#import("../frog/tests/leg/test_config.dart");
#import("../frog/tests/leg_only/test_config.dart");

main() {
  var startTime = new Date.now();
  var optionsParser = new TestOptionsParser();
  var configurations = optionsParser.parse(new Options().arguments);
  if (configurations == null) return;
  // Extract global options from first configuration.
  var firstConf = configurations[0];
  var queue = new ProcessQueue(firstConf['tasks'],
                               firstConf['progress'],
                               startTime);
  for (var conf in configurations) {
    queue.addTestSuite(new SamplesTestSuite(conf));
    queue.addTestSuite(new StandaloneTestSuite(conf));
    queue.addTestSuite(new CorelibTestSuite(conf));
    queue.addTestSuite(new Co19TestSuite(conf));
    queue.addTestSuite(new LanguageTestSuite(conf));
    queue.addTestSuite(new IsolateTestSuite(conf));
    queue.addTestSuite(new StubGeneratorTestSuite(conf));
    if (conf["component"] == "vm") {
      queue.addTestSuite(new VMTestSuite(conf));
    }
    if (conf["patterns"].some((regexp) => regexp.pattern == 'frog')) {
      queue.addTestSuite(new FrogTestSuite(conf));
    }
    if (conf["patterns"].some((regexp) => regexp.pattern == 'leg')) {
      queue.addTestSuite(new LegTestSuite(conf));
    }
    if (conf["patterns"].some((regexp) => regexp.pattern == 'leg_only')) {
      queue.addTestSuite(new LegOnlyTestSuite(conf));
    }
  }
}
