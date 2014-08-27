// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.run;

import 'dart:async';

import '../command.dart';
import '../executable.dart';
import '../io.dart';
import '../utils.dart';

/// Handles the `run` pub command.
class RunCommand extends PubCommand {
  bool get takesArguments => true;
  bool get allowTrailingOptions => false;
  String get description => "Run an executable from a package.\n"
      "NOTE: We are currently optimizing this command's startup time.";
  String get usage => "pub run <executable> [args...]";

  Future onRun() async {
    if (commandOptions.rest.isEmpty) {
      usageError("Must specify an executable to run.");
    }

    var package = entrypoint.root.name;
    var executable = commandOptions.rest[0];
    var args = commandOptions.rest.skip(1).toList();

    // A command like "foo:bar" runs the "bar" script from the "foo" package.
    // If there is no colon prefix, default to the root package.
    if (executable.contains(":")) {
      var components = split1(executable, ":");
      package = components[0];
      executable = components[1];
    }

    var exitCode = await runExecutable(this, entrypoint, package, executable,
        args);
    await flushThenExit(exitCode);
  }
}
