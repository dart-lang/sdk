// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.global_packages;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:barback/barback.dart';

import 'barback/asset_environment.dart';
import 'entrypoint.dart';
import 'executable.dart' as exe;
import 'io.dart';
import 'lock_file.dart';
import 'log.dart' as log;
import 'package.dart';
import 'pubspec.dart';
import 'sdk.dart' as sdk;
import 'solver/version_solver.dart';
import 'source/cached.dart';
import 'source/git.dart';
import 'source/path.dart';
import 'system_cache.dart';
import 'utils.dart';
import 'version.dart';

/// Matches the package name that a binstub was created for inside the contents
/// of the shell script.
final _binStubPackagePattern = new RegExp(r"Package: ([a-zA-Z0-9_-]+)");

/// Maintains the set of packages that have been globally activated.
///
/// These have been hand-chosen by the user to make their executables in bin/
/// available to the entire system. This lets them access them even when the
/// current working directory is not inside another entrypoint package.
///
/// Only one version of a given package name can be globally activated at a
/// time. Activating a different version of a package will deactivate the
/// previous one.
///
/// This handles packages from uncached and cached sources a little differently.
/// For a cached source, the package is physically in the user's pub cache and
/// we don't want to mess with it by putting a lockfile in there. Instead, when
/// we activate the package, we create a full lockfile and put it in the
/// "global_packages" directory. It's named "<package>.lock". Unlike a normal
/// lockfile, it also contains an entry for the root package itself, so that we
/// know the version and description that was activated.
///
/// Uncached packages (i.e. "path" packages) are somewhere else on the user's
/// local file system and can have a lockfile directly in place. (And, in fact,
/// we want to ensure we honor the user's lockfile there.) To activate it, we
/// just need to know where that package directory is. For that, we create a
/// lockfile that *only* contains the root package's [PackageId] -- basically
/// just the path to the directory where the real lockfile lives.
class GlobalPackages {
  /// The [SystemCache] containing the global packages.
  final SystemCache cache;

  /// The directory where the lockfiles for activated packages are stored.
  String get _directory => p.join(cache.rootDir, "global_packages");

  /// The directory where binstubs for global package executables are stored.
  String get _binStubDir => p.join(cache.rootDir, "bin");

  /// Creates a new global package registry backed by the given directory on
  /// the user's file system.
  ///
  /// The directory may not physically exist yet. If not, this will create it
  /// when needed.
  GlobalPackages(this.cache);

  /// Caches the package located in the Git repository [repo] and makes it the
  /// active global version.
  ///
  /// [executables] is the names of the executables that should have binstubs.
  /// If `null`, all executables in the package will get binstubs. If empty, no
  /// binstubs will be created.
  ///
  /// if [overwriteBinStubs] is `true`, any binstubs that collide with
  /// existing binstubs in other packages will be overwritten by this one's.
  /// Otherwise, the previous ones will be preserved.
  Future activateGit(String repo, List<String> executables,
      {bool overwriteBinStubs}) async {
    var source = cache.sources["git"] as GitSource;
    var name = await source.getPackageNameFromRepo(repo);
    // Call this just to log what the current active package is, if any.
    _describeActive(name);

    // TODO(nweiz): Add some special handling for git repos that contain path
    // dependencies. Their executables shouldn't be cached, and there should
    // be a mechanism for redoing dependency resolution if a path pubspec has
    // changed (see also issue 20499).
    await _installInCache(
        new PackageDep(name, "git", VersionConstraint.any, repo),
        executables, overwriteBinStubs: overwriteBinStubs);
  }

  /// Finds the latest version of the hosted package with [name] that matches
  /// [constraint] and makes it the active global version.
  ///
  /// [executables] is the names of the executables that should have binstubs.
  /// If `null`, all executables in the package will get binstubs. If empty, no
  /// binstubs will be created.
  ///
  /// if [overwriteBinStubs] is `true`, any binstubs that collide with
  /// existing binstubs in other packages will be overwritten by this one's.
  /// Otherwise, the previous ones will be preserved.
  Future activateHosted(String name, VersionConstraint constraint,
      List<String> executables, {bool overwriteBinStubs}) async {
    _describeActive(name);
    await _installInCache(new PackageDep(name, "hosted", constraint, name),
        executables, overwriteBinStubs: overwriteBinStubs);
  }

