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
        allowed: ["git", "hosted", "path"],
        defaultsTo: "hosted");

    commandParser.addFlag("no-executables", negatable: false,
        help: "Do not put executables on PATH.");

    commandParser.addOption("executable", abbr: "x",
        help: "Executable(s) to place on PATH.",
        allowMultiple: true);

    commandParser.addFlag("overwrite", negatable: false,
        help: "Overwrite executables from other packages with the same name.");
  }

  Future onRun() {
    // Default to `null`, which means all executables.
    var executables;
    if (commandOptions.wasParsed("executable")) {
      if (commandOptions.wasParsed("no-executables")) {
        usageError("Cannot pass both --no-executables and --executable.");
      }

      executables = commandOptions["executable"];
    } else if (commandOptions["no-executables"]) {
      // An empty list means no executables.
      executables = [];
    }

    var overwrite = commandOptions["overwrite"];
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

    switch (commandOptions["source"]) {
      case "git":
        var repo = readArg("No Git repository given.");
        // TODO(rnystrom): Allow passing in a Git ref too.
        validateNoExtraArgs();
        return globals.activateGit(repo, executables,
            overwriteBinStubs: overwrite);

      case "hosted":
        var package = readArg("No package to activate given.");

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
        return globals.activateHosted(package, constraint, executables,
            overwriteBinStubs: overwrite);

      case "path":
        var path = readArg("No package to activate given.");
        validateNoExtraArgs();
        return globals.activatePath(path, executables,
            overwriteBinStubs: overwrite);
    }

    throw "unreachable";
  }
}
