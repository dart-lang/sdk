// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'command.dart';
import 'fuchsia.dart';

// Runs tests on a fuchsia emulator with chromium maintained test-scripts and
// CFv2 targets.
// TODO(#38752): Need implementation.
class FuchsiaEmulatorCFv2 extends FuchsiaEmulator {
  @override
  Future<void> publishPackage(
      String buildDir, String mode, String arch) async {}

  @override
  void stop() {}

  @override
  VMCommand getTestCommand(String mode, String arch, List<String> arguments) {
    return VMCommand("dummy", arguments, <String, String>{});
  }
}