  /// Makes the local package at [path] globally active.
  ///
  /// [executables] is the names of the executables that should have binstubs.
  /// If `null`, all executables in the package will get binstubs. If empty, no
  /// binstubs will be created.
  ///
  /// if [overwriteBinStubs] is `true`, any binstubs that collide with
  /// existing binstubs in other packages will be overwritten by this one's.
  /// Otherwise, the previous ones will be preserved.
  Future activatePath(String path, List<String> executables,
      {bool overwriteBinStubs}) async {
    var entrypoint = new Entrypoint(path, cache);

    // Get the package's dependencies.
    await entrypoint.ensureLockFileIsUpToDate();
    var name = entrypoint.root.name;

    // Call this just to log what the current active package is, if any.
    _describeActive(name);

    // Write a lockfile that points to the local package.
    var fullPath = canonicalize(entrypoint.root.dir);
    var id = new PackageId(name, "path", entrypoint.root.version,
        PathSource.describePath(fullPath));

    // TODO(rnystrom): Look in "bin" and display list of binaries that
    // user can run.
    _writeLockFile(name, new LockFile([id]));

    var binDir = p.join(_directory, name, 'bin');
    if (dirExists(binDir)) deleteEntry(binDir);

    _updateBinStubs(entrypoint.root, executables,
        overwriteBinStubs: overwriteBinStubs);
  }

  /// Installs the package [dep] and its dependencies into the system cache.
  Future _installInCache(PackageDep dep, List<String> executables,
      {bool overwriteBinStubs}) async {
    var source = cache.sources[dep.source];

    // Create a dummy package with just [dep] so we can do resolution on it.
    var root = new Package.inMemory(new Pubspec("pub global activate",
        dependencies: [dep], sources: cache.sources));

    // Resolve it and download its dependencies.
    var result = await resolveVersions(SolveType.GET, cache.sources, root);
    if (!result.succeeded) {
      // If the package specified by the user doesn't exist, we want to
      // surface that as a [DataError] with the associated exit code.
      if (result.error.package != dep.name) throw result.error;
      if (result.error is NoVersionException) dataError(result.error.message);
      throw result.error;
    }
    result.showReport(SolveType.GET);

    // Make sure all of the dependencies are locally installed.
    var ids = await Future.wait(result.packages.map(_cacheDependency));
    var lockFile = new LockFile(ids);

    // Load the package graph from [result] so we don't need to re-parse all
    // the pubspecs.
    var graph = await new Entrypoint.inMemory(root, lockFile, cache)
        .loadPackageGraph(result);
    var snapshots = await _precompileExecutables(graph.entrypoint, dep.name);
    _writeLockFile(dep.name, lockFile);

    _updateBinStubs(graph.packages[dep.name], executables,
        overwriteBinStubs: overwriteBinStubs, snapshots: snapshots);
  }

  /// Precompiles the executables for [package] and saves them in the global
  /// cache.
  ///
  /// Returns a map from executable name to path for the snapshots that were
  /// successfully precompiled.
  Future<Map<String, String>> _precompileExecutables(Entrypoint entrypoint,
      String package) {
    return log.progress("Precompiling executables", () async {
      var binDir = p.join(_directory, package, 'bin');
      cleanDir(binDir);

      var graph = await entrypoint.loadPackageGraph();
      var environment = await AssetEnvironment.create(
          entrypoint, BarbackMode.RELEASE,
          entrypoints: graph.packages[package].executableIds,
          useDart2JS: false);
      environment.barback.errors.listen((error) {
        log.error(log.red("Build error:\n$error"));
      });

      return environment.precompileExecutables(package, binDir);
    });
  }

