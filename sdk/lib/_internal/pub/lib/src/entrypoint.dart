// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.entrypoint;

import 'dart:async';

import 'package:path/path.dart' as path;

import 'git.dart' as git;
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
  /// well if it requires network access to retrieve (specifically, if the
  /// package's source has [shouldCache] as `true`).
  ///
  /// See also [installDependencies].
  Future<PackageId> install(PackageId id) {
    var pending = _installs[id];
    if (pending != null) return pending;

    var packageDir = path.join(packagesDir, id.name);
    var source;

    var future = new Future.sync(() {
      ensureDir(path.dirname(packageDir));

      if (entryExists(packageDir)) {
        // TODO(nweiz): figure out when to actually delete the directory, and
        // when we can just re-use the existing symlink.
        log.fine("Deleting package directory for ${id.name} before install.");
        deleteEntry(packageDir);
      }

      source = cache.sources[id.source];

      if (source.shouldCache) {
        return cache.install(id).then(
            (pkg) => createPackageSymlink(id.name, pkg.dir, packageDir));
      } else {
        return source.install(id, packageDir).then((found) {
          if (found) return null;
          fail('Package ${id.name} not found in source "${id.source}".');
        });
      }
    }).then((_) => source.resolveId(id));

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

  /// Loads the list of concrete package versions from the `pubspec.lock`, if it
  /// exists. If it doesn't, this completes to an empty [LockFile].
  LockFile loadLockFile() {
    var lockFilePath = path.join(root.dir, 'pubspec.lock');
    if (!entryExists(lockFilePath)) return new LockFile.empty();
    return new LockFile.load(lockFilePath, cache.sources);
  }

  /// Determines whether or not the lockfile is out of date with respect to the
  /// pubspec.
  ///
  /// This will be `false` if there is no lockfile at all, or if the pubspec
  /// contains dependencies that are not in the lockfile or that don't match
  /// what's in there.
  bool isLockFileUpToDate() {
    var lockFile = loadLockFile();

    checkDependency(package) {
      var locked = lockFile.packages[package.name];
      if (locked == null) return false;

      if (package.source != locked.source) return false;
      if (!package.constraint.allows(locked.version)) return false;

      var source = cache.sources[package.source];
      if (!source.descriptionsEqual(package.description, locked.description)) {
        return false;
      }

      return true;
    }

    if (!root.dependencies.every(checkDependency)) return false;
    if (!root.devDependencies.every(checkDependency)) return false;

    return true;
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

  /// Add "packages" directories to the whitelist of directories that may
  /// contain Dart entrypoints.
  void _linkSecondaryPackageDirs() {
    // Only the main "bin" directory gets a "packages" directory, not its
    // subdirectories.
    var binDir = path.join(root.dir, 'bin');
    if (dirExists(binDir)) _linkSecondaryPackageDir(binDir);

    // The others get "packages" directories in subdirectories too.
    for (var dir in ['benchmark', 'example', 'test', 'tool', 'web']) {
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

  /// The basenames of files that are automatically excluded from archives.
  final _BLACKLISTED_FILES = const ['pubspec.lock'];

  /// The basenames of directories that are automatically excluded from
  /// archives.
  final _BLACKLISTED_DIRS = const ['packages'];

  // TODO(nweiz): unit test this function.
  /// Returns a list of files that are considered to be part of this package.
  ///
  /// If this is a Git repository, this will respect .gitignore; otherwise, it
  /// will return all non-hidden, non-blacklisted files.
  ///
  /// If [beneath] is passed, this will only return files beneath that path.
  Future<List<String>> packageFiles({String beneath}) {
    if (beneath == null) beneath = root.dir;

    return git.isInstalled.then((gitInstalled) {
      if (dirExists(path.join(root.dir, '.git')) && gitInstalled) {
        // List all files that aren't gitignored, including those not checked
        // in to Git.
        return git.run(
            ["ls-files", "--cached", "--others", "--exclude-standard", beneath],
            workingDir: root.dir).then((files) {
          // Git always prints files relative to the project root, but we want
          // them relative to the working directory. It also prints forward
          // slashes on Windows which we normalize away for easier testing.
          return files.map((file) => path.normalize(path.join(root.dir, file)));
        });
      }

      return listDir(beneath, recursive: true);
    }).then((files) {
      return files.where((file) {
        // Skip directories and broken symlinks.
        if (!fileExists(file)) return false;

        var relative = path.relative(file, from: beneath);
        if (_BLACKLISTED_FILES.contains(path.basename(relative))) return false;
        return !path.split(relative).any(_BLACKLISTED_DIRS.contains);
      }).toList();
    });
  }
}
