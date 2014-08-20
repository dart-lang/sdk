// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.global_packages;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'entrypoint.dart';
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
  Future activateGit(String repo) {
    var source = cache.sources["git"] as GitSource;
    return source.getPackageNameFromRepo(repo).then((name) {
      // Call this just to log what the current active package is, if any.
      _describeActive(name);

      return _installInCache(
          new PackageDep(name, "git", VersionConstraint.any, repo));
    });
  }

  /// Finds the latest version of the hosted package with [name] that matches
  /// [constraint] and makes it the active global version.
  Future activateHosted(String name, VersionConstraint constraint) {
    _describeActive(name);
    return _installInCache(new PackageDep(name, "hosted", constraint, name));
  }

  /// Makes the local package at [path] globally active.
  Future activatePath(String path) {
    var entrypoint = new Entrypoint(path, cache);

    // Get the package's dependencies.
    return entrypoint.ensureLockFileIsUpToDate().then((_) {
      var name = entrypoint.root.name;

      // Call this just to log what the current active package is, if any.
      _describeActive(name);

      // Write a lockfile that points to the local package.
      var fullPath = canonicalize(entrypoint.root.dir);
      var id = new PackageId(name, "path", entrypoint.root.version,
          PathSource.describePath(fullPath));
      _writeLockFile(name, new LockFile([id]));
    });
  }

  /// Installs the package [dep] and its dependencies into the system cache.
  Future _installInCache(PackageDep dep) {
    var source = cache.sources[dep.source];

    // Create a dummy package with just [dep] so we can do resolution on it.
    var root = new Package.inMemory(new Pubspec("pub global activate",
        dependencies: [dep], sources: cache.sources));

    // Resolve it and download its dependencies.
    return resolveVersions(SolveType.GET, cache.sources, root).then((result) {
      if (!result.succeeded) throw result.error;
      result.showReport(SolveType.GET);

      // Make sure all of the dependencies are locally installed.
      return Future.wait(result.packages.map(_cacheDependency));
    }).then((ids) {
      _writeLockFile(dep.name, new LockFile(ids));
    });
  }

  /// Downloads [id] into the system cache if it's a cached package.
  ///
  /// Returns the resolved [PackageId] for [id].
  Future<PackageId> _cacheDependency(PackageId id) {
    var source = cache.sources[id.source];

    return syncFuture(() {
      if (id.isRoot) return null;
      if (source is! CachedSource) return null;

      return source.downloadToSystemCache(id);
    }).then((_) => source.resolveId(id));
  }

  /// Finishes activating package [package] by saving [lockFile] in the cache.
  void _writeLockFile(String package, LockFile lockFile) {
    ensureDir(_directory);
    writeTextFile(_getLockFilePath(package),
        lockFile.serialize(cache.rootDir, cache.sources));

    var id = lockFile.packages[package];
    if (id.source == "git") {
      var url = GitSource.urlFromDescription(id.description);
      log.message('Activated ${log.bold(id.name)} ${id.version} from Git '
          'repository "$url".');
    } else if (id.source == "path") {
      var path = PathSource.pathFromDescription(id.description);
      log.message('Activated ${log.bold(id.name)} ${id.version} at path '
          '"$path".');
    } else {
      log.message("Activated ${log.bold(id.name)} ${id.version}.");
    }

    // TODO(rnystrom): Look in "bin" and display list of binaries that
    // user can run.
  }

  /// Shows the user the currently active package with [name], if any.
  void _describeActive(String package) {
    try {
      var lockFile = new LockFile.load(_getLockFilePath(package),
          cache.sources);
      var id = lockFile.packages[package];

      if (id.source == "git") {
        var url = GitSource.urlFromDescription(id.description);
        log.message('Package ${log.bold(id.name)} is currently active from '
            'Git repository "${url}".');
      } else if (id.source == "path") {
        var path = PathSource.pathFromDescription(id.description);
        log.message('Package ${log.bold(package)} is currently active at '
            'path "$path".');
      } else {
        log.message("Package ${log.bold(package)} is currently active at "
            "version ${log.bold(id.version)}.");
      }
    } on IOException catch (error) {
      // If we couldn't read the lock file, it's not activated.
      return null;
    }
  }

  /// Deactivates a previously-activated package named [name].
  ///
  /// If [logDeletion] is true, displays to the user when a package is
  /// deactivated. Otherwise, deactivates silently.
  ///
  /// Returns `false` if no package with [name] was currently active.
  bool deactivate(String name, {bool logDeactivate: false}) {
    var lockFilePath = _getLockFilePath(name);
    if (!fileExists(lockFilePath)) return false;

    var lockFile = new LockFile.load(lockFilePath, cache.sources);
    var id = lockFile.packages[name];

    deleteEntry(lockFilePath);

    if (logDeactivate) {
      if (id.source == "git") {
        var url = GitSource.urlFromDescription(id.description);
        log.message('Deactivated package ${log.bold(name)} from Git repository '
            '"$url".');
      } else if (id.source == "path") {
        var path = PathSource.pathFromDescription(id.description);
        log.message('Deactivated package ${log.bold(name)} at path "$path".');
      } else {
        log.message("Deactivated package ${log.bold(name)} ${id.version}.");
      }
    }

    return true;
  }

  /// Finds the active package with [name].
  ///
  /// Returns an [Entrypoint] loaded with the active package if found.
  Future<Entrypoint> find(String name) {
    return syncFuture(() {
      var lockFile;
      try {
        lockFile = new LockFile.load(_getLockFilePath(name), cache.sources);
      } on IOException catch (error) {
        // If we couldn't read the lock file, it's not activated.
        dataError("No active package ${log.bold(name)}.");
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

  /// Gets the path to the lock file for an activated cached package with
  /// [name].
  String _getLockFilePath(name) => p.join(_directory, name + ".lock");
}
