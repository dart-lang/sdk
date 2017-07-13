// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer_loader;

import 'package:front_end/physical_file_system.dart';
import 'package:kernel/ast.dart' show Program;

import 'package:front_end/src/fasta/builder/builder.dart' show LibraryBuilder;

import 'package:front_end/src/fasta/target_implementation.dart'
    show TargetImplementation;

import 'package:front_end/src/fasta/source/source_class_builder.dart'
    show SourceClassBuilder;

import 'package:front_end/src/fasta/source/source_loader.dart'
    show SourceLoader;

import 'package:analyzer/src/fasta/element_store.dart' show ElementStore;

import 'analyzer_diet_listener.dart' show AnalyzerDietListener;

import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/src/incremental_class_hierarchy.dart';

class AnalyzerLoader<L> extends SourceLoader<L> {
  ElementStore elementStore;

  /// Indicates whether a kernel representation of the code should be generated.
  ///
  /// When `false`, an analyzer AST is generated, and type inference is copied
  /// over to it, but the result is not converted to a kernel representation.
  ///
  /// TODO(paulberry): remove this once "kompile" functionality is no longer
  /// needed.
  final bool generateKernel;

  /// Indicates whether a resolved AST should be generated.
  ///
  /// When `false`, an analyzer AST is generated, but none of the types or
  /// elements pointed to by the AST are guaranteed to be correct.
  ///
  /// This is needed in order to support the old "kompile" use case, since the
  /// tests of that functionality were based on the behavior prior to
  /// integrating resolution and type inference with analyzer.
  ///
  /// TODO(paulberry): remove this once "kompile" functionality is no longer
  /// needed.
  final bool doResolution;

  AnalyzerLoader(
      TargetImplementation target, this.generateKernel, this.doResolution)
      : super(PhysicalFileSystem.instance, target);

  @override
  void computeHierarchy(Program program) {
    elementStore = new ElementStore(coreLibrary, builders);
    ticker.logMs("Built analyzer element model.");
    hierarchy = new IncrementalClassHierarchy();
    ticker.logMs("Computed class hierarchy");
    coreTypes = new CoreTypes(program);
    ticker.logMs("Computed core types");
  }

  @override
  AnalyzerDietListener createDietListener(LibraryBuilder library) {
    return new AnalyzerDietListener(library, elementStore, hierarchy, coreTypes,
        typeInferenceEngine, generateKernel, doResolution);
  }

  @override
  void checkOverrides(List<SourceClassBuilder> sourceClasses) {
    // Not implemented yet. Requires [hierarchy].
  }
}
