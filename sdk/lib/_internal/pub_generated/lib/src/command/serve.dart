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
class ServeCommand extends BarbackCommand {
  String get description =>
      'Run a local web development server.\n\n'
          'By default, this serves "web/" and "test/", but an explicit list of \n'
          'directories to serve can be provided as well.';
  String get usage => "pub serve [directories...]";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-serve.html";
  PubPackageProvider _provider;
  String get hostname => commandOptions['hostname'];
  int get port => parseInt(commandOptions['port'], 'port');
  int get adminPort {
    var adminPort = commandOptions['admin-port'];
    return adminPort == null ? null : parseInt(adminPort, 'admin port');
  }
  bool get useDart2JS => commandOptions['dart2js'];
  bool get logAdminUrl => commandOptions['log-admin-url'];
  BarbackMode get defaultMode => BarbackMode.DEBUG;
  List<String> get defaultSourceDirectories => ["web", "test"];
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
    commandParser.addFlag('log-admin-url', defaultsTo: false, hide: true);
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
                var directoryLength =
                    sourceDirectories.map(((dir) => dir.length)).reduce(math.max);
                environment.startAdminServer(adminPort).then((x3) {
                  try {
                    var server = x3;
                    server.results.listen(((_) {
                      assert(false);
                    }), onError: _fatalError);
                    join2() {
                      environment.pauseUpdates();
                      var it0 = sourceDirectories.iterator;
                      break0(x7) {
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
                            completer0.complete(null);
                          } catch (e2) {
                            completer0.completeError(e2);
                          }
                        }, onError: (e3) {
                          completer0.completeError(e3);
                        });
                      }
                      continue0(x8) {
                        if (it0.moveNext()) {
                          Future.wait([]).then((x6) {
                            var directory = it0.current;
                            _startServer(
                                environment,
                                directory,
                                directoryLength).then((x5) {
                              try {
                                x5;
                                continue0(null);
                              } catch (e4) {
                                completer0.completeError(e4);
                              }
                            }, onError: (e5) {
                              completer0.completeError(e5);
                            });
                          });
                        } else {
                          break0(null);
                        }
                      }
                      continue0(null);
                    }
                    if (logAdminUrl) {
                      log.message(
                          "Running admin server on " "${log.bold('http://${hostname}:${server.port}')}");
                      join2();
                    } else {
                      join2();
                    }
                  } catch (e1) {
                    completer0.completeError(e1);
                  }
                }, onError: (e6) {
                  completer0.completeError(e6);
                });
              } catch (e0) {
                completer0.completeError(e0);
              }
            }, onError: (e7) {
              completer0.completeError(e7);
            });
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
      } catch (e8) {
        completer0.completeError(e8);
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
              completer0.complete(null);
            }
            if (mode == BarbackMode.RELEASE) {
              server.allowAsset = ((url) => !url.path.endsWith(".dart"));
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
  void _fatalError(error, [stackTrace]) {
    if (_completer.isCompleted) return;
    _completer.completeError(error, stackTrace);
  }
}
