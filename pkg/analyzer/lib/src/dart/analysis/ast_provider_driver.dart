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
  /**
   * Return the [AstNode] for the given [element] if the given [unit], or
   * `null` if the [element] is not know, or is not defined in the [unit].
   */
  @override
  AstNode findNodeForElement(CompilationUnit unit, Element element) {
    AstNode nameNode = new NodeLocator(element.nameOffset).searchWithin(unit);
    if (element is ClassElement) {
      if (element.isEnum) {
        return nameNode.getAncestor((node) => node is EnumDeclaration);
      } else {
        return nameNode.getAncestor(
            (node) => node is ClassDeclaration || node is ClassTypeAlias);
      }
    }
    if (element is ConstructorElement) {
      return nameNode.getAncestor((node) => node is ConstructorDeclaration);
    }
    if (element is FieldElement) {
      if (element.isEnumConstant) {
        return nameNode.getAncestor((node) => node is EnumConstantDeclaration);
      } else {
        return nameNode.getAncestor((node) => node is VariableDeclaration);
      }
    }
    if (element is FunctionElement) {
      return nameNode.getAncestor((node) => node is FunctionDeclaration);
    }
    if (element is FunctionTypeAliasElement) {
      return nameNode.getAncestor((node) => node is FunctionTypeAlias);
    }
    if (element is LocalVariableElement) {
      return nameNode.getAncestor(
          (node) => node is DeclaredIdentifier || node is VariableDeclaration);
    }
    if (element is MethodElement) {
      return nameNode.getAncestor((node) => node is MethodDeclaration);
    }
    if (element is ParameterElement) {
      return nameNode.getAncestor((node) => node is FormalParameter);
    }
    if (element is PropertyAccessorElement) {
      if (element.isSynthetic) {
        return null;
      }
      if (element.enclosingElement is ClassElement) {
        return nameNode.getAncestor((node) => node is MethodDeclaration);
      } else if (element.enclosingElement is CompilationUnitElement) {
        return nameNode.getAncestor((node) => node is FunctionDeclaration);
      }
      return null;
    }
    if (element is TopLevelVariableElement) {
      return nameNode.getAncestor((node) => node is VariableDeclaration);
    }
    return null;
  }

  @override
  Future<T> getParsedNodeForElement<T extends AstNode>(Element element) async {
    CompilationUnit unit = await getParsedUnitForElement(element);
    return findNodeForElement(unit, element) as T;
  }

  @override
  Future<T> getResolvedNodeForElement<T extends AstNode>(
      Element element) async {
    CompilationUnit unit = await getResolvedUnitForElement(element);
    return findNodeForElement(unit, element) as T;
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
