// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.executable;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';

import 'barback/asset_environment.dart';
import 'entrypoint.dart';
import 'exit_codes.dart' as exit_codes;
import 'io.dart';
import 'log.dart' as log;
import 'utils.dart';

/// Runs [executable] from [package] reachable from [entrypoint].
///
/// The executable string is a relative Dart file path using native path
/// separators with or without a trailing ".dart" extension. It is contained
/// within [package], which should either be the entrypoint package or an
/// immediate dependency of it.
///
/// Arguments from [args] will be passed to the spawned Dart application.
///
/// If [mode] is passed, it's used as the barback mode; it defaults to
/// [BarbackMode.RELEASE].
///
/// Returns the exit code of the spawned app.
Future<int> runExecutable(Entrypoint entrypoint, String package,
    String executable, Iterable<String> args, {bool isGlobal: false,
    BarbackMode mode}) {
  final completer0 = new Completer();
  scheduleMicrotask(() {
    try {
      join0() {
        join1() {
          join2() {
            join3() {
              var localSnapshotPath =
                  p.join(".pub", "bin", package, "${executable}.dart.snapshot");
              join4() {
                var rootDir = "bin";
                var parts = p.split(executable);
                join5() {
                  var assetPath = "${p.url.joinAll(p.split(executable))}.dart";
                  var id = new AssetId(package, assetPath);
                  AssetEnvironment.create(
                      entrypoint,
                      mode,
                      useDart2JS: false,
                      entrypoints: [id]).then((x0) {
                    try {
                      var environment = x0;
                      environment.barback.errors.listen(((error) {
                        log.error(log.red("Build error:\n$error"));
                      }));
                      var server;
                      join6() {
                        completer0.complete(
                            environment.barback.getAssetById(id).then(((_) {
                          final completer0 = new Completer();
                          scheduleMicrotask(() {
                            try {
                              var vmArgs = [];
                              vmArgs.add("--checked");
                              var relativePath =
                                  p.url.relative(assetPath, from: p.url.joinAll(p.split(server.rootDirectory)));
                              vmArgs.add(
                                  server.url.resolve(relativePath).toString());
                              vmArgs.addAll(args);
                              Process.start(
                                  Platform.executable,
                                  vmArgs).then((x0) {
                                try {
                                  var process = x0;
                                  process.stderr.listen(stderr.add);
                                  process.stdout.listen(stdout.add);
                                  stdin.listen(process.stdin.add);
                                  completer0.complete(process.exitCode);
                                } catch (e0, s0) {
                                  completer0.completeError(e0, s0);
                                }
                              }, onError: completer0.completeError);
                            } catch (e, s) {
                              completer0.completeError(e, s);
                            }
                          });
                          return completer0.future;
                        })).catchError(((error, stackTrace) {
                          if (error is! AssetNotFoundException) throw error;
                          var message =
                              "Could not find ${log.bold(executable + ".dart")}";
                          if (package != entrypoint.root.name) {
                            message +=
                                " in package ${log.bold(server.package)}";
                          }
                          log.error("$message.");
                          log.fine(new Chain.forTrace(stackTrace));
                          return exit_codes.NO_INPUT;
                        })));
                      }
                      if (package == entrypoint.root.name) {
                        environment.serveDirectory(rootDir).then((x1) {
                          try {
                            server = x1;
                            join6();
                          } catch (e0, s0) {
                            completer0.completeError(e0, s0);
                          }
                        }, onError: completer0.completeError);
                      } else {
                        environment.servePackageBinDirectory(
                            package).then((x2) {
                          try {
                            server = x2;
                            join6();
                          } catch (e1, s1) {
                            completer0.completeError(e1, s1);
                          }
                        }, onError: completer0.completeError);
                      }
                    } catch (e2, s2) {
                      completer0.completeError(e2, s2);
                    }
                  }, onError: completer0.completeError);
                }
                if (parts.length > 1) {
                  assert(!isGlobal && package == entrypoint.root.name);
                  rootDir = parts.first;
                  join5();
                } else {
                  executable = p.join("bin", executable);
                  join5();
                }
              }
              if (!isGlobal &&
                  fileExists(localSnapshotPath) &&
                  mode == BarbackMode.RELEASE) {
                completer0.complete(
                    _runCachedExecutable(entrypoint, localSnapshotPath, args));
              } else {
                join4();
              }
            }
            if (p.extension(executable) == ".dart") {
              executable = p.withoutExtension(executable);
              join3();
            } else {
              join3();
            }
          }
          if (log.verbosity == log.Verbosity.NORMAL) {
            log.verbosity = log.Verbosity.WARNING;
            join2();
          } else {
            join2();
          }
        }
        if (entrypoint.root.name != package &&
            !entrypoint.root.immediateDependencies.any(((dep) {
          return dep.name == package;
        }))) {
          entrypoint.loadPackageGraph().then((x3) {
            try {
              var graph = x3;
              join7() {
                join1();
              }
              if (graph.packages.containsKey(package)) {
                dataError(
                    'Package "${package}" is not an immediate dependency.\n'
                        'Cannot run executables in transitive dependencies.');
                join7();
              } else {
                dataError(
                    'Could not find package "${package}". Did you forget to add a ' 'dependency?');
                join7();
              }
            } catch (e3, s3) {
              completer0.completeError(e3, s3);
            }
          }, onError: completer0.completeError);
        } else {
          join1();
        }
      }
      if (mode == null) {
        mode = BarbackMode.RELEASE;
        join0();
      } else {
        join0();
      }
    } catch (e, s) {
      completer0.completeError(e, s);
    }
  });
  return completer0.future;
}

