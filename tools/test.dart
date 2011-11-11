#!/usr/bin/env dart_bin
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test");

#import("testing/dart/test_runner.dart");
#import("testing/dart/test_options.dart");
#import("testing/dart/test_progress.dart");

#import("../tests/standalone/test_config.dart");
#import("../tests/corelib/test_config.dart");

main() {
  var optionsParser = new TestOptionsParser();
  var configurations = optionsParser.parse(new Options().arguments);
  if (configurations == null) return;
  print(configurations.length);
  var queue = new ProcessQueue(configurations[0]['tasks'],
                               new CompactProgressIndicator());
  for (var conf in configurations) {
    new StandaloneTestSuite(conf).forEachTest(queue.runTest);
    new CorelibTestSuite(conf).forEachTest(queue.runTest);
  }
}
