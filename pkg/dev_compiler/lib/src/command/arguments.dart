// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// Stores the result of preprocessing `dartdevc` command line arguments.
///
/// `dartdevc` preprocesses arguments to support some features that
/// `package:args` does not handle (training `@` to reference arguments in a
/// file).
///
/// [isBatch]/[isWorker] mode are preprocessed because they can combine
/// argument lists from the initial invocation and from batch/worker jobs.
class ParsedArguments {
  /// The user's arguments to the compiler for this compilation.
  final List<String> rest;

  /// Whether to run in `--batch` mode, e.g the Dart SDK and Language tests.
  ///
  /// Similar to [isWorker] but with a different protocol.
  /// See also [isBatchOrWorker].
  final bool isBatch;

  /// Whether to run in `--experimental-expression-compiler` mode.
  ///
  /// This is a special mode that is optimized for only compiling expressions.
  ///
  /// All dependencies must come from precompiled dill files, and those must
  /// be explicitly invalidated as needed between expression compile requests.
  /// Invalidation of dill is performed using [updateDeps] from the client (i.e.
  /// debugger) and should be done every time a dill file changes, for example,
  /// on hot reload or rebuild.
  final bool isExpressionCompiler;

  /// Whether to run in `--bazel_worker` mode, e.g. for Bazel builds.
  ///
  /// Similar to [isBatch] but with a different protocol.
  /// See also [isBatchOrWorker].
  final bool isWorker;

  /// Whether to re-use the last compiler result when in a worker.
  ///
  /// This is useful if we are repeatedly compiling things in the same context,
  /// e.g. in a debugger REPL.
  final bool reuseResult;

  /// Whether to use the incremental compiler for compiling.
  ///
  /// Note that this only makes sense when also reusing results.
  final bool useIncrementalCompiler;

  ParsedArguments._(
    this.rest, {
    this.isBatch = false,
    this.isWorker = false,
    this.reuseResult = false,
    this.useIncrementalCompiler = false,
    this.isExpressionCompiler = false,
  });

  /// Preprocess arguments to determine whether DDK is used in batch mode or as a
  /// persistent worker.
  ///
  /// When used in batch mode, we expect a `--batch` parameter.
  ///
  /// When used as a persistent bazel worker, the `--persistent_worker` might be
  /// present, and an argument of the form `@path/to/file` might be provided. The
  /// latter needs to be replaced by reading all the contents of the
  /// file and expanding them into the resulting argument list.
  factory ParsedArguments.from(List<String> args) {
    if (args.isEmpty) return ParsedArguments._(args);

    var newArgs = <String>[];
    var isWorker = false;
    var isBatch = false;
    var reuseResult = false;
    var useIncrementalCompiler = false;
    var isExpressionCompiler = false;

    Iterable<String> argsToParse = args;

    // Expand `@path/to/file`
    if (args.last.startsWith('@')) {
      var extra = _readLines(args.last.substring(1));
      argsToParse = args.take(args.length - 1).followedBy(extra);
    }

    for (var arg in argsToParse) {
      if (arg == '--persistent_worker') {
        isWorker = true;
      } else if (arg == '--batch') {
        isBatch = true;
      } else if (arg == '--reuse-compiler-result') {
        reuseResult = true;
      } else if (arg == '--use-incremental-compiler') {
        useIncrementalCompiler = true;
      } else if (arg == '--experimental-expression-compiler') {
        isExpressionCompiler = true;
      } else {
        newArgs.add(arg);
      }
    }
    return ParsedArguments._(newArgs,
        isWorker: isWorker,
        isBatch: isBatch,
        reuseResult: reuseResult,
        useIncrementalCompiler: useIncrementalCompiler,
        isExpressionCompiler: isExpressionCompiler);
  }

  /// Whether the compiler is running in [isBatch] or [isWorker] mode.
  ///
  /// Both modes are generally equivalent from the compiler's perspective,
  /// the main difference is that they use distinct protocols to communicate
  /// jobs to the compiler.
  bool get isBatchOrWorker => isBatch || isWorker;

  /// Merge [args] and return the new parsed arguments.
  ///
  /// Typically used when [isBatchOrWorker] is set to merge the compilation's
  /// arguments with any global ones that were provided when the worker started.
  ParsedArguments merge(List<String> arguments) {
    // Parse the arguments again so `--kernel` can be passed. This provides
    // added safety that we are really compiling in Kernel mode, if somehow the
    // worker was not initialized correctly.
    var newArgs = ParsedArguments.from(arguments);
    if (newArgs.isBatchOrWorker) {
      throw ArgumentError('cannot change batch or worker mode after startup.');
    }
    return ParsedArguments._(rest.toList()..addAll(newArgs.rest),
        isWorker: isWorker,
        isBatch: isBatch,
        reuseResult: reuseResult || newArgs.reuseResult,
        useIncrementalCompiler:
            useIncrementalCompiler || newArgs.useIncrementalCompiler);
  }
}

/// Return all lines in a file found at [path].
Iterable<String> _readLines(String path) {
  try {
    return File(path).readAsLinesSync().where((String line) => line.isNotEmpty);
  } on FileSystemException catch (e) {
    throw Exception('Failed to read $path: $e');
  }
}
