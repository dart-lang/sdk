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
  String get usage => "pub global activate <package...>";
  bool get takesArguments => true;

  GlobalActivateCommand() {
    commandParser.addOption("source",
        abbr: "s",
        help: "The source used to find the package.",
        allowed: ["hosted", "path"],
        defaultsTo: "hosted");
  }

  Future onRun() {
    var args = commandOptions.rest;

    readArg([String error]) {
      if (args.isEmpty) usageError(error);
      var arg = args.first;
      args = args.skip(1);
      return arg;
    }

    validateNoExtraArgs() {
      if (args.isEmpty) return;
      var unexpected = args.map((arg) => '"$arg"');
      var arguments = pluralize("argument", unexpected.length);
      usageError("Unexpected $arguments ${toSentence(unexpected)}.");
    }

    var package = readArg("No package to activate given.");

    switch (commandOptions["source"]) {
      case "hosted":
        // Parse the version constraint, if there is one.
        var constraint = VersionConstraint.any;
        if (args.isNotEmpty) {
          try {
            constraint = new VersionConstraint.parse(readArg());
          } on FormatException catch (error) {
            usageError(error.message);
          }
        }

        validateNoExtraArgs();
        return globals.activateHosted(package, constraint);

      case "path":
        validateNoExtraArgs();
        return globals.activatePath(package);
    }

    throw "unreachable";
  }
}
