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
import 'utils.dart';

/// Runs [executable] from [package] reachable from [entrypoint].
///
/// The executable string is a relative Dart file path using native path
/// separators with or without a trailing ".dart" extension. It is contained
/// within [package], which should either be the entrypoint package or an
/// immediate dependency of it.
///
/// Arguments from [args] will be passed to the spawned Dart application.
///
/// If [mode] is passed, it's used as the barback mode; it defaults to
/// [BarbackMode.RELEASE].
///
/// Returns the exit code of the spawned app.
Future<int> runExecutable(Entrypoint entrypoint, String package,
    String executable, Iterable<String> args, {bool isGlobal: false,
    BarbackMode mode}) async {
  if (mode == null) mode = BarbackMode.RELEASE;

  // Make sure the package is an immediate dependency of the entrypoint or the
  // entrypoint itself.
  if (entrypoint.root.name != package &&
      !entrypoint.root.immediateDependencies
          .any((dep) => dep.name == package)) {
    var graph = await entrypoint.loadPackageGraph();
    if (graph.packages.containsKey(package)) {
      dataError('Package "$package" is not an immediate dependency.\n'
          'Cannot run executables in transitive dependencies.');
    } else {
      dataError('Could not find package "$package". Did you forget to add a '
          'dependency?');
    }
  }

  // Unless the user overrides the verbosity, we want to filter out the
  // normal pub output shown while loading the environment.
  if (log.verbosity == log.Verbosity.NORMAL) {
    log.verbosity = log.Verbosity.WARNING;
  }

  // Ignore a trailing extension.
  if (p.extension(executable) == ".dart") {
    executable = p.withoutExtension(executable);
  }

  var localSnapshotPath = p.join(".pub", "bin", package,
      "$executable.dart.snapshot");
  if (!isGlobal && fileExists(localSnapshotPath) &&
      // Dependencies are only snapshotted in release mode, since that's the
      // default mode for them to run. We can't run them in a different mode
      // using the snapshot.
      mode == BarbackMode.RELEASE) {
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

  var assetPath = "${p.url.joinAll(p.split(executable))}.dart";
  var id = new AssetId(package, assetPath);

  // TODO(nweiz): Use [packages] to only load assets from packages that the
  // executable might load.
  var environment = await AssetEnvironment.create(entrypoint, mode,
      useDart2JS: false, entrypoints: [id]);
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
    // For other packages, always use the "bin" directory.
    server = await environment.servePackageBinDirectory(package);
  }

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
    vmArgs.add('bin/css.dart');
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
/// If [recompile] is passed, it's called if the snapshot is out-of-date. It's
/// expected to regenerate a snapshot at [path], after which the snapshot will
/// be re-run. It may return a Future.
///
/// If [checked] is set, runs the snapshot in checked mode.
///
/// Returns the snapshot's exit code.
///
/// This doesn't do any validation of the snapshot's SDK version.
Future<int> runSnapshot(String path, Iterable<String> args, {recompile(),
    bool checked: false}) async {
  var vmArgs = [path]..addAll(args);

  // TODO(nweiz): pass a flag to silence the "Wrong full snapshot version"
  // message when issue 20784 is fixed.
  if (checked) vmArgs.insert(0, "--checked");

  // We need to split stdin so that we can send the same input both to the
  // first and second process, if we start more than one.
  var stdin1;
  var stdin2;
  if (recompile == null) {
    stdin1 = stdin;
  } else {
    var pair = tee(stdin);
    stdin1 = pair.first;
    stdin2 = pair.last;
  }

  runProcess(input) async {
    var process = await Process.start(Platform.executable, vmArgs);

    // Note: we're not using process.std___.pipe(std___) here because
    // that prevents pub from also writing to the output streams.
    process.stderr.listen(stderr.add);
    process.stdout.listen(stdout.add);
    input.listen(process.stdin.add);

    return process.exitCode;
  }

  var exitCode = await runProcess(stdin1);
  if (recompile == null || exitCode != 255) return exitCode;

  // Exit code 255 indicates that the snapshot version was out-of-date. If we
  // can recompile, do so.
  await recompile();
  return runProcess(stdin2);
}

/// Runs the executable snapshot at [snapshotPath].
Future<int> _runCachedExecutable(Entrypoint entrypoint, String snapshotPath,
    List<String> args) {
  return runSnapshot(snapshotPath, args, checked: true, recompile: () {
    log.fine("Precompiled executable is out of date.");
    return entrypoint.precompileExecutables();
  });
}
