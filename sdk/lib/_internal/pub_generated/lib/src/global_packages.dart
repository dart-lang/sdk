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
final _binStubPackagePattern = new RegExp(r"Package: ([a-zA-Z0-9_-]+)");
class GlobalPackages {
  final SystemCache cache;
  String get _directory => p.join(cache.rootDir, "global_packages");
  String get _binStubDir => p.join(cache.rootDir, "bin");
  GlobalPackages(this.cache);
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
                new PackageDep(name, "git", VersionConstraint.any, repo)).then((x1) {
              try {
                var package = x1;
                _updateBinStubs(
                    package,
                    executables,
                    overwriteBinStubs: overwriteBinStubs);
                completer0.complete(null);
              } catch (e1) {
                completer0.completeError(e1);
              }
            }, onError: (e2) {
              completer0.completeError(e2);
            });
          } catch (e0) {
            completer0.completeError(e0);
          }
        }, onError: (e3) {
          completer0.completeError(e3);
        });
      } catch (e4) {
        completer0.completeError(e4);
      }
    });
    return completer0.future;
  }
  Future activateHosted(String name, VersionConstraint constraint,
      List<String> executables, {bool overwriteBinStubs}) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        _describeActive(name);
        _installInCache(
            new PackageDep(name, "hosted", constraint, name)).then((x0) {
          try {
            var package = x0;
            _updateBinStubs(
                package,
                executables,
                overwriteBinStubs: overwriteBinStubs);
            completer0.complete(null);
          } catch (e0) {
            completer0.completeError(e0);
          }
        }, onError: (e1) {
          completer0.completeError(e1);
        });
      } catch (e2) {
        completer0.completeError(e2);
      }
    });
    return completer0.future;
  }
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
              completer0.complete(null);
            }
            if (dirExists(binDir)) {
              deleteEntry(binDir);
              join0();
            } else {
              join0();
            }
          } catch (e0) {
            completer0.completeError(e0);
          }
        }, onError: (e1) {
          completer0.completeError(e1);
        });
      } catch (e2) {
        completer0.completeError(e2);
      }
    });
    return completer0.future;
  }
  Future<Package> _installInCache(PackageDep dep) {
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
                          x3;
                          _writeLockFile(dep.name, lockFile);
                          completer0.complete(graph.packages[dep.name]);
                        } catch (e3) {
                          completer0.completeError(e3);
                        }
                      }, onError: (e4) {
                        completer0.completeError(e4);
                      });
                    } catch (e2) {
                      completer0.completeError(e2);
                    }
                  }, onError: (e5) {
                    completer0.completeError(e5);
                  });
                } catch (e1) {
                  completer0.completeError(e1);
                }
              }, onError: (e6) {
                completer0.completeError(e6);
              });
            }
            if (!result.succeeded) {
              join1() {
                join2() {
                  completer0.completeError(result.error);
                }
                if (result.error is NoVersionException) {
                  dataError(result.error.message);
                  join2();
                } else {
                  join2();
                }
              }
              if (result.error.package != dep.name) {
                completer0.completeError(result.error);
              } else {
                join1();
              }
            } else {
              join0();
            }
          } catch (e0) {
            completer0.completeError(e0);
          }
        }, onError: (e7) {
          completer0.completeError(e7);
        });
      } catch (e8) {
        completer0.completeError(e8);
      }
    });
    return completer0.future;
  }
  Future _precompileExecutables(Entrypoint entrypoint, String package) {
    return log.progress("Precompiling executables", () {
      var binDir = p.join(_directory, package, 'bin');
      cleanDir(binDir);
      return AssetEnvironment.create(
          entrypoint,
          BarbackMode.RELEASE,
          useDart2JS: false).then((environment) {
        environment.barback.errors.listen((error) {
          log.error(log.red("Build error:\n$error"));
        });
        return environment.precompileExecutables(package, binDir);
      });
    });
  }
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
            } catch (e0) {
              completer0.completeError(e0);
            }
          }, onError: (e1) {
            completer0.completeError(e1);
          });
        } else {
          join0();
        }
      } catch (e2) {
        completer0.completeError(e2);
      }
    });
    return completer0.future;
  }
  void _writeLockFile(String package, LockFile lockFile) {
    ensureDir(p.join(_directory, package));
    var oldPath = p.join(_directory, "$package.lock");
    if (fileExists(oldPath)) deleteEntry(oldPath);
    writeTextFile(
        _getLockFilePath(package),
        lockFile.serialize(cache.rootDir, cache.sources));
    var id = lockFile.packages[package];
    log.message('Activated ${_formatPackage(id)}.');
  }
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
      return null;
    }
  }
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
  Future<Entrypoint> find(String name) {
    return new Future.sync(() {
      var lockFilePath = _getLockFilePath(name);
      var lockFile;
      try {
        lockFile = new LockFile.load(lockFilePath, cache.sources);
      } on IOException catch (error) {
        var oldLockFilePath = p.join(_directory, '$name.lock');
        try {
          lockFile = new LockFile.load(oldLockFilePath, cache.sources);
        } on IOException catch (error) {
          dataError("No active package ${log.bold(name)}.");
        }
        ensureDir(p.dirname(lockFilePath));
        new File(oldLockFilePath).renameSync(lockFilePath);
      }
      var id = lockFile.packages[name];
      lockFile.packages.remove(name);
      var source = cache.sources[id.source];
      if (source is CachedSource) {
        return cache.sources[id.source].getDirectory(
            id).then((dir) => new Package.load(name, dir, cache.sources)).then((package) {
          return new Entrypoint.inMemory(package, lockFile, cache);
        });
      }
      assert(id.source == "path");
      return new Entrypoint(
          PathSource.pathFromDescription(id.description),
          cache);
    });
  }
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
  String _getLockFilePath(String name) =>
      p.join(_directory, name, "pubspec.lock");
  void listActivePackages() {
    if (!dirExists(_directory)) return;
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
  void _updateBinStubs(Package package, List<String> executables,
      {bool overwriteBinStubs}) {
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
      var previousPackage =
          _createBinStub(package, executable, script, overwrite: overwriteBinStubs);
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
    if (executables != null) {
      var unknown = ordered(
          executables.where((exe) => !package.pubspec.executables.keys.contains(exe)));
      if (unknown.isNotEmpty) {
        dataError("Unknown ${namedSequence('executable', unknown)}.");
      }
    }
    var binFiles = package.listFiles(
        beneath: "bin",
        recursive: false).map((path) => p.relative(path, from: package.dir)).toList();
    for (var executable in installed) {
      var script = package.pubspec.executables[executable];
      var scriptPath = p.join("bin", "$script.dart");
      if (!binFiles.contains(scriptPath)) {
        log.warning(
            'Warning: Executable "$executable" runs "$scriptPath", '
                'which was not found in ${log.bold(package.name)}.');
      }
    }
  }
  String _createBinStub(Package package, String executable, String script,
      {bool overwrite}) {
    var binStubPath = p.join(_binStubDir, executable);
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
    if (Platform.operatingSystem == "windows") {
      var batch = """
@echo off
rem This file was created by pub v${sdk.version}.
rem Package: ${package.name}
rem Version: ${package.version}
rem Executable: ${executable}
rem Script: ${script}
pub global run ${package.name}:$script "%*"
""";
      writeTextFile(binStubPath, batch);
    } else {
      var bash = """
# This file was created by pub v${sdk.version}.
# Package: ${package.name}
# Version: ${package.version}
# Executable: ${executable}
# Script: ${script}
pub global run ${package.name}:$script "\$@"
""";
      writeTextFile(binStubPath, bash);
      var result = Process.runSync('chmod', ['+x', binStubPath]);
      if (result.exitCode != 0) {
        try {
          deleteEntry(binStubPath);
        } on IOException catch (err) {
          log.fine("Could not delete binstub:\n$err");
        }
        fail(
            'Could not make "$binStubPath" executable (exit code '
                '${result.exitCode}):\n${result.stderr}');
      }
    }
    return previousPackage;
  }
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
}
