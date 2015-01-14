// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.global_run;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;

import '../command.dart';
import '../io.dart';
import '../utils.dart';

/// Handles the `global run` pub command.
class GlobalRunCommand extends PubCommand {
  String get name => "run";
  String get description =>
      "Run an executable from a globally activated package.\n"
      "NOTE: We are currently optimizing this command's startup time.";
  String get invocation => "pub global run <package>:<executable> [args...]";
  bool get allowTrailingOptions => false;

  /// The mode for barback transformers.
  BarbackMode get mode => new BarbackMode(argResults["mode"]);

  GlobalRunCommand() {
    argParser.addOption("mode", defaultsTo: "release",
        help: 'Mode to run transformers in.');
  }

  Future run() async {
    if (argResults.rest.isEmpty) {
      usageException("Must specify an executable to run.");
    }

    var package;
    var executable = argResults.rest[0];
    if (executable.contains(":")) {
      var parts = split1(executable, ":");
      package = parts[0];
      executable = parts[1];
    } else {
      // If the package name is omitted, use the same name for both.
      package = executable;
    }

    var args = argResults.rest.skip(1).toList();
    if (p.split(executable).length > 1) {
      // TODO(nweiz): Use adjacent strings when the new async/await compiler
      // lands.
      usageException('Cannot run an executable in a subdirectory of a global ' +
          'package.');
    }

    var exitCode = await globals.runExecutable(package, executable, args,
        mode: mode);
    await flushThenExit(exitCode);
  }
}
