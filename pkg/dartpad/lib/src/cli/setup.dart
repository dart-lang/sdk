// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';

import '../setup/dart.dart';
import '../setup/flutter.dart';

/// Command to download or build DartPad SDK assets for Dart and Flutter.
final class SetupCommand extends Command<void> {
  @override
  final String name = 'setup';

  @override
  final String description =
      'Download or build DartPad SDK assets for Dart and Flutter.';

  SetupCommand() {
    addSubcommand(SetupDartCommand());
    addSubcommand(SetupFlutterCommand());
  }
}
