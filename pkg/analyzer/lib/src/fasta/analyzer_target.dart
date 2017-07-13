// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer_target;

import 'package:front_end/physical_file_system.dart';
import 'package:kernel/ast.dart' show Library, Source;

import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;

import 'package:front_end/src/fasta/uri_translator.dart' show UriTranslator;

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;

import 'analyzer_loader.dart' show AnalyzerLoader;

class AnalyzerTarget extends KernelTarget {
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

  AnalyzerTarget(DillTarget dillTarget, UriTranslator uriTranslator,
      bool strongMode, this.generateKernel, this.doResolution,
      [Map<String, Source> uriToSource])
      : super(PhysicalFileSystem.instance, dillTarget, uriTranslator,
            uriToSource);

  @override
  AnalyzerLoader<Library> createLoader() =>
      new AnalyzerLoader<Library>(this, generateKernel, doResolution);
}
