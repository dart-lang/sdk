// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:kernel/kernel.dart'
    show Component, DartType, NamedNode, Procedure, TypeParameter;

import '../base/processed_options.dart' show ProcessedOptions;

import '../fasta/compiler_context.dart' show CompilerContext;

import '../fasta/incremental_compiler.dart' show IncrementalCompiler;

import '../fasta/scanner/string_scanner.dart' show StringScanner;

import 'compiler_options.dart' show CompilerOptions;

/// Identifies a position in the source program for expression compilation.
///
/// Currently this can be either a library-scope or a class-scope. This object
/// may also contain references to FE-internal datastructures, so it is
/// invalidated by any changes to the Kernel program.
abstract class CompilationPosition {
  final NamedNode kernelNode = null;
}

abstract class IncrementalKernelGenerator {
  factory IncrementalKernelGenerator(CompilerOptions options, Uri entryPoint,
      [Uri bootstrapDill]) {
    return new IncrementalCompiler(
        new CompilerContext(new ProcessedOptions(options, false, [entryPoint])),
        bootstrapDill);
  }

  /// Returns a component whose libraries are the recompiled libraries,
  /// or - in the case of [fullComponent] - a full Component.
  Future<Component> computeDelta({Uri entryPoint, bool fullComponent});

  /// Remove the file associated with the given file [uri] from the set of
  /// valid files.  This guarantees that those files will be re-read on the
  /// next call to [computeDelta]).
  void invalidate(Uri uri);

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
  /// [enclosingNode] must refer to either a [Library] or a [Class] in which
  /// scope [expression] is compiled. If it refers to a [Class], the flag
  /// [isStatic] determines whether [expression] may reference "this".
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
      CompilationPosition position,
      [bool isStatic = false]);

  /// Finds the [CompilationPosition] referenced by [library] and optionally
  /// [class].
  CompilationPosition resolveCompilationPosition(Uri library,
      [String className]);
}

bool isLegalIdentifier(String identifier) {
  return StringScanner.isLegalIdentifier(identifier);
}
