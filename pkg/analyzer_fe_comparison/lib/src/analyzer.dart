// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/generated/source.dart' show SourceKind;
import 'package:analyzer_fe_comparison/src/comparison_node.dart';

/// Analyzes the project located at [libPath] using the analyzer, and returns a
/// [ComparisonNode] representing it.
Future<ComparisonNode> driveAnalyzer(String libPath) async {
  var visitor = _AnalyzerVisitor();
  var contextCollection = AnalysisContextCollection(includedPaths: [libPath]);
  var contexts = contextCollection.contexts;
  if (contexts.length != 1) {
    throw new StateError('Expected exactly one context');
  }
  var context = contexts[0];
  var session = context.currentSession;
  var uriConverter = session.uriConverter;
  var contextRoot = context.contextRoot;
  var libraryNodes = <ComparisonNode>[];
  for (var filePath in contextRoot.analyzedFiles()) {
    var kind = await session.getSourceKind(filePath);
    if (kind == SourceKind.LIBRARY) {
      var importUri = uriConverter.pathToUri(filePath);
      var libraryElement = await session.getLibraryByUri(importUri.toString());
      var childNodes = <ComparisonNode>[];
      if (libraryElement.name.isNotEmpty) {
        childNodes.add(ComparisonNode('name=${libraryElement.name}'));
      }
      for (var compilationUnit in libraryElement.units) {
        var unitResult =
            await session.getResolvedAst(compilationUnit.source.fullName);
        for (var astNode in unitResult.unit.declarations) {
          var childNode = astNode.accept(visitor);
          if (childNode != null) {
            childNodes.add(childNode);
          }
        }
      }
      libraryNodes.add(ComparisonNode.sorted(importUri.toString(), childNodes));
    }
  }
  return ComparisonNode.sorted('Component', libraryNodes);
}

/// Visitor for serializing the contents of an analyzer AST into
/// ComparisonNodes.
class _AnalyzerVisitor extends UnifyingAstVisitor<ComparisonNode> {
  @override
  ComparisonNode visitClassDeclaration(ClassDeclaration node) {
    return ComparisonNode('Class ${node.name.name}');
  }

  @override
  ComparisonNode visitEnumDeclaration(EnumDeclaration node) {
    return ComparisonNode('Enum ${node.name.name}');
  }

  @override
  ComparisonNode visitFunctionDeclaration(FunctionDeclaration node) {
    // TODO(paulberry)
    return null;
  }

  @override
  ComparisonNode visitFunctionTypeAlias(FunctionTypeAlias node) {
    // TODO(paulberry)
    return null;
  }

  @override
  ComparisonNode visitNode(AstNode node) {
    throw new UnimplementedError('AnalyzerVisitor: ${node.runtimeType}');
  }

  @override
  ComparisonNode visitTopLevelVariableDeclaration(
      TopLevelVariableDeclaration node) {
    // TODO(paulberry)
    return null;
  }
}
