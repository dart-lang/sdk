// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io' show exitCode;

import "package:testing/src/run_tests.dart" as testing show main;

main() async {
  // This method is async, but keeps a port open to prevent the VM from exiting
  // prematurely.
  await testing.main(
      <String>["--config=pkg/compiler/testing.json", "--verbose", "analyze"]);
  if (exitCode != 0) {
    throw "Exit-code was $exitCode!";
  }
}
