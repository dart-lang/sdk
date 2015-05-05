// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.analysis.index.index_dart;

import 'package:analysis_server/analysis/index/index_core.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * An [IndexContributor] that can be used to contribute relationships for Dart
 * files.
 *
 * Clients are expected to subtype this class when implementing plugins.
 */
abstract class DartIndexContributor extends IndexContributor {
  @override
  void contributeTo(IndexStore store, AnalysisContext context, Source source) {
    if (!AnalysisEngine.isDartFileName(source.fullName)) {
      return;
    }
    List<Source> libraries = context.getLibrariesContaining(source);
    if (libraries.isEmpty) {
      return;
    }
    libraries.forEach((Source library) {
      CompilationUnit unit = context.resolveCompilationUnit2(source, library);
      if (unit != null) {
        internalContributeTo(store, unit);
      }
    });
  }

  /**
   * Contribute relationships to the given index [store] based on the given
   * fully resolved compilation[unit].
   */
  void internalContributeTo(IndexStore store, CompilationUnit unit);
}
