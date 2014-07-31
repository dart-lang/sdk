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
import 'system_cache.dart';
import 'solver/version_solver.dart';
import 'source.dart';
import 'source/cached.dart';
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

  /// Activates the Git repo described by [ref] for package [name].
  Future activateGit(String name, String ref) {
    // See if we already have it activated.
    var lockFile = _describeActive(name);
    var id;
    if (lockFile != null) {
      id = lockFile.packages[name];
    } else {
      id = new PackageId(name, "git", Version.none, ref);
    }

    return _installInCache(id, lockFile);
  }

  /// Finds the latest version of the hosted package with [name] that matches
  /// [constraint] and makes it the active global version.
  Future activateHosted(String name, VersionConstraint constraint) {
    // See if we already have it activated.
    var lockFile = _describeActive(name);
    var currentVersion;
    if (lockFile != null) {
      var id = lockFile.packages[name];

      // Try to preserve the current version if we've already activated the
      // hosted package.
      if (id.source == "hosted") currentVersion = id.version;

      // Pull the root package out of the lock file so the solver doesn't see
      // it.
      lockFile.packages.remove(name);
    } else {
      lockFile = new LockFile.empty();
    }

    return _selectVersion(name, currentVersion, constraint).then((version) {
      // Make sure it's in the cache.
      var id = new PackageId(name, "hosted", version, name);
      return _installInCache(id, lockFile);
    });
  }

  /// Makes the local package at [path] globally active.
  Future activatePath(String path) {
    return syncFuture(() {
      var entrypoint = new Entrypoint(path, cache);

      var name = entrypoint.root.name;
      _describeActive(name);

      // Write a lockfile that points to the local package.
      var fullPath = canonicalize(entrypoint.root.dir);
      var id = new PackageId(name, "path", entrypoint.root.version,
          PathSource.describePath(fullPath));
      _finishActivation(id, new LockFile.empty());
    });
  }

  /// Installs the package [id] with [lockFile] into the system cache.
  Future _installInCache(PackageId id, LockFile lockFile) {
    var source = cache.sources[id.source];

    // Put the main package in the cache.
    return source.downloadToSystemCache(id).then((package) {
      // If we didn't know the version for the ID (which is true for Git
      // packages), look it up now that we have it.
      if (id.version == Version.none) {
        id = id.atVersion(package.version);
      }

      return source.resolveId(id).then((id_) {
        id = id_;

        // Resolve it and download its dependencies.
        return resolveVersions(SolveType.GET, cache.sources, package,
            lockFile: lockFile);
      });
    }).then((result) {
      if (!result.succeeded) throw result.error;
      result.showReport(SolveType.GET);

      // Make sure all of the dependencies are locally installed.
      return Future.wait(result.packages.map(_cacheDependency));
    }).then((ids) {
      _finishActivation(id, new LockFile(ids));
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

  /// Finishes activating package [id] by saving [lockFile] in the cache.
  void _finishActivation(PackageId id, LockFile lockFile) {
    deactivate(id.name);

    // Add the root package to the lockfile.
    lockFile.packages[id.name] = id;

    ensureDir(_directory);
    writeTextFile(_getLockFilePath(id.name),
        lockFile.serialize(cache.rootDir, cache.sources));

    log.message("Activated ${log.bold(id.name)} ${id.version}.");
    // TODO(rnystrom): Look in "bin" and display list of binaries that
    // user can run.
  }

  /// Gets the lock file for the currently activate package with [name].
  ///
  /// Displays a message to the user about the current package, if any. Returns
  /// the [LockFile] for the active package or `null` otherwise.
  LockFile _describeActive(String package) {
    try {
      var lockFile = new LockFile.load(_getLockFilePath(package),
          cache.sources);
      var id = lockFile.packages[package];

      if (id.source == "path") {
        var path = PathSource.pathFromDescription(id.description);
        log.message('Package ${log.bold(package)} is already active at '
            'path "$path".');
      } else {
        log.message("Package ${log.bold(package)} is already active at "
            "version ${log.bold(id.version)}.");
      }

      return lockFile;
    } on IOException catch (error) {
      // If we couldn't read the lock file, it's not activated.
    }
  }

  /// Deactivates a previously-activated package named [name].
  ///
  /// If [logDeletion] is true, displays to the user when a package is
  /// deactivated. Otherwise, deactivates silently.
  ///
  /// Returns `false` if no package with [name] was currently active.
  bool deactivate(String name, {bool logDeletion: false}) {
    var lockFilePath = _getLockFilePath(name);
    if (!fileExists(lockFilePath)) return false;

    var lockFile = new LockFile.load(lockFilePath, cache.sources);
    var id = lockFile.packages[name];

    deleteEntry(lockFilePath);

    if (logDeletion) {
      if (id.source == "path") {
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

  /// Picks the best hosted version of [package] to activate that meets
  /// [constraint].
  ///
  /// If [version] is not `null`, this tries to maintain that version if
  /// possible.
  Future<Version> _selectVersion(String package, Version version,
      VersionConstraint constraint) {
    // If we already have a valid active version, just use it.
    if (version != null && constraint.allows(version)) {
      return new Future.value(version);
    }

    // Otherwise, select the best version the matches the constraint.
    var source = cache.sources["hosted"];
    return source.getVersions(package, package).then((versions) {
      versions = versions.where(constraint.allows).toList();

      if (versions.isEmpty) {
        // TODO(rnystrom): Show most recent unmatching version?
        dataError("Package ${log.bold(package)} has no versions that match "
            "$constraint.");
      }

      // Pick the best matching version.
      versions.sort(Version.prioritize);
      return versions.last;
    });
  }

  /// Gets the path to the lock file for an activated cached package with
  /// [name].
  String _getLockFilePath(name) => p.join(_directory, name + ".lock");
}
