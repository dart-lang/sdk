// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.global_packages;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:barback/barback.dart';
import 'package:pub_semver/pub_semver.dart';

import 'barback/asset_environment.dart';
import 'entrypoint.dart';
import 'exceptions.dart';
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
      {bool overwriteBinStubs}) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        var source = cache.sources["git"] as GitSource;
        source.getPackageNameFromRepo(repo).then((x0) {
          try {
            var name = x0;
            _describeActive(name);
            _installInCache(
                new PackageDep(name, "git", VersionConstraint.any, repo),
                executables,
                overwriteBinStubs: overwriteBinStubs).then((x1) {
              try {
                x1;
                completer0.complete();
              } catch (e0, s0) {
                completer0.completeError(e0, s0);
              }
            }, onError: completer0.completeError);
          } catch (e1, s1) {
            completer0.completeError(e1, s1);
          }
        }, onError: completer0.completeError);
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
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
      List<String> executables, {bool overwriteBinStubs}) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        _describeActive(name);
        _installInCache(
            new PackageDep(name, "hosted", constraint, name),
            executables,
            overwriteBinStubs: overwriteBinStubs).then((x0) {
          try {
            x0;
            completer0.complete();
          } catch (e0, s0) {
            completer0.completeError(e0, s0);
          }
        }, onError: completer0.completeError);
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
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
      {bool overwriteBinStubs}) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        var entrypoint = new Entrypoint(path, cache);
        entrypoint.ensureLockFileIsUpToDate().then((x0) {
          try {
            x0;
            var name = entrypoint.root.name;
            _describeActive(name);
            var fullPath = canonicalize(entrypoint.root.dir);
            var id = new PackageId(
                name,
                "path",
                entrypoint.root.version,
                PathSource.describePath(fullPath));
            _writeLockFile(name, new LockFile([id]));
            var binDir = p.join(_directory, name, 'bin');
            join0() {
              _updateBinStubs(
                  entrypoint.root,
                  executables,
                  overwriteBinStubs: overwriteBinStubs);
              completer0.complete();
            }
            if (dirExists(binDir)) {
              deleteEntry(binDir);
              join0();
            } else {
              join0();
            }
          } catch (e0, s0) {
            completer0.completeError(e0, s0);
          }
        }, onError: completer0.completeError);
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }

  /// Installs the package [dep] and its dependencies into the system cache.
  Future _installInCache(PackageDep dep, List<String> executables,
      {bool overwriteBinStubs}) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        var source = cache.sources[dep.source];
        var root = new Package.inMemory(
            new Pubspec(
                "pub global activate",
                dependencies: [dep],
                sources: cache.sources));
        resolveVersions(SolveType.GET, cache.sources, root).then((x0) {
          try {
            var result = x0;
            join0() {
              result.showReport(SolveType.GET);
              Future.wait(result.packages.map(_cacheDependency)).then((x1) {
                try {
                  var ids = x1;
                  var lockFile = new LockFile(ids);
                  new Entrypoint.inMemory(
                      root,
                      lockFile,
                      cache).loadPackageGraph(result).then((x2) {
                    try {
                      var graph = x2;
                      _precompileExecutables(
                          graph.entrypoint,
                          dep.name).then((x3) {
                        try {
                          var snapshots = x3;
                          _writeLockFile(dep.name, lockFile);
                          _updateBinStubs(
                              graph.packages[dep.name],
                              executables,
                              overwriteBinStubs: overwriteBinStubs,
                              snapshots: snapshots);
                          completer0.complete();
                        } catch (e0, s0) {
                          completer0.completeError(e0, s0);
                        }
                      }, onError: completer0.completeError);
                    } catch (e1, s1) {
                      completer0.completeError(e1, s1);
                    }
                  }, onError: completer0.completeError);
                } catch (e2, s2) {
                  completer0.completeError(e2, s2);
                }
              }, onError: completer0.completeError);
            }
            if (!result.succeeded) {
              join1() {
                join2() {
                  throw result.error;
                  join0();
                }
                if (result.error is NoVersionException) {
                  dataError(result.error.message);
                  join2();
                } else {
                  join2();
                }
              }
              if (result.error.package != dep.name) {
                throw result.error;
                join1();
              } else {
                join1();
              }
            } else {
              join0();
            }
          } catch (e3, s3) {
            completer0.completeError(e3, s3);
          }
        }, onError: completer0.completeError);
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }

  /// Precompiles the executables for [package] and saves them in the global
  /// cache.
  ///
  /// Returns a map from executable name to path for the snapshots that were
  /// successfully precompiled.
  Future<Map<String, String>> _precompileExecutables(Entrypoint entrypoint,
      String package) {
    return log.progress("Precompiling executables", () {
      final completer0 = new Completer();
      scheduleMicrotask(() {
        try {
          var binDir = p.join(_directory, package, 'bin');
          cleanDir(binDir);
          entrypoint.loadPackageGraph().then((x0) {
            try {
              var graph = x0;
              AssetEnvironment.create(
                  entrypoint,
                  BarbackMode.RELEASE,
                  entrypoints: graph.packages[package].executableIds,
                  useDart2JS: false).then((x1) {
                try {
                  var environment = x1;
                  environment.barback.errors.listen(((error) {
                    log.error(log.red("Build error:\n$error"));
                  }));
                  completer0.complete(
                      environment.precompileExecutables(package, binDir));
                } catch (e0, s0) {
                  completer0.completeError(e0, s0);
                }
              }, onError: completer0.completeError);
            } catch (e1, s1) {
              completer0.completeError(e1, s1);
            }
          }, onError: completer0.completeError);
        } catch (e, s) {
          completer0.completeError(e, s);
        }
      });
      return completer0.future;
    });
  }

  /// Downloads [id] into the system cache if it's a cached package.
  ///
  /// Returns the resolved [PackageId] for [id].
  Future<PackageId> _cacheDependency(PackageId id) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        var source = cache.sources[id.source];
        join0() {
          completer0.complete(source.resolveId(id));
        }
        if (!id.isRoot && source is CachedSource) {
          source.downloadToSystemCache(id).then((x0) {
            try {
              x0;
              join0();
            } catch (e0, s0) {
              completer0.completeError(e0, s0);
            }
          }, onError: completer0.completeError);
        } else {
          join0();
        }
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }

  /// Finishes activating package [package] by saving [lockFile] in the cache.
  void _writeLockFile(String package, LockFile lockFile) {
    ensureDir(p.join(_directory, package));

    // TODO(nweiz): This cleans up Dart 1.6's old lockfile location. Remove it
    // when Dart 1.6 is old enough that we don't think anyone will have these
    // lockfiles anymore (issue 20703).
    var oldPath = p.join(_directory, "$package.lock");
    if (fileExists(oldPath)) deleteEntry(oldPath);

    writeTextFile(
        _getLockFilePath(package),
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
        log.message(
            'Package ${log.bold(name)} is currently active from Git '
                'repository "${url}".');
      } else if (id.source == 'path') {
        var path = PathSource.pathFromDescription(id.description);
        log.message(
            'Package ${log.bold(name)} is currently active at path ' '"$path".');
      } else {
        log.message(
            'Package ${log.bold(name)} is currently active at version '
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
        return cache.sources[id.source].getDirectory(
            id).then((dir) => new Package.load(name, dir, cache.sources)).then((package) {
          return new Entrypoint.inMemory(package, lockFile, cache);
        });
      }

      // For uncached sources (i.e. path), the ID just points to the real
      // directory for the package.
      assert(id.source == "path");
      return new Entrypoint(
          PathSource.pathFromDescription(id.description),
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
        return exe.runExecutable(
            entrypoint,
            package,
            executable,
            args,
            mode: mode,
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
      log.fine(
          "$package:$executable is out of date and needs to be " "recompiled.");
      return find(
          package).then(
              (entrypoint) =>
                  entrypoint.loadPackageGraph()).then(
                      (graph) => _precompileExecutables(graph.entrypoint, package));
    });
  }

  /// Gets the path to the lock file for an activated cached package with
  /// [name].
  String _getLockFilePath(String name) =>
      p.join(_directory, name, "pubspec.lock");

  /// Shows the user a formatted list of globally activated packages.
  void listActivePackages() {
    if (!dirExists(_directory)) return;

    listDir(_directory).map(_loadPackageId).toList()
        ..sort((id1, id2) => id1.name.compareTo(id2.name))
        ..forEach((id) => log.message(_formatPackage(id)));
  }

  /// Returns the [PackageId] for the globally-activated package at [path].
  ///
  /// [path] should be a path within [_directory]. It can either be an old-style
  /// path to a single lockfile or a new-style path to a directory containing a
  /// lockfile.
  PackageId _loadPackageId(String path) {
    var name = p.basenameWithoutExtension(path);
    if (!fileExists(path)) path = p.join(path, 'pubspec.lock');

    var id =
        new LockFile.load(p.join(_directory, path), cache.sources).packages[name];

    if (id == null) {
      throw new FormatException(
          "Pubspec for activated package $name didn't " "contain an entry for itself.");
    }

    return id;
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

  /// Repairs any corrupted globally-activated packages and their binstubs.
  ///
  /// Returns a pair of two [int]s. The first indicates how many packages were
  /// successfully re-activated; the second indicates how many failed.
  Future<Pair<int, int>> repairActivatedPackages() {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        var executables = {};
        join0() {
          var successes = 0;
          var failures = 0;
          join1() {
            join2() {
              completer0.complete(new Pair(successes, failures));
            }
            if (executables.isNotEmpty) {
              var packages = pluralize("package", executables.length);
              var message =
                  new StringBuffer("Binstubs exist for non-activated " "packages:\n");
              executables.forEach(((package, executableNames) {
                executableNames.forEach(
                    (executable) => deleteEntry(p.join(_binStubDir, executable)));
                message.writeln(
                    "  From ${log.bold(package)}: " "${toSentence(executableNames)}");
              }));
              log.error(message);
              join2();
            } else {
              join2();
            }
          }
          if (dirExists(_directory)) {
            var it0 = listDir(_directory).iterator;
            break0() {
              join1();
            }
            var trampoline0;
            continue0() {
              trampoline0 = null;
              if (it0.moveNext()) {
                var entry = it0.current;
                var id;
                join3() {
                  trampoline0 = continue0;
                }
                catch0(error, stackTrace) {
                  try {
                    var message =
                        "Failed to reactivate " "${log.bold(p.basenameWithoutExtension(entry))}";
                    join4() {
                      log.error(message, error, stackTrace);
                      failures++;
                      tryDeleteEntry(entry);
                      join3();
                    }
                    if (id != null) {
                      message += " ${id.version}";
                      join5() {
                        join4();
                      }
                      if (id.source != "hosted") {
                        message += " from ${id.source}";
                        join5();
                      } else {
                        join5();
                      }
                    } else {
                      join4();
                    }
                  } catch (error, stackTrace) {
                    completer0.completeError(error, stackTrace);
                  }
                }
                try {
                  id = _loadPackageId(entry);
                  log.message(
                      "Reactivating ${log.bold(id.name)} ${id.version}...");
                  find(id.name).then((x0) {
                    trampoline0 = () {
                      trampoline0 = null;
                      try {
                        var entrypoint = x0;
                        entrypoint.loadPackageGraph().then((x1) {
                          trampoline0 = () {
                            trampoline0 = null;
                            try {
                              var graph = x1;
                              _precompileExecutables(
                                  entrypoint,
                                  id.name).then((x2) {
                                trampoline0 = () {
                                  trampoline0 = null;
                                  try {
                                    var snapshots = x2;
                                    var packageExecutables =
                                        executables.remove(id.name);
                                    join6() {
                                      _updateBinStubs(
                                          graph.packages[id.name],
                                          packageExecutables,
                                          overwriteBinStubs: true,
                                          snapshots: snapshots,
                                          suggestIfNotOnPath: false);
                                      successes++;
                                      join3();
                                    }
                                    if (packageExecutables == null) {
                                      packageExecutables = [];
                                      join6();
                                    } else {
                                      join6();
                                    }
                                  } catch (e0, s0) {
                                    catch0(e0, s0);
                                  }
                                };
                                do trampoline0(); while (trampoline0 != null);
                              }, onError: catch0);
                            } catch (e1, s1) {
                              catch0(e1, s1);
                            }
                          };
                          do trampoline0(); while (trampoline0 != null);
                        }, onError: catch0);
                      } catch (e2, s2) {
                        catch0(e2, s2);
                      }
                    };
                    do trampoline0(); while (trampoline0 != null);
                  }, onError: catch0);
                } catch (e3, s3) {
                  catch0(e3, s3);
                }
              } else {
                break0();
              }
            }
            trampoline0 = continue0;
            do trampoline0(); while (trampoline0 != null);
          } else {
            join1();
          }
        }
        if (dirExists(_binStubDir)) {
          var it1 = listDir(_binStubDir).iterator;
          break1() {
            join0();
          }
          var trampoline1;
          continue1() {
            trampoline1 = null;
            if (it1.moveNext()) {
              var entry = it1.current;
              join7() {
                trampoline1 = continue1;
              }
              catch1(error, stackTrace) {
                try {
                  log.error(
                      "Error reading binstub for " "\"${p.basenameWithoutExtension(entry)}\"",
                      error,
                      stackTrace);
                  tryDeleteEntry(entry);
                  join7();
                } catch (error, stackTrace) {
                  completer0.completeError(error, stackTrace);
                }
              }
              try {
                var binstub = readTextFile(entry);
                var package = _binStubProperty(binstub, "Package");
                join8() {
                  var executable = _binStubProperty(binstub, "Executable");
                  join9() {
                    executables.putIfAbsent(package, (() {
                      return [];
                    })).add(executable);
                    join7();
                  }
                  if (executable == null) {
                    throw new ApplicationException("No 'Executable' property.");
                    join9();
                  } else {
                    join9();
                  }
                }
                if (package == null) {
                  throw new ApplicationException("No 'Package' property.");
                  join8();
                } else {
                  join8();
                }
              } catch (e4, s4) {
                catch1(e4, s4);
              }
            } else {
              break1();
            }
          }
          trampoline1 = continue1;
          do trampoline1(); while (trampoline1 != null);
        } else {
          join0();
        }
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
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
  /// snapshots were precompiled to the paths of those snapshots. Binstubs for
  /// those will run the snapshot directly and skip pub entirely.
  ///

      /// If [suggestIfNotOnPath] is `true` (the default), this will warn the user if
  /// the bin directory isn't on their path.
  void _updateBinStubs(Package package, List<String> executables,
      {bool overwriteBinStubs, Map<String, String> snapshots, bool suggestIfNotOnPath:
      true}) {
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

      var previousPackage = _createBinStub(
          package,
          executable,
          script,
          overwrite: overwriteBinStubs,
          snapshot: snapshots[script]);
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
          log.warning(
              "Replaced ${log.bold(command)} previously installed from "
                  "${log.bold(collided[command])}.");
        } else {
          log.warning(
              "Executable ${log.bold(command)} was already installed "
                  "from ${log.bold(collided[command])}.");
        }
      }

      if (!overwriteBinStubs) {
        log.warning(
            "Deactivate the other package(s) or activate "
                "${log.bold(package.name)} using --overwrite.");
      }
    }

    // Show errors for any unknown executables.
    if (executables != null) {
      var unknown = ordered(
          executables.where((exe) => !package.pubspec.executables.keys.contains(exe)));
      if (unknown.isNotEmpty) {
        dataError("Unknown ${namedSequence('executable', unknown)}.");
      }
    }

    // Show errors for any missing scripts.
    // TODO(rnystrom): This can print false positives since a script may be
    // produced by a transformer. Do something better.
    var binFiles = package.listFiles(
        beneath: "bin",
        recursive: false).map((path) => package.relative(path)).toList();
    for (var executable in installed) {
      var script = package.pubspec.executables[executable];
      var scriptPath = p.join("bin", "$script.dart");
      if (!binFiles.contains(scriptPath)) {
        log.warning(
            'Warning: Executable "$executable" runs "$scriptPath", '
                'which was not found in ${log.bold(package.name)}.');
      }
    }

    if (suggestIfNotOnPath && installed.isNotEmpty) {
      _suggestIfNotOnPath(installed.first);
    }
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

    if (Platform.operatingSystem == "windows") binStubPath += ".bat";

    // See if the binstub already exists. If so, it's for another package
    // since we already deleted all of this package's binstubs.
    var previousPackage;
    if (fileExists(binStubPath)) {
      var contents = readTextFile(binStubPath);
      previousPackage = _binStubProperty(contents, "Package");
      if (previousPackage == null) {
        log.fine("Could not parse binstub $binStubPath:\n$contents");
      } else if (!overwrite) {
        return previousPackage;
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
$invocation %*
""";

      if (snapshot != null) {
        batch += """

rem The VM exits with code 255 if the snapshot version is out-of-date.
rem If it is, we need to delete it and run "pub global" manually.
if not errorlevel 255 (
  exit /b %errorlevel%
)

pub global run ${package.name}:$script %*
""";
      }

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

      if (snapshot != null) {
        bash += """

# The VM exits with code 255 if the snapshot version is out-of-date.
# If it is, we need to delete it and run "pub global" manually.
exit_code=\$?
if [ \$exit_code != 255 ]; then
  exit \$exit_code
fi

pub global run ${package.name}:$script "\$@"
""";
      }

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

        fail(
            'Could not make "$binStubPath" executable (exit code '
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
      var binStubPackage = _binStubProperty(contents, "Package");
      if (binStubPackage == null) {
        log.fine("Could not parse binstub $file:\n$contents");
        continue;
      }

      if (binStubPackage == package) {
        log.fine("Deleting old binstub $file");
        deleteEntry(file);
      }
    }
  }

  /// Checks to see if the binstubs are on the user's PATH and, if not, suggests
  /// that the user add the directory to their PATH.
  ///
  /// [installed] should be the name of an installed executable that can be used
  /// to test whether accessing it on the path works.
  void _suggestIfNotOnPath(String installed) {
    if (Platform.operatingSystem == "windows") {
      // See if the shell can find one of the binstubs.
      // "\q" means return exit code 0 if found or 1 if not.
      var result = runProcessSync("where", [r"\q", installed + ".bat"]);
      if (result.exitCode == 0) return;

      log.warning(
          "${log.yellow('Warning:')} Pub installs executables into "
              "${log.bold(_binStubDir)}, which is not on your path.\n"
              "You can fix that by adding that directory to your system's "
              '"Path" environment variable.\n'
              'A web search for "configure windows path" will show you how.');
    } else {
      // See if the shell can find one of the binstubs.
      var result = runProcessSync("which", [installed]);
      if (result.exitCode == 0) return;

      var binDir = _binStubDir;
      if (binDir.startsWith(Platform.environment['HOME'])) {
        binDir =
            p.join("~", p.relative(binDir, from: Platform.environment['HOME']));
      }

      log.warning(
          "${log.yellow('Warning:')} Pub installs executables into "
              "${log.bold(binDir)}, which is not on your path.\n"
              "You can fix that by adding this to your shell's config file "
              "(.bashrc, .bash_profile, etc.):\n" "\n"
              "  ${log.bold('export PATH="\$PATH":"$binDir"')}\n" "\n");
    }
  }

  /// Returns the value of the property named [name] in the bin stub script
  /// [source].
  String _binStubProperty(String source, String name) {
    var pattern = new RegExp(quoteRegExp(name) + r": ([a-zA-Z0-9_-]+)");
    var match = pattern.firstMatch(source);
    return match == null ? null : match[1];
  }
}
