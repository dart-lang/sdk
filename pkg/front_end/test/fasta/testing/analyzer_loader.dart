// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer_loader;

import 'package:front_end/src/api_prototype/standard_file_system.dart'
    show StandardFileSystem;

import 'package:front_end/src/fasta/builder/builder.dart' show LibraryBuilder;

import 'package:front_end/src/fasta/source/source_class_builder.dart'
    show SourceClassBuilder;

import 'package:front_end/src/fasta/source/source_loader.dart'
    show SourceLoader;

import 'package:front_end/src/fasta/target_implementation.dart'
    show TargetImplementation;

import 'analyzer_diet_listener.dart' show AnalyzerDietListener;

class AnalyzerLoader<L> extends SourceLoader<L> {
  AnalyzerLoader(TargetImplementation target)
      : super(StandardFileSystem.instance, false, target);

  @override
  AnalyzerDietListener createDietListener(LibraryBuilder library) {
    return new AnalyzerDietListener(
        library, hierarchy, coreTypes, typeInferenceEngine);
  }

  @override
  void checkOverrides(List<SourceClassBuilder> sourceClasses) {
    // Not implemented yet. Requires [hierarchy].
  }
}
