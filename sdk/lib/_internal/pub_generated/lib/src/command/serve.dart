// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.serve;

import 'dart:async';
import 'dart:math' as math;

import 'package:barback/barback.dart';

import '../barback/asset_environment.dart';
import '../barback/pub_package_provider.dart';
import '../log.dart' as log;
import '../utils.dart';
import 'barback.dart';

final _arrow = getSpecial('\u2192', '=>');

/// Handles the `serve` pub command.
class ServeCommand extends BarbackCommand {
  String get description =>
      'Run a local web development server.\n\n'
          'By default, this serves "web/" and "test/", but an explicit list of \n'
          'directories to serve can be provided as well.';
  String get usage => "pub serve [directories...]";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-serve.html";

  PubPackageProvider _provider;

  String get hostname => commandOptions['hostname'];

  /// The base port for the servers.
  ///
  /// This will print a usage error and exit if the specified port is invalid.
  int get port => parseInt(commandOptions['port'], 'port');

  /// The port for the admin UI.
  ///
  /// This will print a usage error and exit if the specified port is invalid.
  int get adminPort {
    var adminPort = commandOptions['admin-port'];
    return adminPort == null ? null : parseInt(adminPort, 'admin port');
  }

  /// `true` if Dart entrypoints should be compiled to JavaScript.
  bool get useDart2JS => commandOptions['dart2js'];

  /// `true` if the admin server URL should be displayed on startup.
  bool get logAdminUrl => commandOptions['log-admin-url'];

  BarbackMode get defaultMode => BarbackMode.DEBUG;

  List<String> get defaultSourceDirectories => ["web", "test"];

  /// This completer is used to keep pub running (by not completing) and to
  /// pipe fatal errors to pub's top-level error-handling machinery.
  final _completer = new Completer();

  ServeCommand() {
    commandParser.addOption(
        'hostname',
        defaultsTo: 'localhost',
        help: 'The hostname to listen on.');
    commandParser.addOption(
        'port',
        defaultsTo: '8080',
        help: 'The base port to listen on.');

    // TODO(rnystrom): A hidden option to print the URL that the admin server
    // is bound to on startup. Since this is currently only used for the Web
    // Socket interface, we don't want to show it to users, but the tests and
    // Editor need this logged to know what port to bind to.
    // Remove this (and always log) when #16954 is fixed.
    commandParser.addFlag('log-admin-url', defaultsTo: false, hide: true);

    // TODO(nweiz): Make this public when issue 16954 is fixed.
    commandParser.addOption('admin-port', hide: true);

    commandParser.addFlag(
        'dart2js',
        defaultsTo: true,
        help: 'Compile Dart to JavaScript.');
    commandParser.addFlag(
        'force-poll',
        defaultsTo: false,
        help: 'Force the use of a polling filesystem watcher.');
  }

  Future onRunTransformerCommand() {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        var port = parseInt(commandOptions['port'], 'port');
        join0(x0) {
          var adminPort = x0;
          join1(x1) {
            var watcherType = x1;
            AssetEnvironment.create(
                entrypoint,
                mode,
                watcherType: watcherType,
                hostname: hostname,
                basePort: port,
                useDart2JS: useDart2JS).then((x2) {
              try {
                var environment = x2;
                var directoryLength = sourceDirectories.map(((dir) {
                  return dir.length;
                })).reduce(math.max);
                environment.startAdminServer(adminPort).then((x3) {
                  try {
                    var server = x3;
                    server.results.listen(((_) {
                      assert(false);
                    }), onError: _fatalError);
                    join2() {
                      environment.pauseUpdates();
                      var it0 = sourceDirectories.iterator;
                      break0() {
                        environment.barback.errors.listen(((error) {
                          log.error(log.red("Build error:\n$error"));
                        }));
                        environment.barback.results.listen(((result) {
                          if (result.succeeded) {
                            log.message(
                                "Build completed ${log.green('successfully')}");
                          } else {
                            log.message(
                                "Build completed with " "${log.red(result.errors.length)} errors.");
                          }
                        }), onError: _fatalError);
                        environment.resumeUpdates();
                        _completer.future.then((x4) {
                          try {
                            x4;
                            completer0.complete();
                          } catch (e0, s0) {
                            completer0.completeError(e0, s0);
                          }
                        }, onError: completer0.completeError);
                      }
                      var trampoline0;
                      continue0() {
                        trampoline0 = null;
                        if (it0.moveNext()) {
                          var directory = it0.current;
                          _startServer(
                              environment,
                              directory,
                              directoryLength).then((x5) {
                            trampoline0 = () {
                              trampoline0 = null;
                              try {
                                x5;
                                trampoline0 = continue0;
                              } catch (e1, s1) {
                                completer0.completeError(e1, s1);
                              }
                            };
                            do trampoline0(); while (trampoline0 != null);
                          }, onError: completer0.completeError);
                        } else {
                          break0();
                        }
                      }
                      trampoline0 = continue0;
                      do trampoline0(); while (trampoline0 != null);
                    }
                    if (logAdminUrl) {
                      log.message(
                          "Running admin server on " "${log.bold('http://${hostname}:${server.port}')}");
                      join2();
                    } else {
                      join2();
                    }
                  } catch (e2, s2) {
                    completer0.completeError(e2, s2);
                  }
                }, onError: completer0.completeError);
              } catch (e3, s3) {
                completer0.completeError(e3, s3);
              }
            }, onError: completer0.completeError);
          }
          if (commandOptions['force-poll']) {
            join1(WatcherType.POLLING);
          } else {
            join1(WatcherType.AUTO);
          }
        }
        if (commandOptions['admin-port'] == null) {
          join0(null);
        } else {
          join0(parseInt(commandOptions['admin-port'], 'admin port'));
        }
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }

  Future _startServer(AssetEnvironment environment, String rootDirectory,
      int directoryLength) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        environment.serveDirectory(rootDirectory).then((x0) {
          try {
            var server = x0;
            join0() {
              var prefix =
                  log.gray(padRight("[${server.rootDirectory}]", directoryLength + 2));
              server.results.listen(((result) {
                var buffer = new StringBuffer();
                buffer.write("$prefix ");
                if (result.isSuccess) {
                  buffer.write(
                      "${log.green('GET')} ${result.url.path} $_arrow ${result.id}");
                } else {
                  buffer.write("${log.red('GET')} ${result.url.path} $_arrow");
                  var error = result.error.toString();
                  if (error.contains("\n")) {
                    buffer.write("\n${prefixLines(error)}");
                  } else {
                    buffer.write(" $error");
                  }
                }
                log.message(buffer);
              }), onError: _fatalError);
              log.message(
                  "Serving ${entrypoint.root.name} "
                      "${padRight(server.rootDirectory, directoryLength)} "
                      "on ${log.bold('http://${hostname}:${server.port}')}");
              completer0.complete();
            }
            if (mode == BarbackMode.RELEASE) {
              server.allowAsset = ((url) {
                return !url.path.endsWith(".dart");
              });
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

  /// Reports [error] and exits the server.
  void _fatalError(error, [stackTrace]) {
    if (_completer.isCompleted) return;
    _completer.completeError(error, stackTrace);
  }
}
