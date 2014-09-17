// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.run;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;

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

  RunCommand() {
    commandParser.addOption("mode",
        help: 'Mode to run transformers in.\n'
              '(defaults to "release" for dependencies, "debug" for '
                'entrypoint)');
  }

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

      if (p.split(executable).length > 1) {
      // TODO(nweiz): Use adjacent strings when the new async/await compiler
      // lands.
        usageError("Cannot run an executable in a subdirectory of a " +
            "dependency.");
      }
    }

    var mode;
    if (commandOptions['mode'] != null) {
      mode = new BarbackMode(commandOptions['mode']);
    } else if (package == entrypoint.root.name) {
      mode = BarbackMode.DEBUG;
    } else {
      mode = BarbackMode.RELEASE;
    }

    var exitCode = await runExecutable(entrypoint, package, executable, args,
        mode: mode);
    await flushThenExit(exitCode);
  }
}
