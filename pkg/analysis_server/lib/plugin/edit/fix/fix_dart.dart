// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart'
    show DartFixContextImpl;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/ast_provider_driver.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/dart/element/ast_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Complete with top-level declarations with the given [name].
 */
typedef Future<List<TopLevelDeclarationInSource>> GetTopLevelDeclarations(
    String name);

/**
 * An object used to provide context information for [DartFixContributor]s.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartFixContext implements FixContext {
  /**
   * The provider for parsed or resolved ASTs.
   */
  AstProvider get astProvider;

  /**
   * The function to get top-level declarations from.
   */
  GetTopLevelDeclarations get getTopLevelDeclarations;

  /**
   * The [CompilationUnit] to compute fixes in.
   */
  CompilationUnit get unit;
}

/**
 * A [FixContributor] that can be used to contribute fixes for errors in Dart
 * files.
 *
 * Clients may extend this class when implementing plugins.
 */
abstract class DartFixContributor implements FixContributor {
  @override
  Future<List<Fix>> computeFixes(FixContext context) async {
    AnalysisDriver driver = context.analysisDriver;
    Source source = context.error.source;
    if (!AnalysisEngine.isDartFileName(source.fullName)) {
      return Fix.EMPTY_LIST;
    }
    CompilationUnit unit = (await driver.getResult(source.fullName)).unit;
    if (unit == null) {
      return Fix.EMPTY_LIST;
    }
    DartFixContext dartContext =
        new DartFixContextImpl(context, new AstProviderForDriver(driver), unit);
    return internalComputeFixes(dartContext);
  }

  /**
   * Return a list of fixes for the given [context].
   */
  Future<List<Fix>> internalComputeFixes(DartFixContext context);
}
