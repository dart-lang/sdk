// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:kernel/kernel.dart'
    show Component, Procedure, DartType, TypeParameter;

import '../base/processed_options.dart' show ProcessedOptions;

import '../fasta/compiler_context.dart' show CompilerContext;

import '../fasta/incremental_compiler.dart' show IncrementalCompiler;

import '../fasta/scanner/string_scanner.dart' show StringScanner;

import 'compiler_options.dart' show CompilerOptions;

abstract class IncrementalKernelGenerator {
  factory IncrementalKernelGenerator(CompilerOptions options, Uri entryPoint,
      [Uri initializeFromDillUri, bool outlineOnly]) {
    return new IncrementalCompiler(
        new CompilerContext(
            new ProcessedOptions(options: options, inputs: [entryPoint])),
        initializeFromDillUri,
        outlineOnly);
  }

  /// Initialize the incremental compiler from a component.
  ///
  /// Notice that the component has to include the platform, and that no other
  /// platform will be loaded.
  factory IncrementalKernelGenerator.fromComponent(
      CompilerOptions options, Uri entryPoint, Component component,
      [bool outlineOnly]) {
    return new IncrementalCompiler.fromComponent(
        new CompilerContext(
            new ProcessedOptions(options: options, inputs: [entryPoint])),
        component,
        outlineOnly);
  }

  /// Returns a component whose libraries are the recompiled libraries,
  /// or - in the case of [fullComponent] - a full Component.
  Future<Component> computeDelta({List<Uri> entryPoints, bool fullComponent});

  /// Remove the file associated with the given file [uri] from the set of
  /// valid files.  This guarantees that those files will be re-read on the
  /// next call to [computeDelta]).
  void invalidate(Uri uri);

  /// Invalidate all libraries that were build from source.
  ///
  /// This is equivalent to a number of calls to [invalidate]: One for each URI
  /// that happens to have been read from source.
  /// Said another way, this invalidates everything not loaded from dill
  /// (at startup) or via [setModulesToLoadOnNextComputeDelta].
  void invalidateAllSources();

  /// Set the given [components] as components to load on the next iteration
  /// of [computeDelta].
  ///
  /// If specified, all libraries not compiled from source and not included in
  /// these components will be invalidated and the libraries inside these
  /// components will be loaded instead.
  ///
  /// Useful for, for instance, modular compilation, where modules
  /// (created externally) via this functionality can be added, changed or
  /// removed.
  void setModulesToLoadOnNextComputeDelta(List<Component> components);

  /// Compile [expression] as an [Expression]. A function returning that
  /// expression is compiled.
  ///
  /// [expression] may use the variables supplied in [definitions] as free
  /// variables and [typeDefinitions] as free type variables. These will become
  /// required parameters to the compiled function. All elements of
  /// [definitions] and [typeDefinitions] will become parameters/type
  /// parameters, whether or not they appear free in [expression]. The type
  /// parameters should have a null parent pointer.
  ///
  /// [libraryUri] must refer to either a previously compiled library.
  /// [className] may optionally refer to a class within such library to use for
  /// the scope of the expression. In that case, [isStatic] indicates whether
  /// the scope can access [this].
  ///
  /// It is illegal to use "await" in [expression] and the compiled function
  /// will always be synchronous.
  ///
  /// [computeDelta] must have been called at least once prior.
  ///
  /// [compileExpression] will return [null] if the library or class for
  /// [enclosingNode] could not be found. Otherwise, errors are reported in the
  /// normal way.
  Future<Procedure> compileExpression(
      String expression,
      Map<String, DartType> definitions,
      List<TypeParameter> typeDefinitions,
      String syntheticProcedureName,
      Uri libraryUri,
      [String className,
      bool isStatic = false]);
}

bool isLegalIdentifier(String identifier) {
  return StringScanner.isLegalIdentifier(identifier);
}
