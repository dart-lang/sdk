// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/ast_provider_driver.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/element/ast_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * An object used to provide context information for [DartAssistContributor]s.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartAssistContext {
  /**
   * The analysis driver used to access analysis results.
   */
  AnalysisDriver get analysisDriver;

  /**
   * The provider for parsed or resolved ASTs.
   */
  AstProvider get astProvider;

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
    AnalysisDriver driver = context.analysisDriver;
    Source source = context.source;
    if (!AnalysisEngine.isDartFileName(source.fullName)) {
      return Assist.EMPTY_LIST;
    }
    CompilationUnit unit = (await driver.getResult(source.fullName)).unit;
    if (unit == null) {
      return Assist.EMPTY_LIST;
    }
    DartAssistContext dartContext = new _DartAssistContextImpl(
        new AstProviderForDriver(driver), context, unit);
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
  @override
  final AstProvider astProvider;

  final AssistContext _context;

  @override
  final CompilationUnit unit;

  _DartAssistContextImpl(this.astProvider, this._context, this.unit);

  @override
  AnalysisDriver get analysisDriver => _context.analysisDriver;

  @override
  int get selectionLength => _context.selectionLength;

  @override
  int get selectionOffset => _context.selectionOffset;

  @override
  Source get source => _context.source;
}
