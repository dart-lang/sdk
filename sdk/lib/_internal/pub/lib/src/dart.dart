// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library for compiling Dart code and manipulating analyzer parse trees.
library pub.dart;

import 'dart:async';
import 'dart:isolate';

import 'package:analyzer_experimental/analyzer.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import '../../../compiler/compiler.dart' as compiler;
import '../../../compiler/implementation/source_file_provider.dart'
    show FormattingDiagnosticHandler, SourceFileProvider;
import '../../../compiler/implementation/filenames.dart'
    show appendSlash;

import 'io.dart';
import 'sdk.dart' as sdk;
import 'utils.dart';

/// Returns [entrypoint] compiled to JavaScript (or to Dart if [toDart] is
/// true).
///
/// By default, the package root is assumed to be adjacent to [entrypoint], but
/// if [packageRoot] is passed that will be used instead.
Future<String> compile(String entrypoint, {String packageRoot,
    bool toDart: false}) {
  return new Future.sync(() {
    var provider = new SourceFileProvider();
    var options = <String>['--categories=Client,Server', '--minify'];
    if (toDart) options.add('--output-type=dart');
    if (packageRoot == null) {
      packageRoot = path.join(path.dirname(entrypoint), 'packages');
    }

    return compiler.compile(
        path.toUri(entrypoint),
        path.toUri(appendSlash(_libPath)),
        path.toUri(appendSlash(packageRoot)),
        provider.readStringFromUri,
        new FormattingDiagnosticHandler(provider).diagnosticHandler,
        options);
  }).then((result) {
    if (result != null) return result;
    throw new ApplicationException('Failed to compile "$entrypoint".');
  });
}

/// Returns the path to the library directory. This corresponds to the "sdk"
/// directory in the repo and to the root of the compiled SDK.
String get _libPath {
  if (runningFromSdk) return sdk.rootDirectory;
  return path.join(repoRoot, 'sdk');
}

/// Returns whether [dart] looks like an entrypoint file.
bool isEntrypoint(CompilationUnit dart) {
  // TODO(nweiz): this misses the case where a Dart file doesn't contain main(),
  // but it parts in another file that does.
  return dart.declarations.any((node) {
    return node is FunctionDeclaration && node.name.name == "main" &&
        node.functionExpression.parameters.parameters.isEmpty;
  });
}

/// Runs [code] in an isolate.
///
/// [code] should be the contents of a Dart entrypoint. It may contain imports;
/// they will be resolved in the same context as the host isolate.
///
/// Returns a Future that will resolve to a [SendPort] that will communicate to
/// the spawned isolate once it's spawned. If the isolate fails to spawn, the
/// Future will complete with an error.
Future<SendPort> runInIsolate(String code) {
  return withTempDir((dir) {
    var dartPath = path.join(dir, 'runInIsolate.dart');
    writeTextFile(dartPath, code, dontLogContents: true);
    var bufferPort = spawnFunction(_isolateBuffer);
    return bufferPort.call(path.toUri(dartPath).toString()).then((response) {
      if (response.first == 'error') {
        return new Future.error(
            new CrossIsolateException.deserialize(response.last));
      }

      return response.last;
    });
  });
}

// TODO(nweiz): remove this when issue 12617 is fixed.
/// A function used as a buffer between the host isolate and [spawnUri].
///
/// [spawnUri] synchronously loads the file and its imports, which can deadlock
/// the host isolate if there's an HTTP import pointing at a server in the host.
/// Adding an additional isolate in the middle works around this.
void _isolateBuffer() {
  port.receive((uri, replyTo) {
    try {
      replyTo.send(['success', spawnUri(uri)]);
    } catch (e, stack) {
      replyTo.send(['error', CrossIsolateException.serialize(e, stack)]);
    }
  });
}

/// An exception that was originally raised in another isolate.
///
/// Exception objects can't cross isolate boundaries in general, so this class
/// wraps as much information as can be consistently serialized.
class CrossIsolateException implements Exception {
  /// The name of the type of exception thrown.
  ///
  /// This is the return value of [error.runtimeType.toString()]. Keep in mind
  /// that objects in different libraries may have the same type name.
  final String type;

  /// The exception's message, or its [toString] if it didn't expose a `message`
  /// property.
  final String message;

  /// The exception's stack trace, or `null` if no stack trace was available.
  final Trace stackTrace;

  /// Loads a [CrossIsolateException] from a serialized representation.
  ///
  /// [error] should be the result of [CrossIsolateException.serialize].
  factory CrossIsolateException.deserialize(Map error) {
    var type = error['type'];
    var message = error['message'];
    var stackTrace = error['stack'] == null ? null :
            new Trace.parse(error['stack']);
    return new CrossIsolateException._(type, message, stackTrace);
  }

  /// Loads a [CrossIsolateException] from a serialized representation.
  ///
  /// [error] should be the result of [CrossIsolateException.serialize].
  CrossIsolateException._(this.type, this.message, this.stackTrace);

  /// Serializes [error] to an object that can safely be passed across isolate
  /// boundaries.
  static Map serialize(error, [StackTrace stack]) {
    if (stack == null) stack = getAttachedStackTrace(error);
    return {
      'type': error.runtimeType.toString(),
      'message': getErrorMessage(error),
      'stack': stack == null ? null : stack.toString()
    };
  }

  String toString() => "$message\n$stackTrace";
}
