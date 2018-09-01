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
        _AnalyzerVisitor(childNodes)._visitList(unitResult.unit.declarations);
      }
      libraryNodes.add(ComparisonNode.sorted(importUri.toString(), childNodes));
    }
  }
  return ComparisonNode.sorted('Component', libraryNodes);
}

/// Visitor for serializing the contents of an analyzer AST into
/// ComparisonNodes.
///
/// Results are accumulated into [_resultNodes].
class _AnalyzerVisitor extends UnifyingAstVisitor<void> {
  final List<ComparisonNode> _resultNodes;

  _AnalyzerVisitor(this._resultNodes);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var children = <ComparisonNode>[];
    _AnalyzerVisitor(children)._visitList(node.members);
    _resultNodes
        .add(ComparisonNode.sorted('Class ${node.name.name}', children));
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _resultNodes
        .add(ComparisonNode('Constructor ${node.name?.name ?? '(unnamed)'}'));
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    var children = <ComparisonNode>[];
    for (var enumValue in node.constants) {
      children.add(ComparisonNode('EnumValue ${enumValue.name.name}'));
    }
    _resultNodes.add(ComparisonNode.sorted('Enum ${node.name.name}', children));
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    node.fields.accept(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    String kind;
    if (node.isGetter) {
      kind = 'Getter';
    } else if (node.isSetter) {
      kind = 'Setter';
    } else {
      // Kernel calls top level functions "methods".
      kind = 'Method';
    }
    _resultNodes.add(ComparisonNode('$kind ${node.name.name}'));
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _resultNodes.add(ComparisonNode('Typedef ${node.name.name}'));
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    String kind;
    if (node.isGetter) {
      kind = 'Getter';
    } else if (node.isSetter) {
      kind = 'Setter';
    } else if (node.isOperator) {
      kind = 'Operator';
    } else {
      kind = 'Method';
    }
    _resultNodes.add(ComparisonNode('$kind ${node.name.name}'));
  }

  @override
  Null visitNode(AstNode node) {
    throw new UnimplementedError('AnalyzerVisitor: ${node.runtimeType}');
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.variables.accept(this);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    for (var variableDeclaration in node.variables) {
      // Kernel calls both fields and top level variable declarations "fields".
      _resultNodes
          .add(ComparisonNode('Field ${variableDeclaration.name.name}'));
    }
  }

  /// Visits all the nodes in [nodes].
  void _visitList(List<AstNode> nodes) {
    for (var astNode in nodes) {
      astNode.accept(this);
    }
  }
}
