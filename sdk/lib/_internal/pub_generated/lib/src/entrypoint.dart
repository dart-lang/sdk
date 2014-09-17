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
class Entrypoint {
  final Package root;
  final SystemCache cache;
  final bool _packageSymlinks;
  LockFile _lockFile;
  PackageGraph _packageGraph;
  Entrypoint(String rootDir, SystemCache cache, {bool packageSymlinks: true})
      : root = new Package.load(null, rootDir, cache.sources),
        cache = cache,
        _packageSymlinks = packageSymlinks;
  Entrypoint.inMemory(this.root, this._lockFile, this.cache)
      : _packageSymlinks = false;
  String get packagesDir => path.join(root.dir, 'packages');
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
  String get pubspecPath => path.join(root.dir, 'pubspec.yaml');
  String get lockFilePath => path.join(root.dir, 'pubspec.lock');
  Future acquireDependencies(SolveType type, {List<String> useLatest,
      bool dryRun: false}) {
    return syncFuture(() {
      return resolveVersions(
          type,
          cache.sources,
          root,
          lockFile: lockFile,
          useLatest: useLatest);
    }).then((result) {
      if (!result.succeeded) throw result.error;
      result.showReport(type);
      if (dryRun) {
        result.summarizeChanges(type, dryRun: dryRun);
        return null;
      }
      if (_packageSymlinks) {
        cleanDir(packagesDir);
      } else {
        deleteEntry(packagesDir);
      }
      return Future.wait(result.packages.map(_get)).then((ids) {
        _saveLockFile(ids);
        if (_packageSymlinks) _linkSelf();
        _linkOrDeleteSecondaryPackageDirs();
        result.summarizeChanges(type, dryRun: dryRun);
        return loadPackageGraph(result);
      }).then((packageGraph) {
        packageGraph.loadTransformerCache().clearIfOutdated(
            result.changedPackages);
        return precompileExecutables(
            changed: result.changedPackages).catchError((error, stackTrace) {
          log.exception(error, stackTrace);
        });
      });
    });
  }
  Future precompileExecutables({Iterable<String> changed}) {
    if (changed != null) changed = changed.toSet();
    var binDir = path.join('.pub', 'bin');
    var sdkVersionPath = path.join(binDir, 'sdk-version');
    var sdkMatches =
        fileExists(sdkVersionPath) &&
        readTextFile(sdkVersionPath) == "${sdk.version}\n";
    if (!sdkMatches) changed = null;
    return loadPackageGraph().then((graph) {
      var executables = new Map.fromIterable(
          root.immediateDependencies,
          key: (dep) => dep.name,
          value: (dep) => _executablesForPackage(graph, dep.name, changed));
      for (var package in executables.keys.toList()) {
        if (executables[package].isEmpty) executables.remove(package);
      }
      if (!sdkMatches) deleteEntry(binDir);
      if (executables.isEmpty) return null;
      return log.progress("Precompiling executables", () {
        ensureDir(binDir);
        writeTextFile(sdkVersionPath, "${sdk.version}\n");
        var packagesToLoad = unionAll(
            executables.keys.map(
                graph.transitiveDependencies)).map((package) => package.name).toSet();
        return AssetEnvironment.create(
            this,
            BarbackMode.RELEASE,
            packages: packagesToLoad,
            useDart2JS: false).then((environment) {
          environment.barback.errors.listen((error) {
            log.error(log.red("Build error:\n$error"));
          });
          return waitAndPrintErrors(executables.keys.map((package) {
            var dir = path.join(binDir, package);
            cleanDir(dir);
            return environment.precompileExecutables(
                package,
                dir,
                executableIds: executables[package]);
          }));
        });
      });
    });
  }
  List<AssetId> _executablesForPackage(PackageGraph graph, String packageName,
      Set<String> changed) {
    var package = graph.packages[packageName];
    var binDir = path.join(package.dir, 'bin');
    if (!dirExists(binDir)) return [];
    var deps = graph.transitiveDependencies(packageName);
    var hasUncachedDependency = deps.any((package) {
      var source = cache.sources[graph.lockFile.packages[package.name].source];
      return source is! CachedSource;
    });
    if (hasUncachedDependency) return [];
    var executables = package.executableIds;
    if (changed == null) return executables;
    if (deps.any((package) => changed.contains(package.name))) {
      return executables;
    }
    var executablesExist = executables.every(
        (executable) =>
            fileExists(
                path.join(
                    '.pub',
                    'bin',
                    packageName,
                    "${path.url.basename(executable.path)}.snapshot")));
    if (!executablesExist) return executables;
    return [];
  }
  Future<PackageId> _get(PackageId id) {
    if (id.isRoot) return new Future.value(id);
    var source = cache.sources[id.source];
    return syncFuture(() {
      if (!_packageSymlinks) {
        if (source is! CachedSource) return null;
        return source.downloadToSystemCache(id);
      }
      var packageDir = path.join(packagesDir, id.name);
      if (entryExists(packageDir)) deleteEntry(packageDir);
      return source.get(id, packageDir);
    }).then((_) => source.resolveId(id));
  }
  bool _isLockFileUpToDate(LockFile lockFile) {
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
  Future<bool> _arePackagesAvailable(LockFile lockFile) {
    return Future.wait(lockFile.packages.values.map((package) {
      var source = cache.sources[package.source];
      assert(source != null);
      if (source is! CachedSource) return new Future.value(true);
      return source.getDirectory(package).then((dir) {
        return dirExists(dir) || fileExists(path.join(dir, "pubspec.yaml"));
      });
    })).then((results) {
      return results.every((result) => result);
    });
  }
  Future ensureLockFileIsUpToDate() {
    return syncFuture(() {
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
      return _arePackagesAvailable(lockFile).then((available) {
        if (!available) {
          log.message(
              "You are missing some dependencies, so we need to install them " "first:");
        }
        return available;
      });
    }).then((upToDate) {
      if (upToDate) return null;
      return acquireDependencies(SolveType.GET);
    });
  }
  Future<PackageGraph> loadPackageGraph([SolveResult result]) {
    if (_packageGraph != null) return new Future.value(_packageGraph);
    return syncFuture(() {
      if (result != null) {
        return Future.wait(result.packages.map((id) {
          return cache.sources[id.source].getDirectory(
              id).then((dir) => new Package(result.pubspecs[id.name], dir));
        })).then((packages) {
          return new PackageGraph(
              this,
              new LockFile(result.packages),
              new Map.fromIterable(packages, key: (package) => package.name));
        });
      } else {
        return ensureLockFileIsUpToDate().then((_) {
          return Future.wait(lockFile.packages.values.map((id) {
            var source = cache.sources[id.source];
            return source.getDirectory(
                id).then((dir) => new Package.load(id.name, dir, cache.sources));
          })).then((packages) {
            var packageMap = new Map.fromIterable(packages, key: (p) => p.name);
            packageMap[root.name] = root;
            return new PackageGraph(this, lockFile, packageMap);
          });
        });
      }
    }).then((graph) {
      _packageGraph = graph;
      return graph;
    });
  }
  void _saveLockFile(List<PackageId> packageIds) {
    _lockFile = new LockFile(packageIds);
    var lockFilePath = path.join(root.dir, 'pubspec.lock');
    writeTextFile(lockFilePath, _lockFile.serialize(root.dir, cache.sources));
  }
  void _linkSelf() {
    var linkPath = path.join(packagesDir, root.name);
    if (entryExists(linkPath)) return;
    ensureDir(packagesDir);
    createPackageSymlink(
        root.name,
        root.dir,
        linkPath,
        isSelfLink: true,
        relative: true);
  }
  void _linkOrDeleteSecondaryPackageDirs() {
    var binDir = path.join(root.dir, 'bin');
    if (dirExists(binDir)) _linkOrDeleteSecondaryPackageDir(binDir);
    for (var dir in ['benchmark', 'example', 'test', 'tool', 'web']) {
      _linkOrDeleteSecondaryPackageDirsRecursively(path.join(root.dir, dir));
    }
  }
  void _linkOrDeleteSecondaryPackageDirsRecursively(String dir) {
    if (!dirExists(dir)) return;
    _linkOrDeleteSecondaryPackageDir(dir);
    _listDirWithoutPackages(
        dir).where(dirExists).forEach(_linkOrDeleteSecondaryPackageDir);
  }
  List<String> _listDirWithoutPackages(dir) {
    return flatten(listDir(dir).map((file) {
      if (path.basename(file) == 'packages') return [];
      if (!dirExists(file)) return [];
      var fileAndSubfiles = [file];
      fileAndSubfiles.addAll(_listDirWithoutPackages(file));
      return fileAndSubfiles;
    }));
  }
  void _linkOrDeleteSecondaryPackageDir(String dir) {
    var symlink = path.join(dir, 'packages');
    if (entryExists(symlink)) deleteEntry(symlink);
    if (_packageSymlinks) createSymlink(packagesDir, symlink, relative: true);
  }
}
