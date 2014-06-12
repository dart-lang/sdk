// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.run;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:stack_trace/stack_trace.dart';

import '../barback/asset_environment.dart';
import '../command.dart';
import '../exit_codes.dart' as exit_codes;
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';

final _arrow = getSpecial('\u2192', '=>');

/// Handles the `run` pub command.
class RunCommand extends PubCommand {
  bool get takesArguments => true;
  bool get allowTrailingOptions => false;
  String get description => "Run an executable from a package.";
  String get usage => "pub run <executable> [args...]";

  Future onRun() {
    if (commandOptions.rest.isEmpty) {
      usageError("Must specify an executable to run.");
    }

    // Unless the user overrides the verbosity, we want to filter out the
    // normal pub output shown while loading the environment.
    if (log.verbosity == log.Verbosity.NORMAL) {
      log.verbosity = log.Verbosity.WARNING;
    }

    var environment;
    return AssetEnvironment.create(entrypoint, BarbackMode.RELEASE,
        WatcherType.NONE, useDart2JS: false)
          .then((_environment) {
      environment = _environment;

      // Show in-progress errors, but not results. Those get handled
      // implicitly by getAllAssets().
      environment.barback.errors.listen((error) {
        log.error(log.red("Build error:\n$error"));
      });

      return environment.serveDirectory("bin");
    }).then((server) {
      var script = commandOptions.rest[0];
      var args = commandOptions.rest.skip(1).toList();

      // TODO(rnystrom): Support scripts in other directories.
      var scriptPath = "bin/$script.dart";

      // Try to make sure the entrypoint script exists (or is generated) before
      // we spawn the process to run it.
      return environment.barback.getAssetById(
          new AssetId(entrypoint.root.name, scriptPath)).then((_) {
        return environment.getUrlsForAssetPath(scriptPath).then((urls) {
          // Should only be bound to one port.
          assert(urls.length == 1);

          // Run in checked mode.
          // TODO(rnystrom): Make this configurable.
          args.insert(0, "--checked");

          // The URL to the Dart entrypoint comes before the script arguments.
          args.insert(1, urls[0].toString());
          return Process.start(Platform.executable, args);
        }).then((process) {
          // Note: we're not using process.std___.pipe(std___) here because
          // that prevents pub from also writing to the output streams.
          process.stderr.listen(stderr.add);
          process.stdout.listen(stdout.add);
          stdin.listen(process.stdin.add);

          return process.exitCode;
        }).then(flushThenExit);
      }).catchError((error, stackTrace) {
        if (error is! AssetNotFoundException) throw error;

        log.error("Could not find $scriptPath.");
        log.fine(new Chain.forTrace(stackTrace));
        return flushThenExit(exit_codes.NO_INPUT);
      });
    });
  }
}
