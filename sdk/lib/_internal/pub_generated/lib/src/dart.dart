// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library for compiling Dart code and manipulating analyzer parse trees.
library pub.dart;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/analyzer.dart';
import 'package:path/path.dart' as path;

import '../../../../../../pkg/compiler/lib/compiler.dart' as compiler;
import '../../../../../../pkg/compiler/lib/src/filenames.dart' show appendSlash;

import '../../asset/dart/serialize.dart';
import 'io.dart';
import 'log.dart' as log;

/// Interface to communicate with dart2js.
///
/// This is basically an amalgamation of dart2js's
/// [compiler.CompilerInputProvider], [compiler.CompilerOutputProvider], and
/// [compiler.DiagnosticHandler] function types so that we can provide them
/// as a single unit.
abstract class CompilerProvider {
  /// The URI to the root directory where "dart:" libraries can be found.
  ///
  /// This is used as the base URL to generate library URLs that are then sent
  /// back to [provideInput].
  Uri get libraryRoot;

  /// Given [uri], responds with a future that completes to the contents of
  /// the input file at that URI.
  ///
  /// The future can complete to a string or a list of bytes.
  Future /*<String | List<int>>*/ provideInput(Uri uri);

  /// Reports a diagnostic message from dart2js to the user.
  void handleDiagnostic(Uri uri, int begin, int end, String message,
      compiler.Diagnostic kind);

  /// Given a [name] (which will be "" for the entrypoint) and a file extension,
  /// returns an [EventSink] that dart2js can write to to emit an output file.
  EventSink<String> provideOutput(String name, String extension);
}

/// Compiles [entrypoint] to JavaScript (or to Dart if [toDart] is true) as
/// well as any ancillary outputs dart2js creates.
///
/// Uses [provider] to communcate between dart2js and the caller. Returns a
/// future that completes when compilation is done.
///
/// By default, the package root is assumed to be adjacent to [entrypoint], but
/// if [packageRoot] is passed that will be used instead.
Future compile(String entrypoint, CompilerProvider provider,
    {Iterable<String> commandLineOptions, bool checked: false, bool csp: false,
    bool minify: true, bool verbose: false, Map<String, String> environment,
    String packageRoot, bool analyzeAll: false, bool preserveUris: false,
    bool suppressWarnings: false, bool suppressHints: false,
    bool suppressPackageWarnings: true, bool terse: false,
    bool includeSourceMapUrls: false, bool toDart: false}) {
  return new Future.sync(() {
    var options = <String>['--categories=Client,Server'];
    if (checked) options.add('--enable-checked-mode');
    if (csp) options.add('--csp');
    if (minify) options.add('--minify');
    if (verbose) options.add('--verbose');
    if (analyzeAll) options.add('--analyze-all');
    if (preserveUris) options.add('--preserve-uris');
    if (suppressWarnings) options.add('--suppress-warnings');
    if (suppressHints) options.add('--suppress-hints');
    if (!suppressPackageWarnings) options.add('--show-package-warnings');
    if (terse) options.add('--terse');
    if (toDart) options.add('--output-type=dart');

    var sourceUrl = path.toUri(entrypoint);
    options.add("--out=$sourceUrl.js");

    // Add the source map URLs.
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

/// Returns whether [dart] looks like an entrypoint file.
bool isEntrypoint(CompilationUnit dart) {
  // Allow two or fewer arguments so that entrypoints intended for use with
  // [spawnUri] get counted.
  //
  // TODO(nweiz): this misses the case where a Dart file doesn't contain main(),
  // but it parts in another file that does.
  return dart.declarations.any((node) {
    return node is FunctionDeclaration &&
        node.name.name == "main" &&
        node.functionExpression.parameters.parameters.length <= 2;
  });
}

/// Efficiently parses the import and export directives in [contents].
///
/// If [name] is passed, it's used as the filename for error reporting.
List<UriBasedDirective> parseImportsAndExports(String contents, {String name}) {
  var collector = new _DirectiveCollector();
  parseDirectives(contents, name: name).accept(collector);
  return collector.directives;
}

/// A simple visitor that collects import and export nodes.
class _DirectiveCollector extends GeneralizingAstVisitor {
  final directives = <UriBasedDirective>[];

  visitUriBasedDirective(UriBasedDirective node) => directives.add(node);
}

/// Runs [code] in an isolate.
///
/// [code] should be the contents of a Dart entrypoint. It may contain imports;
/// they will be resolved in the same context as the host isolate. [message] is
/// passed to the [main] method of the code being run; the caller is responsible
/// for using this to establish communication with the isolate.
///
/// [packageRoot] controls the package root of the isolate. It may be either a
/// [String] or a [Uri].
///
/// If [snapshot] is passed, the isolate will be loaded from that path if it
/// exists. Otherwise, a snapshot of the isolate's code will be saved to that
/// path once the isolate is loaded.
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
                                    completer0.complete();
                                  }
                                  if (result.success) {
                                    completer0.complete(null);
                                  } else {
                                    join4();
                                  }
                                } catch (e0, s0) {
                                  completer0.completeError(e0, s0);
                                }
                              }, onError: completer0.completeError);
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
                          throw new CrossIsolateException.deserialize(
                              response['error']);
                          join1();
                        } else {
                          join1();
                        }
                      } catch (e1, s1) {
                        completer0.completeError(e1, s1);
                      }
                    }, onError: completer0.completeError);
                  } catch (e2, s2) {
                    completer0.completeError(e2, s2);
                  }
                }, onError: completer0.completeError);
              }
              if (packageRoot == null) {
                join0(null);
              } else {
                join0(packageRoot.toString());
              }
            } catch (e, s) {
              completer0.completeError(e, s);
            }
          });
          return completer0.future;
        })).then((x0) {
          try {
            x0;
            completer0.complete();
          } catch (e0, s0) {
            completer0.completeError(e0, s0);
          }
        }, onError: completer0.completeError);
      }
      if (snapshot != null && fileExists(snapshot)) {
        log.fine("Spawning isolate from ${snapshot}.");
        join1() {
          join2() {
            join0();
          }
          catch0(error, s1) {
            try {
              if (error is IsolateSpawnException) {
                log.fine(
                    "Couldn't load existing snapshot ${snapshot}:\n${error}");
                join2();
              } else {
                throw error;
              }
            } catch (error, s1) {
              completer0.completeError(error, s1);
            }
          }
          try {
            Isolate.spawnUri(
                path.toUri(snapshot),
                [],
                message,
                packageRoot: packageRoot).then((x1) {
              try {
                x1;
                completer0.complete(null);
              } catch (e1, s2) {
                catch0(e1, s2);
              }
            }, onError: catch0);
          } catch (e2, s3) {
            catch0(e2, s3);
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
    } catch (e, s) {
      completer0.completeError(e, s);
    }
  });
  return completer0.future;
}

// TODO(nweiz): remove this when issue 12617 is fixed.
/// A function used as a buffer between the host isolate and [spawnUri].
///
/// [spawnUri] synchronously loads the file and its imports, which can deadlock
/// the host isolate if there's an HTTP import pointing at a server in the host.
/// Adding an additional isolate in the middle works around this.
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
