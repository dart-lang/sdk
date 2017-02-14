// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/ast_provider.dart';

abstract class AbstractAstProvider implements AstProvider {
  @override
  Future<SimpleIdentifier> getParsedNameForElement(Element element) async {
    CompilationUnit unit = await getParsedUnitForElement(element);
    return _getNameNode(unit, element);
  }

  @override
  Future<SimpleIdentifier> getResolvedNameForElement(Element element) async {
    CompilationUnit unit = await getResolvedUnitForElement(element);
    return _getNameNode(unit, element);
  }

  SimpleIdentifier _getNameNode(CompilationUnit unit, Element element) {
    int nameOffset = element.nameOffset;
    if (nameOffset == -1) {
      return null;
    }
    AstNode nameNode = new NodeLocator(nameOffset).searchWithin(unit);
    if (nameNode is SimpleIdentifier) {
      return nameNode;
    }
    return null;
  }
}

/**
 * [AstProvider] implementation for [AnalysisDriver].
 */
class AstProviderForDriver extends AbstractAstProvider {
  final AnalysisDriver driver;

  AstProviderForDriver(this.driver);

  @override
  Future<CompilationUnit> getParsedUnitForElement(Element element) async {
    String path = element.source.fullName;
    ParseResult parseResult = await driver.parseFile(path);
    return parseResult.unit;
  }

  @override
  Future<CompilationUnit> getResolvedUnitForElement(Element element) async {
    String path = element.source.fullName;
    AnalysisResult analysisResult = await driver.getResult(path);
    return analysisResult?.unit;
  }
}
