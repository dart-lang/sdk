// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/incremental_resolved_ast_generator.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/base/source.dart';
import 'package:front_end/src/incremental_resolved_ast_generator_impl.dart';
import 'package:analyzer/src/kernel/loader.dart';
import 'package:kernel/kernel.dart' hide Source;

dynamic unimplemented() {
  // TODO(paulberry): get rid of this.
  throw new UnimplementedError();
}

DartOptions _convertOptions(ProcessedOptions options) {
  // TODO(paulberry): make sure options.compileSdk is handled correctly.
  return new DartOptions(
      strongMode: true, // TODO(paulberry): options.strongMode,
      sdk: null, // TODO(paulberry): _uriToPath(options.sdkRoot, options),
      sdkSummary:
          null, // TODO(paulberry): options.compileSdk ? null : _uriToPath(options.sdkSummary, options),
      packagePath:
          null, // TODO(paulberry): _uriToPath(options.packagesFileUri, options),
      declaredVariables: null // TODO(paulberry): options.declaredVariables
      );
}

/// Implementation of [IncrementalKernelGenerator].
///
/// Theory of operation: an instance of [IncrementalResolvedAstGenerator] is
/// used to obtain resolved ASTs, and these are fed into kernel code generation
/// logic.
///
/// Note that the kernel doesn't expect to take resolved ASTs as a direct input;
/// it expects to request resolved ASTs from an [AnalysisContext].  To deal with
/// this, we create [_AnalysisContextProxy] which returns the resolved ASTs when
/// requested.  TODO(paulberry): Make this unnecessary.
class IncrementalKernelGeneratorImpl implements IncrementalKernelGenerator {
  final IncrementalResolvedAstGenerator _resolvedAstGenerator;
  final ProcessedOptions _options;

  IncrementalKernelGeneratorImpl(Uri source, ProcessedOptions options)
      : _resolvedAstGenerator =
            new IncrementalResolvedAstGeneratorImpl(source, options),
        _options = options;

  @override
  Future<DeltaProgram> computeDelta(
      {Future<Null> watch(Uri uri, bool used)}) async {
    var deltaLibraries = await _resolvedAstGenerator.computeDelta();
    var kernelOptions = _convertOptions(_options);
    var packages = null; // TODO(paulberry)
    var kernels = <Uri, Program>{};
    for (Uri uri in deltaLibraries.newState.keys) {
      // The kernel generation code doesn't currently support building a kernel
      // directly from resolved ASTs--it wants to query an analysis context.  So
      // we provide it with a proxy analysis context that feeds it the resolved
      // ASTs.
      var strongMode = true; // TODO(paulberry): set this correctly
      var analysisOptions = new _AnalysisOptionsProxy(strongMode);
      var context =
          new _AnalysisContextProxy(deltaLibraries.newState, analysisOptions);
      var program = new Program();
      var loader =
          new DartLoader(program, kernelOptions, packages, context: context);
      loader.loadLibrary(uri);
      kernels[uri] = program;
      // TODO(paulberry) rework watch invocation to eliminate race condition,
      // include part source files, and prevent watch from being a bottleneck
      if (watch != null) await watch(uri, true);
    }
    // TODO(paulberry) invoke watch with used=false for each unused source
    return new DeltaProgram(kernels);
  }

  @override
  void invalidate(String path) => _resolvedAstGenerator.invalidate(path);

  @override
  void invalidateAll() => _resolvedAstGenerator.invalidateAll();
}

class _AnalysisContextProxy implements AnalysisContext {
  final Map<Uri, Map<Uri, CompilationUnit>> _resolvedLibraries;

  @override
  final _SourceFactoryProxy sourceFactory = new _SourceFactoryProxy();

  @override
  final AnalysisOptions analysisOptions;

  _AnalysisContextProxy(this._resolvedLibraries, this.analysisOptions);

  List<AnalysisError> computeErrors(Source source) {
    // TODO(paulberry): do we need to return errors sometimes?
    return [];
  }

  LibraryElement computeLibraryElement(Source source) {
    assert(_resolvedLibraries.containsKey(source.uri));
    return resolutionMap
        .elementDeclaredByCompilationUnit(
            _resolvedLibraries[source.uri][source.uri])
        .library;
  }

  noSuchMethod(Invocation invocation) => unimplemented();

  CompilationUnit resolveCompilationUnit(
      Source unitSource, LibraryElement library) {
    var unit = _resolvedLibraries[library.source.uri][unitSource.uri];
    assert(unit != null);
    return unit;
  }
}

class _AnalysisOptionsProxy implements AnalysisOptions {
  final bool strongMode;

  _AnalysisOptionsProxy(this.strongMode);

  noSuchMethod(Invocation invocation) => unimplemented();
}

class _SourceFactoryProxy implements SourceFactory {
  Source forUri2(Uri absoluteUri) => new _SourceProxy(absoluteUri);

  noSuchMethod(Invocation invocation) => unimplemented();
}

class _SourceProxy extends BasicSource {
  _SourceProxy(Uri uri) : super(uri);

  noSuchMethod(Invocation invocation) => unimplemented();
}
