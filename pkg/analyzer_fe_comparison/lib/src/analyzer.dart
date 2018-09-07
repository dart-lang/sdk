// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
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
  var typeProvider = await session.typeProvider;
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
        _AnalyzerVisitor(typeProvider, childNodes)
            ._visitList(unitResult.unit.declarations);
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
  final TypeProvider _typeProvider;

  final List<ComparisonNode> _resultNodes;

  _AnalyzerVisitor(this._typeProvider, this._resultNodes);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var children = <ComparisonNode>[];
    var visitor = _AnalyzerVisitor(_typeProvider, children);
    visitor._visitTypeParameters(node.declaredElement.typeParameters);
    if (node.declaredElement.supertype != null) {
      children.add(_translateType('Extends: ', node.declaredElement.supertype));
    }
    for (int i = 0; i < node.declaredElement.mixins.length; i++) {
      children
          .add(_translateType('Mixin $i: ', node.declaredElement.mixins[i]));
    }
    for (int i = 0; i < node.declaredElement.interfaces.length; i++) {
      children.add(_translateType(
          'Implements $i: ', node.declaredElement.interfaces[i]));
    }
    visitor._visitList(node.members);
    _resultNodes
        .add(ComparisonNode.sorted('Class ${node.name.name}', children));
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var children = <ComparisonNode>[];
    var visitor = _AnalyzerVisitor(_typeProvider, children);
    visitor._visitParameters(node.parameters);
    _resultNodes.add(ComparisonNode.sorted(
        'Constructor ${node.name?.name ?? '(unnamed)'}', children));
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
    var children = <ComparisonNode>[];
    var visitor = _AnalyzerVisitor(_typeProvider, children);
    visitor._visitTypeParameters(node.declaredElement.typeParameters);
    visitor._visitParameters(node.functionExpression.parameters);
    children
        .add(_translateType('Return type: ', node.declaredElement.returnType));
    _resultNodes
        .add(ComparisonNode.sorted('$kind ${node.name.name}', children));
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _visitTypedef(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _visitTypedef(node);
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
    var children = <ComparisonNode>[];
    var visitor = _AnalyzerVisitor(_typeProvider, children);
    visitor._visitTypeParameters(node.declaredElement.typeParameters);
    visitor._visitParameters(node.parameters);
    children
        .add(_translateType('Return type: ', node.declaredElement.returnType));
    _resultNodes
        .add(ComparisonNode.sorted('$kind ${node.name.name}', children));
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
      var children = <ComparisonNode>[];
      children.add(
          _translateType('Type: ', variableDeclaration.declaredElement.type));
      // Kernel calls both fields and top level variable declarations "fields".
      _resultNodes.add(ComparisonNode.sorted(
          'Field ${variableDeclaration.name.name}', children));
    }
  }

  /// Converts the analyzer representation of a type into a ComparisonNode.
  ComparisonNode _translateType(String prefix, DartType type) {
    if (type is InterfaceType) {
      var children = <ComparisonNode>[];
      children
          .add(ComparisonNode('Library: ${type.element.librarySource.uri}'));
      for (int i = 0; i < type.typeArguments.length; i++) {
        children.add(_translateType('Type arg $i: ', type.typeArguments[i]));
      }
      return ComparisonNode('${prefix}InterfaceType ${type.name}', children);
    }
    if (type is TypeParameterType) {
      // TODO(paulberry): disambiguate if needed.
      return ComparisonNode('${prefix}TypeParameterType: ${type.name}');
    }
    if (type.isDynamic) {
      return ComparisonNode('${prefix}Dynamic');
    }
    if (type.isVoid) {
      return ComparisonNode('${prefix}Void');
    }
    if (type is FunctionType) {
      var children = <ComparisonNode>[];
      var visitor = _AnalyzerVisitor(_typeProvider, children);
      visitor._visitTypeParameters(type.typeFormals);
      int positionalParameterIndex = 0;
      for (var parameterElement in type.parameters) {
        var kind = parameterElement.isNotOptional
            ? 'Required'
            : parameterElement.isOptionalPositional ? 'Optional' : 'Named';
        var name = parameterElement.isNamed
            ? parameterElement.name
            : '${positionalParameterIndex++}';
        children.add(
            _translateType('$kind parameter $name: ', parameterElement.type));
      }
      return ComparisonNode.sorted('${prefix}FunctionType', children);
    }
    throw new UnimplementedError('_translateType: ${type.runtimeType}');
  }

  /// Visits all the nodes in [nodes].
  void _visitList(List<AstNode> nodes) {
    for (var astNode in nodes) {
      astNode.accept(this);
    }
  }

  void _visitParameters(FormalParameterList parameters) {
    var children = <ComparisonNode>[];
    // Note: parameters == null for getters
    if (parameters != null) {
      for (var parameter in parameters.parameters) {
        var element = parameter.declaredElement;
        var kind = element.isNotOptional
            ? 'Required'
            : element.isOptionalPositional ? 'Optional' : 'Named';
        var parameterChildren = <ComparisonNode>[];
        parameterChildren.add(_translateType('Type: ', element.type));
        children.add(
            ComparisonNode.sorted('$kind: ${element.name}', parameterChildren));
      }
    }
    _resultNodes.add(ComparisonNode('Parameters', children));
  }

  void _visitTypedef(TypeAlias node) {
    var children = <ComparisonNode>[];
    var visitor = _AnalyzerVisitor(_typeProvider, children);
    GenericTypeAliasElement element = node.declaredElement;
    visitor._visitTypeParameters(element.typeParameters);
    children.add(_translateType('Type: ', element.function.type));
    _resultNodes
        .add(ComparisonNode.sorted('Typedef ${node.name.name}', children));
  }

  void _visitTypeParameters(List<TypeParameterElement> typeParameters) {
    for (int i = 0; i < typeParameters.length; i++) {
      _resultNodes.add(ComparisonNode(
          'Type parameter $i: ${typeParameters[i].name}', [
        _translateType(
            'Bound: ', typeParameters[i].bound ?? _typeProvider.objectType)
      ]));
    }
  }
}