  /// Downloads [id] into the system cache if it's a cached package.
  ///
  /// Returns the resolved [PackageId] for [id].
  Future<PackageId> _cacheDependency(PackageId id) async {
    var source = cache.sources[id.source];

    if (!id.isRoot && source is CachedSource) {
      await source.downloadToSystemCache(id);
    }

    return source.resolveId(id);
  }

  /// Finishes activating package [package] by saving [lockFile] in the cache.
  void _writeLockFile(String package, LockFile lockFile) {
    ensureDir(p.join(_directory, package));

    // TODO(nweiz): This cleans up Dart 1.6's old lockfile location. Remove it
    // when Dart 1.6 is old enough that we don't think anyone will have these
    // lockfiles anymore (issue 20703).
    var oldPath = p.join(_directory, "$package.lock");
    if (fileExists(oldPath)) deleteEntry(oldPath);

    writeTextFile(_getLockFilePath(package),
        lockFile.serialize(cache.rootDir, cache.sources));

    var id = lockFile.packages[package];
    log.message('Activated ${_formatPackage(id)}.');
  }

  /// Shows the user the currently active package with [name], if any.
  void _describeActive(String name) {
    try {
      var lockFile = new LockFile.load(_getLockFilePath(name), cache.sources);
      var id = lockFile.packages[name];

      if (id.source == 'git') {
        var url = GitSource.urlFromDescription(id.description);
        log.message('Package ${log.bold(name)} is currently active from Git '
            'repository "${url}".');
      } else if (id.source == 'path') {
        var path = PathSource.pathFromDescription(id.description);
        log.message('Package ${log.bold(name)} is currently active at path '
            '"$path".');
      } else {
        log.message('Package ${log.bold(name)} is currently active at version '
            '${log.bold(id.version)}.');
      }
    } on IOException catch (error) {
      // If we couldn't read the lock file, it's not activated.
      return null;
    }
  }

  /// Deactivates a previously-activated package named [name].
  ///
  /// Returns `false` if no package with [name] was currently active.
  bool deactivate(String name) {
    var dir = p.join(_directory, name);
    if (!dirExists(dir)) return false;

    _deleteBinStubs(name);

    var lockFile = new LockFile.load(_getLockFilePath(name), cache.sources);
    var id = lockFile.packages[name];
    log.message('Deactivated package ${_formatPackage(id)}.');

    deleteEntry(dir);

    return true;
  }

  /// Finds the active package with [name].
  ///
  /// Returns an [Entrypoint] loaded with the active package if found.
  Future<Entrypoint> find(String name) {
    // TODO(rnystrom): Use async/await here when on __ catch is supported.
    // See: https://github.com/dart-lang/async_await/issues/27
    return new Future.sync(() {
      var lockFilePath = _getLockFilePath(name);
      var lockFile;
      try {
        lockFile = new LockFile.load(lockFilePath, cache.sources);
      } on IOException catch (error) {
        var oldLockFilePath = p.join(_directory, '$name.lock');
        try {
          // TODO(nweiz): This looks for Dart 1.6's old lockfile location.
          // Remove it when Dart 1.6 is old enough that we don't think anyone
          // will have these lockfiles anymore (issue 20703).
          lockFile = new LockFile.load(oldLockFilePath, cache.sources);
        } on IOException catch (error) {
          // If we couldn't read the lock file, it's not activated.
          dataError("No active package ${log.bold(name)}.");
        }

        // Move the old lockfile to its new location.
        ensureDir(p.dirname(lockFilePath));
        new File(oldLockFilePath).renameSync(lockFilePath);
      }

      // Load the package from the cache.
      var id = lockFile.packages[name];
      lockFile.packages.remove(name);

      var source = cache.sources[id.source];
      if (source is CachedSource) {
        // For cached sources, the package itself is in the cache and the
        // lockfile is the one we just loaded.
        return cache.sources[id.source].getDirectory(id)
            .then((dir) => new Package.load(name, dir, cache.sources))
            .then((package) {
          return new Entrypoint.inMemory(package, lockFile, cache);
        });
      }

      // For uncached sources (i.e. path), the ID just points to the real
      // directory for the package.
      assert(id.source == "path");
      return new Entrypoint(PathSource.pathFromDescription(id.description),
          cache);
    });
  }

