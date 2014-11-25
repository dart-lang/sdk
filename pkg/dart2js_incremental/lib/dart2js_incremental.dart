// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_incremental;

import 'dart:async' show
    Future;

import 'dart:profiler' show
    UserTag;

import 'package:compiler/src/apiimpl.dart' show
    Compiler;

import 'package:compiler/compiler.dart' show
    CompilerInputProvider,
    CompilerOutputProvider,
    Diagnostic,
    DiagnosticHandler;

import 'package:compiler/src/dart2jslib.dart' show
    NullSink;

import 'package:compiler/src/js_backend/js_backend.dart' show
    JavaScriptBackend;

import 'package:compiler/src/elements/elements.dart' show
    LibraryElement;

import 'library_updater.dart' show
    LibraryUpdater,
    Logger;

import 'package:compiler/src/js/js.dart' as jsAst;

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
  final List<String> _updates = <String>[];

  Compiler _compiler;

  bool get compilerWasCancelled => _compiler.compilerWasCancelled;

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

  LibraryElement get mainApp => _compiler.mainApp;

  Compiler get compiler => _compiler;

  Future<bool> compile(Uri script) {
    return _reuseCompiler(null).then((Compiler compiler) {
      _compiler = compiler;
      return compiler.run(script);
    });
  }

  Future<Compiler> _reuseCompiler(
      Future<bool> reuseLibrary(LibraryElement library)) {
    List<String> options = this.options == null
        ? <String> [] : new List<String>.from(this.options);
    options.addAll(INCREMENTAL_OPTIONS);
    return reuseCompiler(
        cachedCompiler: _compiler,
        libraryRoot: libraryRoot,
        packageRoot: packageRoot,
        inputProvider: inputProvider,
        diagnosticHandler: diagnosticHandler,
        options: options,
        outputProvider: outputProvider,
        environment: environment,
        reuseLibrary: reuseLibrary);
  }

  Future<String> compileUpdates(
      Map<Uri, Uri> updatedFiles,
      {Logger logTime,
       Logger logVerbose}) {
    if (logTime == null) {
      logTime = (_) {};
    }
    if (logVerbose == null) {
      logVerbose = (_) {};
    }
    Future mappingInputProvider(Uri uri) {
      Uri updatedFile = updatedFiles[uri];
      return inputProvider(updatedFile == null ? uri : updatedFile);
    }
    LibraryUpdater updater = new LibraryUpdater(
        _compiler,
        mappingInputProvider,
        _compiler.mainApp.canonicalUri,
        logTime,
        logVerbose);
    Future<Compiler> future = _reuseCompiler(updater.reuseLibrary);
    return future.then((Compiler compiler) {
      _compiler = compiler;
      if (compiler.compilationFailed) {
        return null;
      } else {
        String update = updater.computeUpdateJs();
        _updates.add(update);
        return update;
      }
    });
  }

  String allUpdates() {
    jsAst.Node updates = jsAst.js.escapedString(_updates.join(""));

    jsAst.FunctionDeclaration mainRunner = jsAst.js.statement(r"""
function dartMainRunner(main, args) {
  $dart_unsafe_eval.patch(#);
  return main(args);
}""", updates);


    jsAst.Printer printer = new jsAst.Printer(_compiler, null);
    printer.blockOutWithoutBraces(mainRunner);
    return printer.outBuffer.getText();
  }
}
