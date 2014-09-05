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
import 'system_cache.dart';
import 'solver/version_solver.dart';
import 'source/cached.dart';
import 'source/git.dart';
import 'source/path.dart';
import 'utils.dart';
import 'version.dart';

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

  /// Creates a new global package registry backed by the given directory on
  /// the user's file system.
  ///
  /// The directory may not physically exist yet. If not, this will create it
  /// when needed.
  GlobalPackages(this.cache);

  /// Caches the package located in the Git repository [repo] and makes it the
  /// active global version.
  Future activateGit(String repo) async {
    var source = cache.sources["git"] as GitSource;
    var name = await source.getPackageNameFromRepo(repo);
    // Call this just to log what the current active package is, if any.
    _describeActive(name);

    // TODO(nweiz): Add some special handling for git repos that contain path
    // dependencies. Their executables shouldn't be cached, and there should
    // be a mechanism for redoing dependency resolution if a path pubspec has
    // changed (see also issue 20499).
    await _installInCache(
        new PackageDep(name, "git", VersionConstraint.any, repo));
  }

  /// Finds the latest version of the hosted package with [name] that matches
  /// [constraint] and makes it the active global version.
  Future activateHosted(String name, VersionConstraint constraint) {
    _describeActive(name);
    return _installInCache(new PackageDep(name, "hosted", constraint, name));
  }

  /// Makes the local package at [path] globally active.
  Future activatePath(String path) async {
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
  }

  /// Installs the package [dep] and its dependencies into the system cache.
  Future _installInCache(PackageDep dep) async {
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
    await _precompileExecutables(graph.entrypoint, dep.name);
    _writeLockFile(dep.name, lockFile);
  }

  /// Precompiles the executables for [package] and saves them in the global
  /// cache.
  Future _precompileExecutables(Entrypoint entrypoint, String package) {
    return log.progress("Precompiling executables", () {
      var binDir = p.join(_directory, package, 'bin');
      cleanDir(binDir);

      return AssetEnvironment.create(entrypoint, BarbackMode.RELEASE,
          useDart2JS: false).then((environment) {
        environment.barback.errors.listen((error) {
          log.error(log.red("Build error:\n$error"));
        });

        return environment.precompileExecutables(package, binDir);
      });
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
  /// If [logDeactivate] is true, displays to the user when a package is
  /// deactivated. Otherwise, deactivates silently.
  ///
  /// Returns `false` if no package with [name] was currently active.
  bool deactivate(String name, {bool logDeactivate: false}) {
    var dir = p.join(_directory, name);
    if (!dirExists(dir)) return false;

    if (logDeactivate) {
      var lockFile = new LockFile.load(_getLockFilePath(name), cache.sources);
      var id = lockFile.packages[name];
      log.message('Deactivated package ${_formatPackage(id)}.');
    }

    deleteEntry(dir);

    return true;
  }

  /// Finds the active package with [name].
  ///
  /// Returns an [Entrypoint] loaded with the active package if found.
  Future<Entrypoint> find(String name) {
    // TODO(rnystrom): Use async/await here when on __ catch is supported.
    // See: https://github.com/dart-lang/async_await/issues/27
    return syncFuture(() {
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
  /// Returns the exit code from the executable.
  Future<int> runExecutable(String package, String executable,
      Iterable<String> args) {
    var binDir = p.join(_directory, package, 'bin');
    if (!fileExists(p.join(binDir, '$executable.dart.snapshot'))) {
      return find(package).then((entrypoint) {
        return exe.runExecutable(entrypoint, package, executable, args,
            isGlobal: true);
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
}
