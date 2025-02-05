// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show exitCode;

import "package:testing/src/run_tests.dart" as testing show main;

Future<void> main() async {
  // This method is async, but keeps a port open to prevent the VM from exiting
  // prematurely.
  // Note: if you change this file, also change
  // pkg/compiler/test/analyses/analyze_test.dart
  await testing.main(
      <String>["--config=pkg/front_end/testing.json", "--verbose", "analyze"]);
  if (exitCode != 0) {
    throw "Exit-code was $exitCode!";
  }
}
