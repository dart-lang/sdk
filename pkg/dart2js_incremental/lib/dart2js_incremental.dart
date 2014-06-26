// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_incremental;

import 'dart:async' show
    Future;

import 'dart:profiler' show
    UserTag;

import 'package:compiler/implementation/apiimpl.dart' show
    Compiler;

import 'package:compiler/compiler.dart' show
    CompilerInputProvider,
    CompilerOutputProvider,
    Diagnostic,
    DiagnosticHandler;

import 'package:compiler/implementation/dart2jslib.dart' show
    NullSink;

import 'package:compiler/implementation/js_backend/js_backend.dart' show
    JavaScriptBackend;

import 'package:compiler/implementation/elements/elements.dart' show
    LibraryElement;

part 'caching_compiler.dart';

const List<String> INCREMENTAL_OPTIONS = const <String>[
    '--disable-type-inference',
    '--incremental-support',
    '--no-source-maps', // TODO(ahe): Remove this.
];

class IncrementalCompiler {
  final Uri libraryRoot;
  final Uri packageRoot;
  final CompilerInputProvider inputProvider;
  final DiagnosticHandler diagnosticHandler;
  final List<String> options;
  final CompilerOutputProvider outputProvider;
  final Map<String, dynamic> environment;

  Compiler _compiler;

  IncrementalCompiler({
      this.libraryRoot,
      this.packageRoot,
      this.inputProvider,
      this.diagnosticHandler,
      this.options,
      this.outputProvider,
      this.environment}) {
    if (libraryRoot == null) {
      throw new ArgumentError('libraryRoot is null.');
    }
    if (inputProvider == null) {
      throw new ArgumentError('inputProvider is null.');
    }
    if (diagnosticHandler == null) {
      throw new ArgumentError('diagnosticHandler is null.');
    }
  }

  Future<bool> compile(Uri script) {
    List<String> options = new List<String>.from(this.options);
    options.addAll(INCREMENTAL_OPTIONS);
    _compiler = reuseCompiler(
        cachedCompiler: _compiler,
        libraryRoot: libraryRoot,
        packageRoot: packageRoot,
        inputProvider: inputProvider,
        diagnosticHandler: diagnosticHandler,
        options: options,
        outputProvider: outputProvider,
        environment: environment);
    return _compiler.run(script);
  }
}
