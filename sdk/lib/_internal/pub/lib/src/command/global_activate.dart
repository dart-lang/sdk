// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.global_activate;

import 'dart:async';

import 'package:pub_semver/pub_semver.dart';

import '../command.dart';
import '../utils.dart';

/// Handles the `global activate` pub command.
class GlobalActivateCommand extends PubCommand {
  String get name => "activate";
  String get description => "Make a package's executables globally available.";
  String get invocation => "pub global activate <package...>";

  GlobalActivateCommand() {
    argParser.addOption("source",
        abbr: "s",
        help: "The source used to find the package.",
        allowed: ["git", "hosted", "path"],
        defaultsTo: "hosted");

    argParser.addFlag("no-executables", negatable: false,
        help: "Do not put executables on PATH.");

    argParser.addOption("executable", abbr: "x",
        help: "Executable(s) to place on PATH.",
        allowMultiple: true);

    argParser.addFlag("overwrite", negatable: false,
        help: "Overwrite executables from other packages with the same name.");
  }

  Future run() {
    // Default to `null`, which means all executables.
    var executables;
    if (argResults.wasParsed("executable")) {
      if (argResults.wasParsed("no-executables")) {
        usageException("Cannot pass both --no-executables and --executable.");
      }

      executables = argResults["executable"];
    } else if (argResults["no-executables"]) {
      // An empty list means no executables.
      executables = [];
    }

    var overwrite = argResults["overwrite"];
    var args = argResults.rest;

    readArg([String error]) {
      if (args.isEmpty) usageException(error);
      var arg = args.first;
      args = args.skip(1);
      return arg;
    }

    validateNoExtraArgs() {
      if (args.isEmpty) return;
      var unexpected = args.map((arg) => '"$arg"');
      var arguments = pluralize("argument", unexpected.length);
      usageException("Unexpected $arguments ${toSentence(unexpected)}.");
    }

    switch (argResults["source"]) {
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
            usageException(error.message);
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
