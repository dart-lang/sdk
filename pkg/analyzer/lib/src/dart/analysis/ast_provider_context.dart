// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/ast_provider_driver.dart';
import 'package:analyzer/src/dart/element/ast_provider.dart';
import 'package:analyzer/src/generated/engine.dart';

/**
 * [AstProvider] implementation for [AnalysisContext].
 */
class AstProviderForContext extends AbstractAstProvider {
  final AnalysisContext context;

  AstProviderForContext(this.context);

  @override
  Future<CompilationUnit> getParsedUnitForElement(Element element) async {
    return context.parseCompilationUnit(element.source);
  }

  @override
  Future<CompilationUnit> getResolvedUnitForElement(Element element) async {
    return context.getResolvedCompilationUnit2(
        element.source, element.librarySource);
  }
}
