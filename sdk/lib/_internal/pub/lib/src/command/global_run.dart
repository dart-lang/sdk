// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.global_run;

import 'dart:async';

import '../command.dart';
import '../executable.dart';
import '../io.dart';

/// Handles the `global run` pub command.
class GlobalRunCommand extends PubCommand {
  bool get takesArguments => true;
  bool get allowTrailingOptions => false;
  String get description =>
      "Run an executable from a globally activated package.";
  String get usage => "pub global run <package>:<executable> [args...]";

  Future onRun() {
    if (commandOptions.rest.isEmpty) {
      usageError("Must specify an executable to run.");
    }

    if (!commandOptions.rest[0].contains(":")) {
      // TODO(rnystrom): Allow "foo" as a synonym for "foo:foo"?
      usageError("Must specify a package from which to run the executable.");
    }

    var parts = split1(commandOptions.rest[0], ":");
    var package = parts[0];
    var executable = parts[1];
    var args = commandOptions.rest.skip(1).toList();

    return globals.find(package).then((entrypoint) {
      return runExecutable(this, entrypoint, package, executable, args,
          isGlobal: true);
    }).then(flushThenExit);
  }
}
