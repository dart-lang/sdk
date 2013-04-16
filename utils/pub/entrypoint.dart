// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library entrypoint;

import 'dart:async';

import 'package:pathos/path.dart' as path;

import 'io.dart';
import 'lock_file.dart';
import 'log.dart' as log;
import 'package.dart';
import 'pubspec.dart';
import 'sdk.dart' as sdk;
import 'system_cache.dart';
import 'utils.dart';
import 'version.dart';
import 'solver/version_solver.dart';

/// Pub operates over a directed graph of dependencies that starts at a root
/// "entrypoint" package. This is typically the package where the current
/// working directory is located. An entrypoint knows the [root] package it is
/// associated with and is responsible for managing the "packages" directory
/// for it.
///
/// That directory contains symlinks to all packages used by an app. These links
/// point either to the [SystemCache] or to some other location on the local
/// filesystem.
///
/// While entrypoints are typically applications, a pure library package may end
/// up being used as an entrypoint. Also, a single package may be used as an
/// entrypoint in one context but not in another. For example, a package that
/// contains a reusable library may not be the entrypoint when used by an app,
/// but may be the entrypoint when you're running its tests.
class Entrypoint {
  /// The root package this entrypoint is associated with.
  final Package root;

  /// The system-wide cache which caches packages that need to be fetched over
  /// the network.
  final SystemCache cache;

  /// Packages which are either currently being asynchronously installed to the
  /// directory, or have already been installed.
  final _installs = new Map<PackageId, Future<PackageId>>();

  /// Loads the entrypoint from a package at [rootDir].
  Entrypoint(String rootDir, SystemCache cache)
      : root = new Package.load(null, rootDir, cache.sources),
        cache = cache;

  // TODO(rnystrom): Make this path configurable.
  /// The path to the entrypoint's "packages" directory.
  String get packagesDir => path.join(root.dir, 'packages');

  /// Ensures that the package identified by [id] is installed to the directory.
  /// Returns the resolved [PackageId].
  ///
  /// If this completes successfully, the package is guaranteed to be importable
  /// using the `package:` scheme.
  ///
  /// This will automatically install the package to the system-wide cache as
  /// well if it requires network access to retrieve (specifically, if
  /// `id.source.shouldCache` is true).
  ///
  /// See also [installDependencies].
  Future<PackageId> install(PackageId id) {
    var pendingOrCompleted = _installs[id];
    if (pendingOrCompleted != null) return pendingOrCompleted;

    var packageDir = path.join(packagesDir, id.name);
    var future = new Future.sync(() {
      ensureDir(path.dirname(packageDir));

      if (entryExists(packageDir)) {
        // TODO(nweiz): figure out when to actually delete the directory, and
        // when we can just re-use the existing symlink.
        log.fine("Deleting package directory for ${id.name} before install.");
        deleteEntry(packageDir);
      }

      if (id.source.shouldCache) {
        return cache.install(id).then(
            (pkg) => createPackageSymlink(id.name, pkg.dir, packageDir));
      } else {
        return id.source.install(id, packageDir).then((found) {
          if (found) return null;
          // TODO(nweiz): More robust error-handling.
          throw 'Package ${id.name} not found in source "${id.source.name}".';
        });
      }
    }).then((_) => id.resolved);

    _installs[id] = future;

    return future;
  }

  /// Installs all dependencies of the [root] package to its "packages"
  /// directory, respecting the [LockFile] if present. Returns a [Future] that
  /// completes when all dependencies are installed.
  Future installDependencies() {
    return new Future.sync(() {
      return resolveVersions(cache.sources, root, lockFile: loadLockFile());
    }).then(_installDependencies);
  }

  /// Installs the latest available versions of all dependencies of the [root]
  /// package to its "package" directory, writing a new [LockFile]. Returns a
  /// [Future] that completes when all dependencies are installed.
  Future updateAllDependencies() {
    return resolveVersions(cache.sources, root).then(_installDependencies);
  }

  /// Installs the latest available versions of [dependencies], while leaving
  /// other dependencies as specified by the [LockFile] if possible. Returns a
  /// [Future] that completes when all dependencies are installed.
  Future updateDependencies(List<String> dependencies) {
    return new Future.sync(() {
      return resolveVersions(cache.sources, root,
          lockFile: loadLockFile(), useLatest: dependencies);
    }).then(_installDependencies);
  }

  /// Removes the old packages directory, installs all dependencies listed in
  /// [result], and writes a [LockFile].
  Future _installDependencies(SolveResult result) {
    return new Future.sync(() {
      if (!result.succeeded) throw result.error;

      cleanDir(packagesDir);
      return Future.wait(result.packages.map((id) {
        if (id.isRoot) return new Future.value(id);
        return install(id);
      }).toList());
    }).then((ids) {
      _saveLockFile(ids);
      _installSelfReference();
      _linkSecondaryPackageDirs();
    });
  }

