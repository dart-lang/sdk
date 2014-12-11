// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.entrypoint;

import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:barback/barback.dart';

import 'barback/asset_environment.dart';
import 'io.dart';
import 'lock_file.dart';
import 'log.dart' as log;
import 'package.dart';
import 'package_graph.dart';
import 'sdk.dart' as sdk;
import 'solver/version_solver.dart';
import 'source/cached.dart';
import 'system_cache.dart';
import 'utils.dart';

/// The context surrounding the root package pub is operating on.
///
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

  /// Whether to create and symlink a "packages" directory containing links to
  /// the installed packages.
  final bool _packageSymlinks;

  /// The lockfile for the entrypoint.
  ///
  /// If not provided to the entrypoint, it will be laoded lazily from disc.
  LockFile _lockFile;

  /// The graph of all packages reachable from the entrypoint.
  PackageGraph _packageGraph;

  /// Loads the entrypoint from a package at [rootDir].
  ///
  /// If [packageSymlinks] is `true`, this will create a "packages" directory
  /// with symlinks to the installed packages. This directory will be symlinked
  /// into any directory that might contain an entrypoint.
  Entrypoint(String rootDir, SystemCache cache, {bool packageSymlinks: true})
      : root = new Package.load(null, rootDir, cache.sources),
        cache = cache,
        _packageSymlinks = packageSymlinks;

  /// Creates an entrypoint given package and lockfile objects.
  Entrypoint.inMemory(this.root, this._lockFile, this.cache)
      : _packageSymlinks = false;

  /// The path to the entrypoint's "packages" directory.
  String get packagesDir => root.path('packages');

  /// `true` if the entrypoint package currently has a lock file.
  bool get lockFileExists => _lockFile != null || entryExists(lockFilePath);

  LockFile get lockFile {
    if (_lockFile != null) return _lockFile;

    if (!lockFileExists) {
      _lockFile = new LockFile.empty();
    } else {
      _lockFile = new LockFile.load(lockFilePath, cache.sources);
    }

    return _lockFile;
  }

  /// The path to the entrypoint package's pubspec.
  String get pubspecPath => root.path('pubspec.yaml');

  /// The path to the entrypoint package's lockfile.
  String get lockFilePath => root.path('pubspec.lock');

  /// Gets all dependencies of the [root] package.
  ///
  /// Performs version resolution according to [SolveType].
  ///
  /// [useLatest], if provided, defines a list of packages that will be
  /// unlocked and forced to their latest versions. If [upgradeAll] is
  /// true, the previous lockfile is ignored and all packages are re-resolved
  /// from scratch. Otherwise, it will attempt to preserve the versions of all
  /// previously locked packages.
  ///
  /// Shows a report of the changes made relative to the previous lockfile. If
  /// this is an upgrade or downgrade, all transitive dependencies are shown in
  /// the report. Otherwise, only dependencies that were changed are shown. If
  /// [dryRun] is `true`, no physical changes are made.
  Future acquireDependencies(SolveType type, {List<String> useLatest,
      bool dryRun: false}) async {
    var result = await resolveVersions(type, cache.sources, root,
        lockFile: lockFile, useLatest: useLatest);
    if (!result.succeeded) throw result.error;

    result.showReport(type);

    if (dryRun) {
      result.summarizeChanges(type, dryRun: dryRun);
      return;
    }

    // Install the packages and maybe link them into the entrypoint.
    if (_packageSymlinks) {
      cleanDir(packagesDir);
    } else {
      deleteEntry(packagesDir);
    }

    var ids = await Future.wait(result.packages.map(_get));
    _saveLockFile(ids);

    if (_packageSymlinks) _linkSelf();
    _linkOrDeleteSecondaryPackageDirs();

    result.summarizeChanges(type, dryRun: dryRun);

    /// Build a package graph from the version solver results so we don't
    /// have to reload and reparse all the pubspecs.
    var packageGraph = await loadPackageGraph(result);
    packageGraph.loadTransformerCache().clearIfOutdated(result.changedPackages);

    // TODO(nweiz): Use await here when
    // https://github.com/dart-lang/async_await/issues/51 is fixed.
    return precompileDependencies(changed: result.changedPackages).then((_) {
      return precompileExecutables(changed: result.changedPackages);
    }).catchError((error, stackTrace) {
      // Just log exceptions here. Since the method is just about acquiring
      // dependencies, it shouldn't fail unless that fails.
      log.exception(error, stackTrace);
    });
  }

  /// Precompile any transformed dependencies of the entrypoint.
  ///
  /// If [changed] is passed, only dependencies whose contents might be changed
  /// if one of the given packages changes will be recompiled.
  Future precompileDependencies({Iterable<String> changed}) async {
    if (changed != null) changed = changed.toSet();

    var graph = await loadPackageGraph();

    // Just precompile the debug version of a package. We're mostly interested
    // in improving speed for development iteration loops, which usually use
    // debug mode.
    var depsDir = path.join('.pub', 'deps', 'debug');

    var dependenciesToPrecompile = graph.packages.values.where((package) {
      if (package.pubspec.transformers.isEmpty) return false;
      if (graph.isPackageMutable(package.name)) return false;
      if (!dirExists(path.join(depsDir, package.name))) return true;
      if (changed == null) return true;

      /// Only recompile [package] if any of its transitive dependencies have
      /// changed. We check all transitive dependencies because it's possible
      /// that a transformer makes decisions based on their contents.
      return overlaps(
          graph.transitiveDependencies(package.name)
            .map((package) => package.name).toSet(),
          changed);
    }).map((package) => package.name).toSet();

    if (dirExists(depsDir)) {
      // Delete any cached dependencies that are going to be recached.
      for (var package in dependenciesToPrecompile) {
        deleteEntry(path.join(depsDir, package));
      }

      // Also delete any cached dependencies that should no longer be cached.
      for (var subdir in listDir(depsDir)) {
        var package = graph.packages[path.basename(subdir)];
        if (package == null || package.pubspec.transformers.isEmpty ||
            graph.isPackageMutable(package.name)) {
          deleteEntry(subdir);
        }
      }
    }

    if (dependenciesToPrecompile.isEmpty) return;

    await log.progress("Precompiling dependencies", () async {
      var packagesToLoad =
          unionAll(dependenciesToPrecompile.map(graph.transitiveDependencies))
          .map((package) => package.name).toSet();

      var environment = await AssetEnvironment.create(this, BarbackMode.DEBUG,
          packages: packagesToLoad, useDart2JS: false);

      /// Ignore barback errors since they'll be emitted via [getAllAssets]
      /// below.
      environment.barback.errors.listen((_) {});

      // TODO(nweiz): only get assets from [dependenciesToPrecompile] so as not
      // to trigger unnecessary lazy transformers.
      var assets = await environment.barback.getAllAssets();
      await waitAndPrintErrors(assets.map((asset) async {
        if (!dependenciesToPrecompile.contains(asset.id.package)) return;

        var destPath = path.join(
            depsDir, asset.id.package, path.fromUri(asset.id.path));
        ensureDir(path.dirname(destPath));
        await createFileFromStream(asset.read(), destPath);
      }));

      log.message("Precompiled " +
          toSentence(ordered(dependenciesToPrecompile).map(log.bold)) + ".");
    }).catchError((error) {
      // TODO(nweiz): Do this in a catch clause when async_await supports
      // "rethrow" (https://github.com/dart-lang/async_await/issues/46).
      // TODO(nweiz): When barback does a better job of associating errors with
      // assets (issue 19491), catch and handle compilation errors on a
      // per-package basis.
      dependenciesToPrecompile.forEach((package) =>
          deleteEntry(path.join(depsDir, package)));
      throw error;
    });
  }

  /// Precompiles all executables from dependencies that don't transitively
  /// depend on [this] or on a path dependency.
  Future precompileExecutables({Iterable<String> changed}) async {
    if (changed != null) changed = changed.toSet();

    var binDir = path.join('.pub', 'bin');
    var sdkVersionPath = path.join(binDir, 'sdk-version');

    // If the existing executable was compiled with a different SDK, we need to
    // recompile regardless of what changed.
    // TODO(nweiz): Use the VM to check this when issue 20802 is fixed.
    var sdkMatches = fileExists(sdkVersionPath) &&
        readTextFile(sdkVersionPath) == "${sdk.version}\n";
    if (!sdkMatches) changed = null;

    var graph = await loadPackageGraph();
    var executables = new Map.fromIterable(root.immediateDependencies,
        key: (dep) => dep.name,
        value: (dep) => _executablesForPackage(graph, dep.name, changed));

    for (var package in executables.keys.toList()) {
      if (executables[package].isEmpty) executables.remove(package);
    }

    if (!sdkMatches) deleteEntry(binDir);
    if (executables.isEmpty) return;

    await log.progress("Precompiling executables", () async {
      ensureDir(binDir);

      // Make sure there's a trailing newline so our version file matches the
      // SDK's.
      writeTextFile(sdkVersionPath, "${sdk.version}\n");

      var packagesToLoad =
          unionAll(executables.keys.map(graph.transitiveDependencies))
          .map((package) => package.name).toSet();
      var executableIds = unionAll(
          executables.values.map((ids) => ids.toSet()));
      var environment = await AssetEnvironment.create(this, BarbackMode.RELEASE,
          packages: packagesToLoad,
          entrypoints: executableIds,
          useDart2JS: false);
      environment.barback.errors.listen((error) {
        log.error(log.red("Build error:\n$error"));
      });

      await waitAndPrintErrors(executables.keys.map((package) async {
        var dir = path.join(binDir, package);
        cleanDir(dir);
        await environment.precompileExecutables(package, dir,
            executableIds: executables[package]);
      }));
    });
  }

  /// Returns the list of all executable assets for [packageName] that should be
  /// precompiled.
  ///
  /// If [changed] isn't `null`, executables for [packageName] will only be
  /// compiled if they might depend on a package in [changed].
  List<AssetId> _executablesForPackage(PackageGraph graph, String packageName,
      Set<String> changed) {
    var package = graph.packages[packageName];
    var binDir = package.path('bin');
    if (!dirExists(binDir)) return [];
    if (graph.isPackageMutable(packageName)) return [];

    var executables = package.executableIds;

    // If we don't know which packages were changed, always precompile the
    // executables.
    if (changed == null) return executables;

    // If any of the package's dependencies changed, recompile the executables.
    if (graph.transitiveDependencies(packageName)
        .any((package) => changed.contains(package.name))) {
      return executables;
    }

    // If any executables doesn't exist, precompile them regardless of what
    // changed. Since we delete the bin directory before recompiling, we need to
    // recompile all executables.
    var executablesExist = executables.every((executable) =>
        fileExists(path.join('.pub', 'bin', packageName,
            "${path.url.basename(executable.path)}.snapshot")));
    if (!executablesExist) return executables;

    // Otherwise, we don't need to recompile.
    return [];
  }

  /// Makes sure the package at [id] is locally available.
  ///
  /// This automatically downloads the package to the system-wide cache as well
  /// if it requires network access to retrieve (specifically, if the package's
  /// source is a [CachedSource]).
  Future<PackageId> _get(PackageId id) {
    if (id.isRoot) return new Future.value(id);

    var source = cache.sources[id.source];
    return new Future.sync(() {
      if (!_packageSymlinks) {
        if (source is! CachedSource) return null;
        return source.downloadToSystemCache(id);
      }

      var packageDir = path.join(packagesDir, id.name);
      if (entryExists(packageDir)) deleteEntry(packageDir);
      return source.get(id, packageDir);
    }).then((_) => source.resolveId(id));
  }

  /// Determines whether or not the lockfile is out of date with respect to the
  /// pubspec.
  ///
  /// This will be `false` if there is no lockfile at all, or if the pubspec
  /// contains dependencies that are not in the lockfile or that don't match
  /// what's in there.
  bool _isLockFileUpToDate(LockFile lockFile) {
    /// If this is an entrypoint for an in-memory package, trust the in-memory
    /// lockfile provided for it.
    if (root.dir == null) return true;

    return root.immediateDependencies.every((package) {
      var locked = lockFile.packages[package.name];
      if (locked == null) return false;

      if (package.source != locked.source) return false;
      if (!package.constraint.allows(locked.version)) return false;

      var source = cache.sources[package.source];
      if (source == null) return false;

      return source.descriptionsEqual(package.description, locked.description);
    });
  }

  /// Determines whether all of the packages in the lockfile are already
  /// installed and available.
  ///
  /// Note: this assumes [isLockFileUpToDate] has already been called and
  /// returned `true`.
  Future<bool> _arePackagesAvailable(LockFile lockFile) {
    return Future.wait(lockFile.packages.values.map((package) {
      var source = cache.sources[package.source];

      // This should only be called after [_isLockFileUpToDate] has returned
      // `true`, which ensures all of the sources in the lock file are valid.
      assert(source != null);

      // We only care about cached sources. Uncached sources aren't "installed".
      // If one of those is missing, we want to show the user the file not
      // found error later since installing won't accomplish anything.
      if (source is! CachedSource) return new Future.value(true);

      // Get the directory.
      return source.getDirectory(package).then((dir) {
        // See if the directory is there and looks like a package.
        return dirExists(dir) || fileExists(path.join(dir, "pubspec.yaml"));
      });
    })).then((results) {
      // Make sure they are all true.
      return results.every((result) => result);
    });
  }

  /// Gets dependencies if the lockfile is out of date with respect to the
  /// pubspec.
  Future ensureLockFileIsUpToDate() {
    return new Future.sync(() {
      // If we don't have a current lock file, we definitely need to install.
      if (!_isLockFileUpToDate(lockFile)) {
        if (lockFileExists) {
          log.message(
              "Your pubspec has changed, so we need to update your lockfile:");
        } else {
          log.message(
              "You don't have a lockfile, so we need to generate that:");
        }

        return false;
      }

      // If we do have a lock file, we still need to make sure the packages
      // are actually installed. The user may have just gotten a package that
      // includes a lockfile.
      return _arePackagesAvailable(lockFile).then((available) {
        if (!available) {
          log.message(
              "You are missing some dependencies, so we need to install them "
              "first:");
        }

        return available;
      });
    }).then((upToDate) {
      if (upToDate) return null;
      return acquireDependencies(SolveType.GET);
    });
  }

  /// Loads the package graph for the application and all of its transitive
  /// dependencies.
  ///
  /// If [result] is passed, this loads the graph from it without re-parsing the
  /// lockfile or any pubspecs. Otherwise, before loading, this makes sure the
  /// lockfile and dependencies are installed and up to date.
  Future<PackageGraph> loadPackageGraph([SolveResult result]) async {
    if (_packageGraph != null) return _packageGraph;

    var graph = await log.progress("Loading package graph", () async {
      if (result != null) {
        var packages = await Future.wait(result.packages.map((id) async {
          var dir = await cache.sources[id.source].getDirectory(id);
          return new Package(result.pubspecs[id.name], dir);
        }));

        return new PackageGraph(this, new LockFile(result.packages),
            new Map.fromIterable(packages, key: (package) => package.name));
      }

      await ensureLockFileIsUpToDate();
      var packages = await Future.wait(lockFile.packages.values.map((id) async {
        var source = cache.sources[id.source];
        var dir = await source.getDirectory(id);
        return new Package.load(id.name, dir, cache.sources);
      }));

      var packageMap = new Map.fromIterable(packages, key: (p) => p.name);
      packageMap[root.name] = root;
      return new PackageGraph(this, lockFile, packageMap);
    }, fine: true);

    _packageGraph = graph;
    return graph;
  }

  /// Saves a list of concrete package versions to the `pubspec.lock` file.
  void _saveLockFile(List<PackageId> packageIds) {
    _lockFile = new LockFile(packageIds);
    var lockFilePath = root.path('pubspec.lock');
    writeTextFile(lockFilePath, _lockFile.serialize(root.dir, cache.sources));
  }

  /// Creates a self-referential symlink in the `packages` directory that allows
  /// a package to import its own files using `package:`.
  void _linkSelf() {
    var linkPath = path.join(packagesDir, root.name);
    // Create the symlink if it doesn't exist.
    if (entryExists(linkPath)) return;
    ensureDir(packagesDir);
    createPackageSymlink(root.name, root.dir, linkPath,
        isSelfLink: true, relative: true);
  }

  /// If [packageSymlinks] is true, add "packages" directories to the whitelist
  /// of directories that may contain Dart entrypoints.
  ///
  /// Otherwise, delete any "packages" directories in the whitelist of
  /// directories that may contain Dart entrypoints.
  void _linkOrDeleteSecondaryPackageDirs() {
    // Only the main "bin" directory gets a "packages" directory, not its
    // subdirectories.
    var binDir = root.path('bin');
    if (dirExists(binDir)) _linkOrDeleteSecondaryPackageDir(binDir);

    // The others get "packages" directories in subdirectories too.
    for (var dir in ['benchmark', 'example', 'test', 'tool', 'web']) {
      _linkOrDeleteSecondaryPackageDirsRecursively(root.path(dir));
    }
 }

  /// If [packageSymlinks] is true, creates a symlink to the "packages"
  /// directory in [dir] and all its subdirectories.
  ///
  /// Otherwise, deletes any "packages" directories in [dir] and all its
  /// subdirectories.
  void _linkOrDeleteSecondaryPackageDirsRecursively(String dir) {
    if (!dirExists(dir)) return;
    _linkOrDeleteSecondaryPackageDir(dir);
    _listDirWithoutPackages(dir)
        .where(dirExists)
        .forEach(_linkOrDeleteSecondaryPackageDir);
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

  /// If [packageSymlinks] is true, creates a symlink to the "packages"
  /// directory in [dir].
  ///
  /// Otherwise, deletes a "packages" directories in [dir] if one exists.
  void _linkOrDeleteSecondaryPackageDir(String dir) {
    var symlink = path.join(dir, 'packages');
    if (entryExists(symlink)) deleteEntry(symlink);
    if (_packageSymlinks) createSymlink(packagesDir, symlink, relative: true);
  }
}
