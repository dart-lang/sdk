// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_incremental;

import 'dart:async' show
    EventSink,
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
    IncrementalCompilerContext,
    LibraryUpdater,
    Logger;

import 'package:compiler/src/js/js.dart' as jsAst;

part 'caching_compiler.dart';

const List<String> INCREMENTAL_OPTIONS = const <String>[
    '--disable-type-inference',
    '--incremental-support',
    '--generate-code-with-compile-time-errors',
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
  final IncrementalCompilerContext _context = new IncrementalCompilerContext();

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
    if (outputProvider == null) {
      throw new ArgumentError('outputProvider is null.');
    }
    if (diagnosticHandler == null) {
      throw new ArgumentError('diagnosticHandler is null.');
    }
    _context.incrementalCompiler = this;
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
        logTime,
        logVerbose,
        _context);
    _context.registerUriWithUpdates(updatedFiles.keys);
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

    JavaScriptBackend backend = _compiler.backend;

    jsAst.FunctionDeclaration mainRunner = jsAst.js.statement(r"""
function dartMainRunner(main, args) {
  #helper.patch(#updates + "\n//# sourceURL=initial_patch.js\n");
  return main(args);
}""", {'updates': updates, 'helper': backend.namer.accessIncrementalHelper});

    jsAst.Printer printer = new jsAst.Printer(_compiler, null);
    printer.blockOutWithoutBraces(mainRunner);
    return printer.outBuffer.getText();
  }
}

class IncrementalCompilationFailed {
  final String reason;

  const IncrementalCompilationFailed(this.reason);

  String toString() => "Can't incrementally compile program.\n\n$reason";
}
