#!/usr/bin/env dart_bin
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

// TODO(ager): This activity tracking is temporary until stdout is
// closed implicitly when nothing more can happen.
int pendingActivities = 0;

void activityStarted() {
  ++pendingActivities;
}

void activityCompleted() {
  --pendingActivities;
}

void exitIfLastActivity() {
  if (pendingActivities == 1) {
    stdout.write('\n'.charCodes());
    stdout.close();
  }
}

main() {
  var optionsParser = new TestOptionsParser();
  var configurations = optionsParser.parse(new Options().arguments);
  if (configurations == null) return;
  activityStarted();
  var queue = new ProcessQueue(configurations[0], exitIfLastActivity);
  for (var conf in configurations) {
    activityStarted();
    new StandaloneTestSuite(conf).forEachTest(queue.runTest, activityCompleted);
    activityStarted();
    new CorelibTestSuite(conf).forEachTest(queue.runTest, activityCompleted);
    activityStarted();
    new Co19TestSuite(conf).forEachTest(queue.runTest, activityCompleted);
    activityStarted();
    new LanguageTestSuite(conf).forEachTest(queue.runTest, activityCompleted);
    activityStarted();
    new IsolateTestSuite(conf).forEachTest(queue.runTest, activityCompleted);
    activityStarted();
    new StubGeneratorTestSuite(conf).forEachTest(queue.runTest, activityCompleted);
  }
}
