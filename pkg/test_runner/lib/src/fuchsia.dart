// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'command.dart';
import 'fuchsia_cfv1.dart';
import 'fuchsia_cfv2.dart';

// Sets up and executes commands against a Fuchsia environment.
abstract class FuchsiaEmulator {
  // Publishes the packages to the Fuchsia environment.
  Future<void> publishPackage(String buildDir, String mode, String arch);
  // Tears down the Fuchsia environment.
  void stop();
  // Returns a command to execute a set of tests against the running Fuchsia
  // environment.
  VMCommand getTestCommand(
      String buildDir, String mode, String arch, List<String> arguments);

  static final FuchsiaEmulator _instance = _create();

  static FuchsiaEmulator _create() {
    if (Platform.environment.containsKey('FUCHSIA_CFV2')) {
      return FuchsiaEmulatorCFv2();
    }
    return FuchsiaEmulatorCFv1();
  }

  static FuchsiaEmulator instance() {
    return _instance;
  }
}
