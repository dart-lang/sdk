// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.global;

import '../command.dart';
import 'global_activate.dart';
import 'global_deactivate.dart';
import 'global_run.dart';

/// Handles the `global` pub command.
class GlobalCommand extends PubCommand {
  String get description => "Work with global packages.";
  String get usage => "pub global <subcommand>";

  final subcommands = {
    "activate": new GlobalActivateCommand(),
    "deactivate": new GlobalDeactivateCommand(),
    "run": new GlobalRunCommand()
  };
}
