// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library for compiling Dart code and manipulating analyzer parse trees.
library pub.dart;

import 'dart:async';
import 'dart:isolate';

import 'package:analyzer/analyzer.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import '../../../compiler/compiler.dart' as compiler;
import '../../../compiler/implementation/source_file_provider.dart'
    show FormattingDiagnosticHandler, CompilerSourceFileProvider;
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
///
/// If [inputProvider] and [diagnosticHandler] are omitted, uses a default
/// [compiler.CompilerInputProvider] that loads directly from the filesystem.
/// If either is provided, both must be.
Future<String> compile(String entrypoint, {String packageRoot,
    bool toDart: false, compiler.CompilerInputProvider inputProvider,
    compiler.DiagnosticHandler diagnosticHandler}) {
  return new Future.sync(() {
    var options = <String>['--categories=Client,Server', '--minify'];
    if (toDart) options.add('--output-type=dart');
    if (packageRoot == null) {
      packageRoot = path.join(path.dirname(entrypoint), 'packages');
    }

    // Must either pass both of these or neither.
    if ((inputProvider == null) != (diagnosticHandler == null)) {
      throw new ArgumentError("If either inputProvider or diagnosticHandler "
          "is passed, then both must be.");
    }

    if (inputProvider == null) {
      var provider = new CompilerSourceFileProvider();
      inputProvider = provider.readStringFromUri;
      diagnosticHandler = new FormattingDiagnosticHandler(provider)
          .diagnosticHandler;
    }

    return compiler.compile(
        path.toUri(entrypoint),
        path.toUri(appendSlash(_libPath)),
        path.toUri(appendSlash(packageRoot)),
        inputProvider, diagnosticHandler, options).then((js) {
      if (js == null) throw new CompilerException(entrypoint);
      return js;
    });
  });
}

/// Returns the path to the directory containing the Dart core libraries.
///
/// This corresponds to the "sdk" directory in the repo and to the root of the
/// compiled SDK.
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
/// they will be resolved in the same context as the host isolate. [message] is
/// passed to the [main] method of the code being run; the caller is responsible
/// for using this to establish communication with the isolate.
///
/// Returns a Future that will fire when the isolate has been spawned. If the
/// isolate fails to spawn, the Future will complete with an error.
Future runInIsolate(String code, message) {
  return withTempDir((dir) {
    var dartPath = path.join(dir, 'runInIsolate.dart');
    writeTextFile(dartPath, code, dontLogContents: true);
    var port = new ReceivePort();
    return Isolate.spawn(_isolateBuffer, {
      'replyTo': port.sendPort,
      'uri': path.toUri(dartPath).toString(),
      'message': message
    }).then((_) => port.first).then((response) {
      if (response['type'] == 'success') return;
      assert(response['type'] == 'error');
      return new Future.error(
          new CrossIsolateException.deserialize(response['error']));
    });
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
  // TODO(floitsch): If we do it right we shouldn't need to capture synchronous
  // errors.
  new Future.sync(() {
    return Isolate.spawnUri(Uri.parse(message['uri']), [], message['message']);
  }).then((_) => replyTo.send({'type': 'success'})).catchError((e, stack) {
    replyTo.send({
      'type': 'error',
      'error': CrossIsolateException.serialize(e, stack)
    });
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

/// An exception thrown when dart2js generates compiler errors.
class CompilerException extends ApplicationException {
  CompilerException(String entrypoint)
      : super('Failed to compile "$entrypoint".');
}
