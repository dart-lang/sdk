// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.run;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
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
    var package = entrypoint.root.name;
    var rootDir;
    var scriptPath;
    var args;
    return AssetEnvironment.create(entrypoint, BarbackMode.RELEASE,
        WatcherType.NONE, useDart2JS: false)
          .then((_environment) {
      environment = _environment;

      // Show in-progress errors, but not results. Those get handled
      // implicitly by getAllAssets().
      environment.barback.errors.listen((error) {
        log.error(log.red("Build error:\n$error"));
      });

      var script = commandOptions.rest[0];
      args = commandOptions.rest.skip(1).toList();

      // A command like "foo:bar" runs the "bar" script from the "foo" package.
      // If there is no colon prefix, default to the root package.
      if (script.contains(":")) {
        var components = split1(script, ":");
        package = components[0];
        script = components[1];

        var dep = entrypoint.root.immediateDependencies.firstWhere(
            (dep) => dep.name == package, orElse: () => null);
        if (dep == null) {
          if (environment.graph.packages.containsKey(package)) {
            dataError('Package "$package" is not an immediate dependency.\n'
                'Cannot run executables in transitive dependencies.');
          } else {
            dataError('Could not find package "$package". Did you forget to '
                'add a dependency?');
          }
        }
      }

      // If the command has a path separator, then it's a path relative to the
      // root of the package. Otherwise, it's implicitly understood to be in
      // "bin".
      var parts = path.split(script);
      if (parts.length > 1) {
        if (package != entrypoint.root.name) {
          usageError("Can not run an executable in a subdirectory of a "
              "dependency.");
        }

        scriptPath = "${path.url.joinAll(parts.skip(1))}.dart";
        rootDir = parts.first;
      } else {
        scriptPath = "$script.dart";
        rootDir = "bin";
      }

      if (package == entrypoint.root.name) {
        // Serve the entire root-most directory containing the entrypoint. That
        // ensures that, for example, things like `import '../../utils.dart';`
        // will work from within some deeply nested script.
        return environment.serveDirectory(rootDir);
      } else {
        // For other packages, always use the "bin" directory.
        return environment.servePackageBinDirectory(package);
      }
    }).then((server) {
      // Try to make sure the entrypoint script exists (or is generated) before
      // we spawn the process to run it.
      return environment.barback.getAssetById(
          new AssetId(package, path.url.join(rootDir, scriptPath))).then((_) {

        // Run in checked mode.
        // TODO(rnystrom): Make this configurable.
        var mode = "--checked";
        args = [mode, server.url.resolve(scriptPath).toString()]..addAll(args);

        return Process.start(Platform.executable, args).then((process) {
          // Note: we're not using process.std___.pipe(std___) here because
          // that prevents pub from also writing to the output streams.
          process.stderr.listen(stderr.add);
          process.stdout.listen(stdout.add);
          stdin.listen(process.stdin.add);

          return process.exitCode;
        }).then(flushThenExit);
      }).catchError((error, stackTrace) {
        if (error is! AssetNotFoundException) throw error;

        var message = "Could not find ${path.join(rootDir, scriptPath)}";
        if (package != entrypoint.root.name) {
          message += " in package $package";
        }

        log.error("$message.");
        log.fine(new Chain.forTrace(stackTrace));
        return flushThenExit(exit_codes.NO_INPUT);
      });
    });
  }
}
