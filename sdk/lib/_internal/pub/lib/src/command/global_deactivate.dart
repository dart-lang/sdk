// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.global_deactivate;

import 'dart:async';

import '../command.dart';
import '../utils.dart';

/// Handles the `global deactivate` pub command.
class GlobalDeactivateCommand extends PubCommand {
  String get description => "Remove a previously activated package.";
  String get usage => "pub global deactivate <package>";
  bool get requiresEntrypoint => false;
  bool get takesArguments => true;

  Future onRun() {
    // Make sure there is a package.
    if (commandOptions.rest.isEmpty) {
      usageError("No package to deactivate given.");
    }

    // Don't allow extra arguments.
    if (commandOptions.rest.length > 1) {
      var unexpected = commandOptions.rest.skip(1).map((arg) => '"$arg"');
      var arguments = pluralize("argument", unexpected.length);
      usageError("Unexpected $arguments ${toSentence(unexpected)}.");
    }

    globals.deactivate(commandOptions.rest.first);
    return null;
  }
}
