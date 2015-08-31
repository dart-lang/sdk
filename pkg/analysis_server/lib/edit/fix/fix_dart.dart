// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.edit.fix.fix_dart;

import 'package:analysis_server/edit/fix/fix_core.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A [FixContributor] that can be used to contribute fixes for errors in Dart
 * files.
 *
 * Clients are expected to subtype this class when implementing plugins.
 */
abstract class DartFixContributor extends FixContributor {
  @override
  List<Fix> computeFixes(ResourceProvider resourceProvider,
      AnalysisContext context, AnalysisError error) {
    Source source = error.source;
    if (!AnalysisEngine.isDartFileName(source.fullName)) {
      return Fix.EMPTY_LIST;
    }
    List<Source> libraries = context.getLibrariesContaining(source);
    if (libraries.isEmpty) {
      return Fix.EMPTY_LIST;
    }
    CompilationUnit unit =
        context.resolveCompilationUnit2(source, libraries[0]);
    if (unit == null) {
      return Fix.EMPTY_LIST;
    }
    return internalComputeFixes(resourceProvider, unit, error);
  }

  /**
   * Return a list of fixes for the given [error]. The error was reported
   * against the given compilation [unit].
   */
  List<Fix> internalComputeFixes(ResourceProvider resourceProvider,
      CompilationUnit unit, AnalysisError error);
}