/// Runs the snapshot at [path] with [args] and hooks its stdout, stderr, and
/// sdtin to this process's.
///
/// If [recompile] is passed, it's called if the snapshot is out-of-date. It's
/// expected to regenerate a snapshot at [path], after which the snapshot will
/// be re-run. It may return a Future.
///
/// If [checked] is set, runs the snapshot in checked mode.
///
/// Returns the snapshot's exit code.
///
/// This doesn't do any validation of the snapshot's SDK version.
Future<int> runSnapshot(String path, Iterable<String> args, {recompile(),
    bool checked: false}) {
  final completer0 = new Completer();
  scheduleMicrotask(() {
    try {
      var vmArgs = [path]..addAll(args);
      join0() {
        var stdin1;
        var stdin2;
        join1() {
          runProcess(input) {
            final completer0 = new Completer();
            scheduleMicrotask(() {
              try {
                Process.start(Platform.executable, vmArgs).then((x0) {
                  try {
                    var process = x0;
                    process.stderr.listen(stderr.add);
                    process.stdout.listen(stdout.add);
                    input.listen(process.stdin.add);
                    completer0.complete(process.exitCode);
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
          runProcess(stdin1).then((x0) {
            try {
              var exitCode = x0;
              join2() {
                recompile().then((x1) {
                  try {
                    x1;
                    completer0.complete(runProcess(stdin2));
                  } catch (e0, s0) {
                    completer0.completeError(e0, s0);
                  }
                }, onError: completer0.completeError);
              }
              if (recompile == null || exitCode != 255) {
                completer0.complete(exitCode);
              } else {
                join2();
              }
            } catch (e1, s1) {
              completer0.completeError(e1, s1);
            }
          }, onError: completer0.completeError);
        }
        if (recompile == null) {
          stdin1 = stdin;
          join1();
        } else {
          var pair = tee(stdin);
          stdin1 = pair.first;
          stdin2 = pair.last;
          join1();
        }
      }
      if (checked) {
        vmArgs.insert(0, "--checked");
        join0();
      } else {
        join0();
      }
    } catch (e, s) {
      completer0.completeError(e, s);
    }
  });
  return completer0.future;
}

/// Runs the executable snapshot at [snapshotPath].
Future<int> _runCachedExecutable(Entrypoint entrypoint, String snapshotPath,
    List<String> args) {
  return runSnapshot(snapshotPath, args, checked: true, recompile: () {
    log.fine("Precompiled executable is out of date.");
    return entrypoint.precompileExecutables();
  });
}