  /// Traverses the root's package dependency graph and loads each of the
  /// reached packages. This should only be called after the lockfile has been
  /// successfully generated.
  Future<List<Pubspec>> walkDependencies() {
    return new Future.sync(() {
      var lockFile = loadLockFile();
      var group = new FutureGroup<Pubspec>();
      var visited = new Set<String>();

      // Include the root package in the results.
      group.add(new Future.value(root.pubspec));

      visitPackage(Pubspec pubspec) {
        for (var ref in pubspec.dependencies) {
          if (visited.contains(ref.name)) continue;

          // Look up the concrete version.
          var id = lockFile.packages[ref.name];

          visited.add(ref.name);
          var future;
          if (ref.name == root.name) {
            future = new Future<Pubspec>.value(root.pubspec);
          } else {
            future = cache.describe(id);
          }
          group.add(future.then(visitPackage));
        }

        return pubspec;
      }

      visited.add(root.name);
      visitPackage(root.pubspec);
      return group.future;
    });
  }

  /// Validates that the current Dart SDK version matches the SDK constraints
  /// of every package in the dependency graph. If a package's constraint does
  /// not match, prints an error.
  Future validateSdkConstraints() {
    return walkDependencies().then((pubspecs) {
      var errors = [];

      for (var pubspec in pubspecs) {
        var sdkConstraint = pubspec.environment.sdkVersion;
        if (!sdkConstraint.allows(sdk.version)) {
          errors.add("- '${pubspec.name}' requires ${sdkConstraint}");
        }
      }

      if (errors.length > 0) {
        log.error("Some packages that were installed are not compatible with "
                "your SDK version ${sdk.version} and may not work:\n"
            "${errors.join('\n')}\n\n"
            "You may be able to resolve this by upgrading to the latest Dart "
                "SDK\n"
            "or adding a version constraint to use an older version of a "
                "package.");
      }
    });
  }

  /// Loads the list of concrete package versions from the `pubspec.lock`, if it
  /// exists. If it doesn't, this completes to an empty [LockFile].
  LockFile loadLockFile() {
    var lockFilePath = path.join(root.dir, 'pubspec.lock');
    if (!entryExists(lockFilePath)) return new LockFile.empty();
    return new LockFile.load(lockFilePath, cache.sources);
  }

  /// Saves a list of concrete package versions to the `pubspec.lock` file.
  void _saveLockFile(List<PackageId> packageIds) {
    var lockFile = new LockFile.empty();
    for (var id in packageIds) {
      if (!id.isRoot) lockFile.packages[id.name] = id;
    }

    var lockFilePath = path.join(root.dir, 'pubspec.lock');
    writeTextFile(lockFilePath, lockFile.serialize());
  }

  /// Installs a self-referential symlink in the `packages` directory that will
  /// allow a package to import its own files using `package:`.
  void _installSelfReference() {
    var linkPath = path.join(packagesDir, root.name);
    // Create the symlink if it doesn't exist.
    if (entryExists(linkPath)) return;
    ensureDir(packagesDir);
    createPackageSymlink(root.name, root.dir, linkPath,
        isSelfLink: true, relative: true);
  }

  /// If `bin/`, `test/`, or `example/` directories exist, symlink `packages/`
  /// into them so that their entrypoints can be run. Do the same for any
  /// subdirectories of `test/` and `example/`.
  void _linkSecondaryPackageDirs() {
    var binDir = path.join(root.dir, 'bin');
    var exampleDir = path.join(root.dir, 'example');
    var testDir = path.join(root.dir, 'test');
    var toolDir = path.join(root.dir, 'tool');
    var webDir = path.join(root.dir, 'web');

    if (dirExists(binDir)) _linkSecondaryPackageDir(binDir);
    for (var dir in ['example', 'test', 'tool', 'web']) {
      _linkSecondaryPackageDirsRecursively(path.join(root.dir, dir));
    }
 }

  /// Creates a symlink to the `packages` directory in [dir] and all its
  /// subdirectories.
  void _linkSecondaryPackageDirsRecursively(String dir) {
    if (!dirExists(dir)) return;
    _linkSecondaryPackageDir(dir);
    _listDirWithoutPackages(dir)
        .where(dirExists)
        .forEach(_linkSecondaryPackageDir);
  }

  // TODO(nweiz): roll this into [listDir] in io.dart once issue 4775 is fixed.
  /// Recursively lists the contents of [dir], excluding hidden `.DS_Store`
  /// files and `package` files.
  List<String> _listDirWithoutPackages(dir) {
    return flatten(listDir(dir).map((file) {
      if (path.basename(file) == 'packages') return [];
      if (!dirExists(file)) return [];
      var fileAndSubfiles = [file];
      fileAndSubfiles.addAll(_listDirWithoutPackages(file));
      return fileAndSubfiles;
    }));
  }

  /// Creates a symlink to the `packages` directory in [dir]. Will replace one
  /// if already there.
  void _linkSecondaryPackageDir(String dir) {
    var symlink = path.join(dir, 'packages');
    if (entryExists(symlink)) deleteEntry(symlink);
    createSymlink(packagesDir, symlink, relative: true);
  }
}
