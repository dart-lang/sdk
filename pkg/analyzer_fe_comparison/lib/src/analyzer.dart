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
          childNodes.addAll(astNode.accept(visitor));
        }
      }
      libraryNodes.add(ComparisonNode.sorted(importUri.toString(), childNodes));
    }
  }
  return ComparisonNode.sorted('Component', libraryNodes);
}

/// Visitor for serializing the contents of an analyzer AST into
/// ComparisonNodes.
class _AnalyzerVisitor extends UnifyingAstVisitor<Iterable<ComparisonNode>> {
  @override
  List<ComparisonNode> visitClassDeclaration(ClassDeclaration node) {
    return [ComparisonNode('Class ${node.name.name}')];
  }

  @override
  List<ComparisonNode> visitEnumDeclaration(EnumDeclaration node) {
    return [ComparisonNode('Enum ${node.name.name}')];
  }

  @override
  List<ComparisonNode> visitFunctionDeclaration(FunctionDeclaration node) {
    String kind;
    if (node.isGetter) {
      kind = 'Getter';
    } else if (node.isSetter) {
      kind = 'Setter';
    } else {
      // Kernel calls top level functions "methods".
      kind = 'Method';
    }
    return [ComparisonNode('$kind ${node.name.name}')];
  }

  @override
  List<ComparisonNode> visitFunctionTypeAlias(FunctionTypeAlias node) {
    return [ComparisonNode('Typedef ${node.name.name}')];
  }

  @override
  Null visitNode(AstNode node) {
    throw new UnimplementedError('AnalyzerVisitor: ${node.runtimeType}');
  }

  @override
  Iterable<ComparisonNode> visitTopLevelVariableDeclaration(
      TopLevelVariableDeclaration node) sync* {
    for (var variableDeclaration in node.variables.variables) {
      // Kernel calls top level variable declarations "fields".
      yield ComparisonNode('Field ${variableDeclaration.name.name}');
    }
  }
}
