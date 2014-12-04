#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file is the entrypoint of the dart test suite.  This suite is used
 * to test:
 *
 *     1. the dart vm
 *     2. the dart2js compiler
 *     3. the static analyzer
 *     4. the dart core library
 *     5. other standard dart libraries (DOM bindings, ui libraries,
 *            io libraries etc.)
 *
 * This script is normally invoked by test.py.  (test.py finds the dart vm
 * and passses along all command line arguments to this script.)
 *
 * The command line args of this script are documented in
 * "tools/testing/dart/test_options.dart"; they are printed
 * when this script is run with "--help".
 *
 * The default test directory layout is documented in
 * "tools/testing/dart/test_suite.dart", above
 * "factory StandardTestSuite.forDirectory".
 */

library test;

import "dart:async";
import "dart:io";
import "testing/dart/test_configurations.dart";
import "testing/dart/test_options.dart";
import "testing/dart/test_progress.dart";
import "testing/dart/test_suite.dart";
import "testing/dart/utils.dart";

Future _deleteTemporaryDartDirectories() {
  var completer = new Completer();
  var environment = Platform.environment;
  if (environment['DART_TESTING_DELETE_TEMPORARY_DIRECTORIES'] == '1') {
    LeftOverTempDirPrinter.getLeftOverTemporaryDirectories().listen(
        (Directory tempDirectory) {
          try {
            tempDirectory.deleteSync(recursive: true);
          } catch (error) {
            DebugLogger.error(error);
          }
        }, onDone: completer.complete);
  } else {
    completer.complete();
  }
  return completer.future;
}

void main(List<String> arguments) {
  // This script is in [dart]/tools.
  TestUtils.setDartDirUri(Platform.script.resolve('..'));
  _deleteTemporaryDartDirectories().then((_) {
    var optionsParser = new TestOptionsParser();
    var configurations = optionsParser.parse(arguments);
    if (configurations != null && configurations.length > 0) {
      testConfigurations(configurations);
    }
  });
}
