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
  // Color constants used for generating messages.
  final String GREEN_COLOR = '\u001b[32m';
  final String RED_COLOR = '\u001b[31m';
  final String MAGENTA_COLOR = '\u001b[35m';
  final String NO_COLOR = '\u001b[0m';

  // We make this public so the user can turn it off if they want.
  bool useColor;

  VMConfiguration() :
    super(), useColor = stdioType(stdout) == StdioType.TERMINAL;

  String formatResult(TestCase testCase) {
    String result = super.formatResult(testCase);
    if (useColor) {
      if (testCase.result == PASS) {
        return "${GREEN_COLOR}${result}${NO_COLOR}";
      } else if (testCase.result == FAIL) {
        return "${RED_COLOR}${result}${NO_COLOR}";
      } else if (testCase.result == ERROR) {
        return "${MAGENTA_COLOR}${result}${NO_COLOR}";
      }
    }
    return result;
  }

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
