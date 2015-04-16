// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.edit.assist.assist_dart;

import 'package:analysis_server/edit/assist/assist_core.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * An [AssistContributor] that can be used to contribute assists for Dart
 * files.
 */
abstract class DartAssistContributor extends AssistContributor {
  @override
  List<Assist> computeAssists(
      AnalysisContext context, Source source, int offset, int length) {
    if (!AnalysisEngine.isDartFileName(source.fullName)) {
      return Assist.EMPTY_LIST;
    }
    List<Source> libraries = context.getLibrariesContaining(source);
    if (libraries.isEmpty) {
      return Assist.EMPTY_LIST;
    }
    CompilationUnit unit =
        context.resolveCompilationUnit2(source, libraries[0]);
    if (unit == null) {
      return Assist.EMPTY_LIST;
    }
    return internalComputeAssists(unit, offset, length);
  }

  /**
   * Return a list of assists for a location in the given [source]. The location
   * is specified by the [offset] and [length] of the selected region. The
   * [context] can be used to get additional information that is useful for
   * computing assists.
   */
  List<Assist> internalComputeAssists(
      CompilationUnit unit, int offset, int length);
}
