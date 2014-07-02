// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.global_activate;

import 'dart:async';

import '../command.dart';
import '../utils.dart';
import '../version.dart';

/// Handles the `global activate` pub command.
class GlobalActivateCommand extends PubCommand {
  String get description => "Make a package's executables globally available.";
  String get usage => "pub global activate <package> [version]";
  bool get requiresEntrypoint => false;
  bool get takesArguments => true;

  Future onRun() {
    // Make sure there is a package.
    if (commandOptions.rest.isEmpty) {
      usageError("No package to activate given.");
    }

    // Don't allow extra arguments.
    if (commandOptions.rest.length > 2) {
      var unexpected = commandOptions.rest.skip(2).map((arg) => '"$arg"');
      var arguments = pluralize("argument", unexpected.length);
      usageError("Unexpected $arguments ${toSentence(unexpected)}.");
    }

    var package = commandOptions.rest.first;

    // Parse the version constraint, if there is one.
    var constraint = VersionConstraint.any;
    if (commandOptions.rest.length == 2) {
      try {
        constraint = new VersionConstraint.parse(commandOptions.rest[1]);
      } on FormatException catch (error) {
        usageError(error.message);
      }
    }

    return globals.activate(package, constraint);
  }
}
