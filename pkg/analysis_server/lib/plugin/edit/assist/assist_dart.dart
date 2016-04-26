// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.plugin.edit.assist.assist_dart;

import 'dart:async';

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * An object used to provide context information for [DartAssistContributor]s.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartAssistContext {
  /**
   * The [AnalysisContext] to get assists in.
   */
  AnalysisContext get analysisContext;

  /**
   * The length of the selection.
   */
  int get selectionLength;

  /**
   * The start of the selection.
   */
  int get selectionOffset;

  /**
   * The source to get assists in.
   */
  Source get source;

  /**
   * The [CompilationUnit] to compute assists in.
   */
  CompilationUnit get unit;
}

/**
 * An [AssistContributor] that can be used to contribute assists for Dart files.
 *
 * Clients may extend this class when implementing plugins.
 */
abstract class DartAssistContributor implements AssistContributor {
  @override
  Future<List<Assist>> computeAssists(AssistContext context) async {
    AnalysisContext analysisContext = context.analysisContext;
    Source source = context.source;
    if (!AnalysisEngine.isDartFileName(source.fullName)) {
      return Assist.EMPTY_LIST;
    }
    List<Source> libraries = analysisContext.getLibrariesContaining(source);
    if (libraries.isEmpty) {
      return Assist.EMPTY_LIST;
    }
    CompilationUnit unit =
        analysisContext.getResolvedCompilationUnit2(source, libraries[0]);
    if (unit == null) {
      return Assist.EMPTY_LIST;
    }
    DartAssistContext dartContext = new _DartAssistContextImpl(context, unit);
    return internalComputeAssists(dartContext);
  }

  /**
   * Completes with a list of assists for the given [context].
   */
  Future<List<Assist>> internalComputeAssists(DartAssistContext context);
}

/**
 * The implementation of [DartAssistContext].
 *
 * Clients may not extend, implement or mix-in this class.
 */
class _DartAssistContextImpl implements DartAssistContext {
  final AssistContext _context;

  /**
   * The [CompilationUnit] to compute assists in.
   */
  final CompilationUnit unit;

  _DartAssistContextImpl(this._context, this.unit);

  /**
   * The [AnalysisContext] to get assists in.
   */
  AnalysisContext get analysisContext => _context.analysisContext;

  /**
   * The length of the selection.
   */
  int get selectionLength => _context.selectionLength;

  /**
   * The start of the selection.
   */
  int get selectionOffset => _context.selectionOffset;

  /**
   * The source to get assists in.
   */
  Source get source => _context.source;
}
