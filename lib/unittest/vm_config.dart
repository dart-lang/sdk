// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple unit test library for running tests on the VM.
 */
#library('unittest');

#import('dart:io');
#import('unittest.dart');

class VmConfiguration extends Configuration {
  void onDone(int passed, int failed, int errors, List<TestCase> results) {
    try {
      super.onDone(passed, failed, errors, results);
    } catch (Exception ex) {
      // A non-zero exit code is used by the test infrastructure to detect
      // failure.
      exit(1);
    }
  }
}

void useVmConfiguration() {
  configure(new VmConfiguration());
}
