library pub.dart;
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:analyzer/analyzer.dart';
import 'package:path/path.dart' as path;
import '../../../compiler/compiler.dart' as compiler;
import '../../../compiler/implementation/filenames.dart' show appendSlash;
import '../../asset/dart/serialize.dart';
import 'io.dart';
import 'log.dart' as log;
abstract class CompilerProvider {
  Uri get libraryRoot;
  Future provideInput(Uri uri);
  void handleDiagnostic(Uri uri, int begin, int end, String message,
      compiler.Diagnostic kind);
  EventSink<String> provideOutput(String name, String extension);
}
Future compile(String entrypoint, CompilerProvider provider,
    {Iterable<String> commandLineOptions, bool checked: false, bool csp: false,
    bool minify: true, bool verbose: false, Map<String, String> environment,
    String packageRoot, bool analyzeAll: false, bool suppressWarnings: false,
    bool suppressHints: false, bool suppressPackageWarnings: true, bool terse:
    false, bool includeSourceMapUrls: false, bool toDart: false}) {
  return new Future.sync(() {
    var options = <String>['--categories=Client,Server'];
    if (checked) options.add('--enable-checked-mode');
    if (csp) options.add('--csp');
    if (minify) options.add('--minify');
    if (verbose) options.add('--verbose');
    if (analyzeAll) options.add('--analyze-all');
    if (suppressWarnings) options.add('--suppress-warnings');
    if (suppressHints) options.add('--suppress-hints');
    if (!suppressPackageWarnings) options.add('--show-package-warnings');
    if (terse) options.add('--terse');
    if (toDart) options.add('--output-type=dart');
    var sourceUrl = path.toUri(entrypoint);
    options.add("--out=$sourceUrl.js");
    if (includeSourceMapUrls) {
      options.add("--source-map=$sourceUrl.js.map");
    }
    if (environment == null) environment = {};
    if (commandLineOptions != null) options.addAll(commandLineOptions);
    if (packageRoot == null) {
      packageRoot = path.join(path.dirname(entrypoint), 'packages');
    }
    return compiler.compile(
        path.toUri(entrypoint),
        provider.libraryRoot,
        path.toUri(appendSlash(packageRoot)),
        provider.provideInput,
        provider.handleDiagnostic,
        options,
        provider.provideOutput,
        environment);
  });
}
bool isEntrypoint(CompilationUnit dart) {
  return dart.declarations.any((node) {
    return node is FunctionDeclaration &&
        node.name.name == "main" &&
        node.functionExpression.parameters.parameters.length <= 2;
  });
}
List<UriBasedDirective> parseImportsAndExports(String contents, {String name}) {
  var collector = new _DirectiveCollector();
  parseDirectives(contents, name: name).accept(collector);
  return collector.directives;
}
class _DirectiveCollector extends GeneralizingAstVisitor {
  final directives = <UriBasedDirective>[];
  visitUriBasedDirective(UriBasedDirective node) => directives.add(node);
}
Future runInIsolate(String code, message, {packageRoot, String snapshot}) {
  final completer0 = new Completer();
  scheduleMicrotask(() {
    try {
      join0() {
        withTempDir(((dir) {
          final completer0 = new Completer();
          scheduleMicrotask(() {
            try {
              var dartPath = path.join(dir, 'runInIsolate.dart');
              writeTextFile(dartPath, code, dontLogContents: true);
              var port = new ReceivePort();
              join0(x0) {
                Isolate.spawn(_isolateBuffer, {
                  'replyTo': port.sendPort,
                  'uri': path.toUri(dartPath).toString(),
                  'packageRoot': x0,
                  'message': message
                }).then((x1) {
                  try {
                    x1;
                    port.first.then((x2) {
                      try {
                        var response = x2;
                        join1() {
                          join2() {
                            ensureDir(path.dirname(snapshot));
                            var snapshotArgs = [];
                            join3() {
                              snapshotArgs.addAll(
                                  ['--snapshot=${snapshot}', dartPath]);
                              runProcess(
                                  Platform.executable,
                                  snapshotArgs).then((x3) {
                                try {
                                  var result = x3;
                                  join4() {
                                    log.warning(
                                        "Failed to compile a snapshot to " "${path.relative(snapshot)}:\n" +
                                            result.stderr.join("\n"));
                                    completer0.complete(null);
                                  }
                                  if (result.success) {
                                    completer0.complete(null);
                                  } else {
                                    join4();
                                  }
                                } catch (e2) {
                                  completer0.completeError(e2);
                                }
                              }, onError: (e3) {
                                completer0.completeError(e3);
                              });
                            }
                            if (packageRoot != null) {
                              snapshotArgs.add('--package-root=${packageRoot}');
                              join3();
                            } else {
                              join3();
                            }
                          }
                          if (snapshot == null) {
                            completer0.complete(null);
                          } else {
                            join2();
                          }
                        }
                        if (response['type'] == 'error') {
                          completer0.completeError(
                              new CrossIsolateException.deserialize(response['error']));
                        } else {
                          join1();
                        }
                      } catch (e1) {
                        completer0.completeError(e1);
                      }
                    }, onError: (e4) {
                      completer0.completeError(e4);
                    });
                  } catch (e0) {
                    completer0.completeError(e0);
                  }
                }, onError: (e5) {
                  completer0.completeError(e5);
                });
              }
              if (packageRoot == null) {
                join0(null);
              } else {
                join0(packageRoot.toString());
              }
            } catch (e6) {
              completer0.completeError(e6);
            }
          });
          return completer0.future;
        })).then((x0) {
          try {
            x0;
            completer0.complete(null);
          } catch (e0) {
            completer0.completeError(e0);
          }
        }, onError: (e1) {
          completer0.completeError(e1);
        });
      }
      if (snapshot != null && fileExists(snapshot)) {
        log.fine("Spawning isolate from ${snapshot}.");
        join1() {
          join2(x1) {
            join0();
          }
          finally0(cont0, v0) {
            cont0(v0);
          }
          catch0(error) {
            log.fine("Couldn't load existing snapshot ${snapshot}:\n${error}");
            finally0(join2, null);
          }
          try {
            Isolate.spawnUri(
                path.toUri(snapshot),
                [],
                message,
                packageRoot: packageRoot).then((x2) {
              try {
                x2;
                finally0((v1) {
                  completer0.complete(v1);
                }, null);
              } catch (e2) {
                catch0(e2);
              }
            }, onError: (e3) {
              catch0(e3);
            });
          } catch (e4) {
            catch0(e4);
          }
        }
        if (packageRoot != null) {
          packageRoot = packageRoot.toString();
          join1();
        } else {
          join1();
        }
      } else {
        join0();
      }
    } catch (e5) {
      completer0.completeError(e5);
    }
  });
  return completer0.future;
}
void _isolateBuffer(message) {
  var replyTo = message['replyTo'];
  var packageRoot = message['packageRoot'];
  if (packageRoot != null) packageRoot = Uri.parse(packageRoot);
  Isolate.spawnUri(
      Uri.parse(message['uri']),
      [],
      message['message'],
      packageRoot: packageRoot).then((_) => replyTo.send({
    'type': 'success'
  })).catchError((e, stack) {
    replyTo.send({
      'type': 'error',
      'error': CrossIsolateException.serialize(e, stack)
    });
  });
}
