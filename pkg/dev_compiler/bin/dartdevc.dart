#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line entry point for Dart Development Compiler (dartdevc).
///
/// Supported commands are
///   * compile: builds a collection of dart libraries into a single JS module
///
/// Additionally, these commands are being considered
///   * link:  combines several JS modules into a single JS file
///   * build: compiles & links a set of code, automatically determining
///            appropriate groupings of libraries to combine into JS modules
///   * watch: watch a directory and recompile build units automatically
///   * serve: uses `watch` to recompile and exposes a simple static file server
///            for local development
///
/// These commands are combined so we have less names to expose on the PATH,
/// and for development simplicity while the precise UI has not been determined.
///
/// A more typical structure for web tools is simply to have the compiler with
/// "watch" as an option. The challenge for us is:
///
/// * Dart used to assume whole-program compiles, so we don't have a
///   user-declared unit of building, and neither "libraries" or "packages" will
///   work,
/// * We do not assume a `node` JS installation, so we cannot easily reuse
///   existing tools for the "link" step, or assume users have a local
///   file server,
/// * We didn't have a file watcher API at first,
/// * We had no conventions about where compiled output should go (or even
///   that we would be compiling at all, vs running on an in-browser Dart VM),
/// * We wanted a good first impression with our simple examples, so we used
///   local file servers, and users have an expectation of it now, even though
///   it doesn't scale to typical apps that need their own real servers.

import 'dart:async';
import 'dart:io';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:bazel_worker/bazel_worker.dart';
import 'package:dev_compiler/src/compiler/command.dart';

Future main(List<String> args) async {
  // Always returns a new modifiable list.
  args = _preprocessArgs(args);

  if (args.contains('--persistent_worker')) {
    new _CompilerWorker(args..remove('--persistent_worker')).run();
  } else {
    exitCode = compile(args);
  }
}

/// Runs the compiler worker loop.
class _CompilerWorker extends AsyncWorkerLoop {
  /// The original args supplied to the executable.
  final List<String> _startupArgs;

  _CompilerWorker(this._startupArgs) : super();

  /// Performs each individual work request.
  Future<WorkResponse> performRequest(WorkRequest request) async {
    var args = _startupArgs.toList()..addAll(request.arguments);

    var output = new StringBuffer();
    var exitCode = compile(args, printFn: output.writeln);
    AnalysisEngine.instance.clearCaches();
    return new WorkResponse()
      ..exitCode = exitCode
      ..output = output.toString();
  }
}

/// Always returns a new modifiable list.
///
/// If the final arg is `@file_path` then read in all the lines of that file
/// and add those as args.
///
/// Bazel actions that support workers must provide all their per-WorkRequest
/// arguments in a file like this instead of as normal args.
List<String> _preprocessArgs(List<String> args) {
  args = new List.from(args);
  if (args.isNotEmpty && args.last.startsWith('@')) {
    var fileArg = args.removeLast();
    args.addAll(new File(fileArg.substring(1)).readAsLinesSync());
  }
  return args;
}
