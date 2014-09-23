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

import '../../../compiler/compiler.dart' as compiler;
import '../../../compiler/implementation/filenames.dart'
    show appendSlash;

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
  Future/*<String | List<int>>*/ provideInput(Uri uri);

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
Future compile(String entrypoint, CompilerProvider provider, {
    Iterable<String> commandLineOptions,
    bool checked: false,
    bool csp: false,
    bool minify: true,
    bool verbose: false,
    Map<String, String> environment,
    String packageRoot,
    bool analyzeAll: false,
    bool suppressWarnings: false,
    bool suppressHints: false,
    bool suppressPackageWarnings: true,
    bool terse: false,
    bool includeSourceMapUrls: false,
    bool toDart: false}) {
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
    return node is FunctionDeclaration && node.name.name == "main" &&
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
  if (snapshot != null && fileExists(snapshot)) {
    log.fine("Spawning isolate from $snapshot.");
    if (packageRoot != null) packageRoot = packageRoot.toString();
    return Isolate.spawnUri(path.toUri(snapshot), [], message,
        packageRoot: packageRoot);
  }

  return withTempDir((dir) async {
    var dartPath = path.join(dir, 'runInIsolate.dart');
    writeTextFile(dartPath, code, dontLogContents: true);
    var port = new ReceivePort();
    await Isolate.spawn(_isolateBuffer, {
      'replyTo': port.sendPort,
      'uri': path.toUri(dartPath).toString(),
      'packageRoot': packageRoot == null ? null : packageRoot.toString(),
      'message': message
    });

    var response = await port.first;
    if (response['type'] == 'error') {
      throw new CrossIsolateException.deserialize(response['error']);
    }

    if (snapshot == null) return;

    ensureDir(path.dirname(snapshot));
    var snapshotArgs = [];
    if (packageRoot != null) snapshotArgs.add('--package-root=$packageRoot');
    snapshotArgs.addAll(['--snapshot=$snapshot', dartPath]);
    var result = await runProcess(Platform.executable, snapshotArgs);

    if (result.success) return;

    // Don't emit a fatal error here, since we don't want to crash the
    // otherwise successful isolate load.
    log.warning("Failed to compile a snapshot to "
        "${path.relative(snapshot)}:\n" + result.stderr.join("\n"));
  });
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
  Isolate.spawnUri(Uri.parse(message['uri']), [], message['message'],
          packageRoot: packageRoot)
      .then((_) => replyTo.send({'type': 'success'}))
      .catchError((e, stack) {
    replyTo.send({
      'type': 'error',
      'error': CrossIsolateException.serialize(e, stack)
    });
  });
}