  /// Runs [package]'s [executable] with [args].
  ///
  /// If [executable] is available in its precompiled form, that will be
  /// recompiled if the SDK has been upgraded since it was first compiled and
  /// then run. Otherwise, it will be run from source.
  ///
  /// If [mode] is passed, it's used as the barback mode; it defaults to
  /// [BarbackMode.RELEASE].
  ///
  /// Returns the exit code from the executable.
  Future<int> runExecutable(String package, String executable,
      Iterable<String> args, {BarbackMode mode}) {
    if (mode == null) mode = BarbackMode.RELEASE;

    var binDir = p.join(_directory, package, 'bin');
    if (mode != BarbackMode.RELEASE ||
        !fileExists(p.join(binDir, '$executable.dart.snapshot'))) {
      return find(package).then((entrypoint) {
        return exe.runExecutable(entrypoint, package, executable, args,
            mode: mode, isGlobal: true);
      });
    }

    // Unless the user overrides the verbosity, we want to filter out the
    // normal pub output shown while loading the environment.
    if (log.verbosity == log.Verbosity.NORMAL) {
      log.verbosity = log.Verbosity.WARNING;
    }

    var snapshotPath = p.join(binDir, '$executable.dart.snapshot');
    return exe.runSnapshot(snapshotPath, args, recompile: () {
      log.fine("$package:$executable is out of date and needs to be "
          "recompiled.");
      return find(package)
          .then((entrypoint) => entrypoint.loadPackageGraph())
          .then((graph) => _precompileExecutables(graph.entrypoint, package));
    });
  }

  /// Gets the path to the lock file for an activated cached package with
  /// [name].
  String _getLockFilePath(String name) =>
      p.join(_directory, name, "pubspec.lock");

  /// Shows to the user formatted list of globally activated packages.
  void listActivePackages() {
    if (!dirExists(_directory)) return;

    // Loads lock [file] and returns [PackageId] of the activated package.
    loadPackageId(file, name) {
      var lockFile = new LockFile.load(p.join(_directory, file), cache.sources);
      return lockFile.packages[name];
    }

    var packages = listDir(_directory).map((entry) {
      if (fileExists(entry)) {
        return loadPackageId(entry, p.basenameWithoutExtension(entry));
      } else {
        return loadPackageId(p.join(entry, 'pubspec.lock'), p.basename(entry));
      }
    }).toList();

    packages
        ..sort((id1, id2) => id1.name.compareTo(id2.name))
        ..forEach((id) => log.message(_formatPackage(id)));
  }

  /// Returns formatted string representing the package [id].
  String _formatPackage(PackageId id) {
    if (id.source == 'git') {
      var url = GitSource.urlFromDescription(id.description);
      return '${log.bold(id.name)} ${id.version} from Git repository "$url"';
    } else if (id.source == 'path') {
      var path = PathSource.pathFromDescription(id.description);
      return '${log.bold(id.name)} ${id.version} at path "$path"';
    } else {
      return '${log.bold(id.name)} ${id.version}';
    }
  }

