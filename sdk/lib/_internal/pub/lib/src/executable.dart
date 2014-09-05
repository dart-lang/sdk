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
import 'entrypoint.dart';
import 'exit_codes.dart' as exit_codes;
import 'io.dart';
import 'log.dart' as log;
import 'sdk.dart' as sdk;
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
Future<int> runExecutable(Entrypoint entrypoint, String package,
    String executable, Iterable<String> args, {bool isGlobal: false}) async {
  // Unless the user overrides the verbosity, we want to filter out the
  // normal pub output shown while loading the environment.
  if (log.verbosity == log.Verbosity.NORMAL) {
    log.verbosity = log.Verbosity.WARNING;
  }

  var localSnapshotPath = p.join(".pub", "bin", package,
      "$executable.dart.snapshot");
  if (!isGlobal && fileExists(localSnapshotPath)) {
    return _runCachedExecutable(entrypoint, localSnapshotPath, args);
  }

  // If the command has a path separator, then it's a path relative to the
  // root of the package. Otherwise, it's implicitly understood to be in
  // "bin".
  var rootDir = "bin";
  var parts = p.split(executable);
  if (parts.length > 1) {
    assert(!isGlobal && package == entrypoint.root.name);
    rootDir = parts.first;
  } else {
    executable = p.join("bin", executable);
  }

  // TODO(nweiz): Use [packages] to only load assets from packages that the
  // executable might load.
  var environment = await AssetEnvironment.create(entrypoint,
      BarbackMode.RELEASE, useDart2JS: false);
  environment.barback.errors.listen((error) {
    log.error(log.red("Build error:\n$error"));
  });

  var server;
  if (package == entrypoint.root.name) {
    // Serve the entire root-most directory containing the entrypoint. That
    // ensures that, for example, things like `import '../../utils.dart';`
    // will work from within some deeply nested script.
    server = await environment.serveDirectory(rootDir);
  } else {
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
    server = await environment.servePackageBinDirectory(package);
  }

  // Try to make sure the entrypoint script exists (or is generated) before
  // we spawn the process to run it.
  var assetPath = "${p.url.joinAll(p.split(executable))}.dart";
  var id = new AssetId(server.package, assetPath);
  // TODO(rnystrom): Use try/catch here when
  // https://github.com/dart-lang/async_await/issues/4 is fixed.
  return environment.barback.getAssetById(id).then((_) async {
    var vmArgs = [];

    // Run in checked mode.
    // TODO(rnystrom): Make this configurable.
    vmArgs.add("--checked");

    // Get the URL of the executable, relative to the server's root directory.
    var relativePath = p.url.relative(assetPath,
        from: p.url.joinAll(p.split(server.rootDirectory)));
    vmArgs.add(server.url.resolve(relativePath).toString());
    vmArgs.addAll(args);

    var process = await Process.start(Platform.executable, vmArgs);
    // Note: we're not using process.std___.pipe(std___) here because
    // that prevents pub from also writing to the output streams.
    process.stderr.listen(stderr.add);
    process.stdout.listen(stdout.add);
    stdin.listen(process.stdin.add);

    return process.exitCode;
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
}

/// Runs the snapshot at [path] with [args] and hooks its stdout, stderr, and
/// sdtin to this process's.
///
/// Returns the snapshot's exit code.
///
/// This doesn't do any validation of the snapshot's SDK version.
Future<int> runSnapshot(String path, Iterable<String> args) async {
  var vmArgs = [path]..addAll(args);

  var process = await Process.start(Platform.executable, vmArgs);
  // Note: we're not using process.std___.pipe(std___) here because
  // that prevents pub from also writing to the output streams.
  process.stderr.listen(stderr.add);
  process.stdout.listen(stdout.add);
  stdin.listen(process.stdin.add);

  return process.exitCode;
}

/// Runs the executable snapshot at [snapshotPath].
Future<int> _runCachedExecutable(Entrypoint entrypoint, String snapshotPath,
    List<String> args) async {
  // If the snapshot was compiled with a different SDK version, we need to
  // recompile it.
  var sdkVersionPath = p.join(".pub", "bin", "sdk-version");
  if (!fileExists(sdkVersionPath) ||
      readTextFile(sdkVersionPath) != "${sdk.version}\n") {
    log.fine("Precompiled executables are out of date.");
    await entrypoint.precompileExecutables();
  }

  // TODO(rnystrom): Use cascade here when async_await compiler supports it.
  // See: https://github.com/dart-lang/async_await/issues/26.
  var vmArgs = ["--checked", snapshotPath];
  vmArgs.addAll(args);

  var process = await Process.start(Platform.executable, vmArgs);
  // Note: we're not using process.std___.pipe(std___) here because
  // that prevents pub from also writing to the output streams.
  process.stderr.listen(stderr.add);
  process.stdout.listen(stdout.add);
  stdin.listen(process.stdin.add);

  return process.exitCode;
}
