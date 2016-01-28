// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_incremental;

import 'dart:async' show
    EventSink,
    Future;

import 'dart:developer' show
    UserTag;

import 'package:compiler/src/apiimpl.dart' show
    CompilerImpl;

import 'package:compiler/compiler_new.dart' show
    CompilerDiagnostics,
    CompilerInput,
    CompilerOutput,
    Diagnostic;

import 'package:compiler/src/null_compiler_output.dart' show
    NullCompilerOutput;

import 'package:compiler/src/js_backend/js_backend.dart' show
    JavaScriptBackend;

import 'package:compiler/src/js_emitter/full_emitter/emitter.dart'
    as full show Emitter;

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
  final CompilerInput inputProvider;
  final CompilerDiagnostics diagnosticHandler;
  final List<String> options;
  final CompilerOutput outputProvider;
  final Map<String, dynamic> environment;
  final List<String> _updates = <String>[];
  final IncrementalCompilerContext _context = new IncrementalCompilerContext();

  CompilerImpl _compiler;

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

  CompilerImpl get compiler => _compiler;

  Future<bool> compile(Uri script) {
    return _reuseCompiler(null).then((CompilerImpl compiler) {
      _compiler = compiler;
      return compiler.run(script);
    });
  }

  Future<CompilerImpl> _reuseCompiler(
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
      return inputProvider.readFromUri(updatedFile == null ? uri : updatedFile);
    }
    LibraryUpdater updater = new LibraryUpdater(
        _compiler,
        mappingInputProvider,
        logTime,
        logVerbose,
        _context);
    _context.registerUriWithUpdates(updatedFiles.keys);
    Future<CompilerImpl> future = _reuseCompiler(updater.reuseLibrary);
    return future.then((CompilerImpl compiler) {
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

    return jsAst.prettyPrint(mainRunner, _compiler).getText();
  }
}

class IncrementalCompilationFailed {
  final String reason;

  const IncrementalCompilationFailed(this.reason);

  String toString() => "Can't incrementally compile program.\n\n$reason";
}