  /// Updates the binstubs for [package].
  ///
  /// A binstub is a little shell script in `PUB_CACHE/bin` that runs an
  /// executable from a globally activated package. This removes any old
  /// binstubs from the previously activated version of the package and
  /// (optionally) creates new ones for the executables listed in the package's
  /// pubspec.
  ///
  /// [executables] is the names of the executables that should have binstubs.
  /// If `null`, all executables in the package will get binstubs. If empty, no
  /// binstubs will be created.
  ///
  /// If [overwriteBinStubs] is `true`, any binstubs that collide with
  /// existing binstubs in other packages will be overwritten by this one's.
  /// Otherwise, the previous ones will be preserved.
  ///
  /// If [snapshots] is given, it is a map of the names of executables whose
  /// snapshots that were precompiled to their paths. Binstubs for those will
  /// run the snapshot directly and skip pub entirely.
  void _updateBinStubs(Package package, List<String> executables,
      {bool overwriteBinStubs, Map<String, String> snapshots}) {
    if (snapshots == null) snapshots = const {};

    // Remove any previously activated binstubs for this package, in case the
    // list of executables has changed.
    _deleteBinStubs(package.name);

    if ((executables != null && executables.isEmpty) ||
        package.pubspec.executables.isEmpty) {
      return;
    }

    ensureDir(_binStubDir);

    var installed = [];
    var collided = {};
    var allExecutables = ordered(package.pubspec.executables.keys);
    for (var executable in allExecutables) {
      if (executables != null && !executables.contains(executable)) continue;

      var script = package.pubspec.executables[executable];

      var previousPackage = _createBinStub(package, executable, script,
          overwrite: overwriteBinStubs, snapshot: snapshots[script]);
      if (previousPackage != null) {
        collided[executable] = previousPackage;

        if (!overwriteBinStubs) continue;
      }

      installed.add(executable);
    }

    if (installed.isNotEmpty) {
      var names = namedSequence("executable", installed.map(log.bold));
      log.message("Installed $names.");
    }

    // Show errors for any collisions.
    if (collided.isNotEmpty) {
      for (var command in ordered(collided.keys)) {
        if (overwriteBinStubs) {
          log.warning("Replaced ${log.bold(command)} previously installed from "
              "${log.bold(collided[command])}.");
        } else {
          log.warning("Executable ${log.bold(command)} was already installed "
              "from ${log.bold(collided[command])}.");
        }
      }

      if (!overwriteBinStubs) {
        log.warning("Deactivate the other package(s) or activate "
            "${log.bold(package.name)} using --overwrite.");
      }
    }

    // Show errors for any unknown executables.
    if (executables != null) {
      var unknown = ordered(executables.where(
          (exe) => !package.pubspec.executables.keys.contains(exe)));
      if (unknown.isNotEmpty) {
        dataError("Unknown ${namedSequence('executable', unknown)}.");
      }
    }

    // Show errors for any missing scripts.
    // TODO(rnystrom): This can print false positives since a script may be
    // produced by a transformer. Do something better.
    var binFiles = package.listFiles(beneath: "bin", recursive: false)
        .map((path) => package.relative(path))
        .toList();
    for (var executable in installed) {
      var script = package.pubspec.executables[executable];
      var scriptPath = p.join("bin", "$script.dart");
      if (!binFiles.contains(scriptPath)) {
        log.warning('Warning: Executable "$executable" runs "$scriptPath", '
            'which was not found in ${log.bold(package.name)}.');
      }
    }

    if (installed.isNotEmpty) _suggestIfNotOnPath(installed);
  }

