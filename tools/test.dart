#!/usr/bin/env dart_bin
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test");

#import("testing/dart/test_runner.dart");
#import("../tests/standalone/test_config.dart");
#import("../tests/corelib/test_config.dart");

main() {
  int numProcessors = new Platform().numberOfProcessors();
  var queue = new ProcessQueue(numProcessors);
  new StandaloneTestSuite().forEachTest(queue.runTest);
  new CorelibTestSuite().forEachTest(queue.runTest);
}
