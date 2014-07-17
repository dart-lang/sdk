// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.executable;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';

import 'barback/asset_environment.dart';
import 'command.dart';
import 'entrypoint.dart';
import 'exit_codes.dart' as exit_codes;
import 'log.dart' as log;
import 'utils.dart';

/// Runs [executable] from [package] reachable from [entrypoint].
///
/// The executable string is a relative Dart file path using native path
/// separators without a trailing ".dart" extension. It is contained within
/// [package], which should either be the entrypoint package or an immediate
/// dependency of it.
///
/// Arguments from [args] will be passed to the spawned Dart application.
///
/// Returns the exit code of the spawned app.
Future<int> runExecutable(PubCommand command, Entrypoint entrypoint,
    String package, String executable, Iterable<String> args,
    {bool isGlobal: false}) {
  // If the command has a path separator, then it's a path relative to the
  // root of the package. Otherwise, it's implicitly understood to be in
  // "bin".
  var rootDir = "bin";
  var parts = p.split(executable);
  if (parts.length > 1) {
    if (isGlobal) {
      command.usageError(
          'Cannot run an executable in a subdirectory of a global package.');
    } else if (package != entrypoint.root.name) {
      command.usageError(
          "Cannot run an executable in a subdirectory of a dependency.");
    }

    rootDir = parts.first;
  } else {
    executable = p.join("bin", executable);
  }

  // Unless the user overrides the verbosity, we want to filter out the
  // normal pub output shown while loading the environment.
  if (log.verbosity == log.Verbosity.NORMAL) {
    log.verbosity = log.Verbosity.WARNING;
  }

  var environment;
  return AssetEnvironment.create(entrypoint, BarbackMode.RELEASE,
      WatcherType.NONE, useDart2JS: false).then((_environment) {
    environment = _environment;

    environment.barback.errors.listen((error) {
      log.error(log.red("Build error:\n$error"));
    });

    if (package == entrypoint.root.name) {
      // Serve the entire root-most directory containing the entrypoint. That
      // ensures that, for example, things like `import '../../utils.dart';`
      // will work from within some deeply nested script.
      return environment.serveDirectory(rootDir);
    }

    // Make sure the dependency exists.
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

    // For other packages, always use the "bin" directory.
    return environment.servePackageBinDirectory(package);
  }).then((server) {
    // Try to make sure the entrypoint script exists (or is generated) before
    // we spawn the process to run it.
    var assetPath = "${p.url.joinAll(p.split(executable))}.dart";
    var id = new AssetId(server.package, assetPath);
    return environment.barback.getAssetById(id).then((_) {
      var vmArgs = [];

      // Run in checked mode.
      // TODO(rnystrom): Make this configurable.
      vmArgs.add("--checked");

      // Get the URL of the executable, relative to the server's root directory.
      var relativePath = p.url.relative(assetPath,
          from: p.url.joinAll(p.split(server.rootDirectory)));
      vmArgs.add(server.url.resolve(relativePath).toString());
      vmArgs.addAll(args);

      return Process.start(Platform.executable, vmArgs).then((process) {
        // Note: we're not using process.std___.pipe(std___) here because
        // that prevents pub from also writing to the output streams.
        process.stderr.listen(stderr.add);
        process.stdout.listen(stdout.add);
        stdin.listen(process.stdin.add);

        return process.exitCode;
      });
    }).catchError((error, stackTrace) {
      if (error is! AssetNotFoundException) throw error;

      var message = "Could not find ${log.bold(executable + ".dart")}";
      if (package != entrypoint.root.name) {
        message += " in package ${log.bold(server.package)}";
      }

      log.error("$message.");
      log.fine(new Chain.forTrace(stackTrace));
      return exit_codes.NO_INPUT;
    });
  });
}