  /// Creates a binstub named [executable] that runs [script] from [package].
  ///
  /// If [overwrite] is `true`, this will replace an existing binstub with that
  /// name for another package.
  ///
  /// If [snapshot] is non-null, it is a path to a snapshot file. The binstub
  /// will invoke that directly. Otherwise, it will run `pub global run`.
  ///
  /// If a collision occurs, returns the name of the package that owns the
  /// existing binstub. Otherwise returns `null`.
  String _createBinStub(Package package, String executable, String script,
      {bool overwrite, String snapshot}) {
    var binStubPath = p.join(_binStubDir, executable);

    // See if the binstub already exists. If so, it's for another package
    // since we already deleted all of this package's binstubs.
    var previousPackage;
    if (fileExists(binStubPath)) {
      var contents = readTextFile(binStubPath);
      var match = _binStubPackagePattern.firstMatch(contents);
      if (match != null) {
        previousPackage = match[1];
        if (!overwrite) return previousPackage;
      } else {
        log.fine("Could not parse binstub $binStubPath:\n$contents");
      }
    }

    // If the script was precompiled to a snapshot, just invoke that directly
    // and skip pub global run entirely.
    var invocation;
    if (snapshot != null) {
      // We expect absolute paths from the precompiler since relative ones
      // won't be relative to the right directory when the user runs this.
      assert(p.isAbsolute(snapshot));
      invocation = 'dart "$snapshot"';
    } else {
      invocation = "pub global run ${package.name}:$script";
    }

    if (Platform.operatingSystem == "windows") {

      var batch = """
@echo off
rem This file was created by pub v${sdk.version}.
rem Package: ${package.name}
rem Version: ${package.version}
rem Executable: ${executable}
rem Script: ${script}
$invocation "%*"
""";
      writeTextFile(binStubPath, batch);
    } else {
      var bash = """
#!/usr/bin/env sh
# This file was created by pub v${sdk.version}.
# Package: ${package.name}
# Version: ${package.version}
# Executable: ${executable}
# Script: ${script}
$invocation "\$@"
""";
      writeTextFile(binStubPath, bash);

      // Make it executable.
      var result = Process.runSync('chmod', ['+x', binStubPath]);
      if (result.exitCode != 0) {
        // Couldn't make it executable so don't leave it laying around.
        try {
          deleteEntry(binStubPath);
        } on IOException catch (err) {
          // Do nothing. We're going to fail below anyway.
          log.fine("Could not delete binstub:\n$err");
        }

        fail('Could not make "$binStubPath" executable (exit code '
            '${result.exitCode}):\n${result.stderr}');
      }
    }

    return previousPackage;
  }

  /// Deletes all existing binstubs for [package].
  void _deleteBinStubs(String package) {
    if (!dirExists(_binStubDir)) return;

    for (var file in listDir(_binStubDir, includeDirs: false)) {
      var contents = readTextFile(file);
      var match = _binStubPackagePattern.firstMatch(contents);
      if (match == null) {
        log.fine("Could not parse binstub $file:\n$contents");
        continue;
      }

      if (match[1] == package) {
        log.fine("Deleting old binstub $file");
        deleteEntry(file);
      }
    }
  }

  /// Checks to see if the binstubs are on the user's PATH and, if not, suggests
  /// that the user add the directory to their PATH.
  void _suggestIfNotOnPath(List<String> installed) {
    if (Platform.operatingSystem == "windows") {
      // See if the shell can find one of the binstubs.
      // "\q" means return exit code 0 if found or 1 if not.
      var result = Process.runSync("where", [r"\q", installed.first]);
      if (result.exitCode == 0) return;

      var binDir = _binStubDir;
      if (binDir.startsWith(Platform.environment['APPDATA'])) {
        binDir = p.join("%APPDATA%", p.relative(binDir,
            from: Platform.environment['APPDATA']));
      }

      log.warning(
          "${log.yellow('Warning:')} Pub installs executables into "
              "${log.bold(binDir)}, which is not on your path.\n"
          "You can fix that by adding that directory to your system's "
              '"Path" environment variable.\n'
          'A web search for "configure windows path" will show you how.');
    } else {
      // See if the shell can find one of the binstubs.
      var result = Process.runSync("which", [installed.first]);
      if (result.exitCode == 0) return;

      var binDir = _binStubDir;
      if (binDir.startsWith(Platform.environment['HOME'])) {
        binDir = p.join("~", p.relative(binDir,
            from: Platform.environment['HOME']));
      }

      log.warning(
          "${log.yellow('Warning:')} Pub installs executables into "
              "${log.bold(binDir)}, which is not on your path.\n"
          "You can fix that by adding this to your shell's config file "
              "(.bashrc, .bash_profile, etc.):\n"
          "\n"
          "\n${log.bold('export PATH="\$PATH":"$binDir"')}\n");
    }
  }
}
