// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file is the entrypoint of the Dart repository's custom test system.
/// It is used to test:
///
///     1. The Dart VM
///     2. The dart2js compiler
///     3. The static analyzer
///     4. The Dart core library
///     5. Other standard dart libraries (DOM bindings, UI libraries,
///        IO libraries etc.)
///     6. The Dart specification parser.
///
/// This script is normally invoked by test.py. (test.py finds the Dart VM and
/// passes along all command line arguments to this script.)
///
/// The command line args of this script are documented in "test_options.dart".
/// They are printed when this script is run with "--help".
///
/// The default test directory layout is documented in "test_suite.dart", above
/// `factory StandardTestSuite.forDirectory`.
import "dart:io";

import "options.dart";
import "test_configurations.dart";
import 'utils.dart';

/// Runs all of the tests specified by the given command line [arguments].
void main(List<String> arguments) {
  // This script is in "<repo>/tools/testing/dart".
  TestUtils.setDartDirUri(Platform.script.resolve('../../..'));

  // Parse the command line arguments to a configuration.
  var parser = new OptionsParser();
  var configurations = parser.parse(arguments);
  if (configurations.isEmpty) return;

  // Run all of the configured tests.
  // TODO(26372): Ensure that all tasks complete and return a future from this
  // function.
  testConfigurations(configurations);
}
