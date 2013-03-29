// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple unit test library for running tests on the VM.
 */
library unittest_vm_config;

import 'dart:io';
import 'unittest.dart';

class VMConfiguration extends Configuration {
  void onDone(bool success) {
    try {
      super.onDone(success);
      exit(0);
    } catch (ex) {
      // A non-zero exit code is used by the test infrastructure to detect
      // failure.
      exit(1);
    }
  }
}

void useVMConfiguration() {
  unittestConfiguration = _singleton;
}

final _singleton = new VMConfiguration();
