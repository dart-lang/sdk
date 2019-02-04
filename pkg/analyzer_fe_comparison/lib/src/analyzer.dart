// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/analysis/uri_converter.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart' show SourceKind;
import 'package:analyzer_fe_comparison/src/comparison_node.dart';

/// Analyzes the files in [filePaths] using the analyzer, and returns a
/// [ComparisonNode] representing them.
Future<ComparisonNode> analyzeFiles(
    String startingPath, List<String> filePaths) async {
  var driver = await _AnalyzerDriver.create(startingPath);
  return driver.analyzeFiles(filePaths);
}

/// Analyzes the package located at [libPath] using the analyzer, and returns a
/// [ComparisonNode] representing it.
Future<ComparisonNode> analyzePackage(String libPath) async {
  var driver = await _AnalyzerDriver.create(libPath);
  return driver.analyzePackage();
}

class _AnalyzerDriver {
  final AnalysisSession _session;

  final TypeProvider _typeProvider;

  final UriConverter _uriConverter;

  final ContextRoot _contextRoot;

  _AnalyzerDriver._(
      this._session, this._typeProvider, this._uriConverter, this._contextRoot);

  Future<ComparisonNode> analyzeFiles(Iterable<String> filePaths) async {
    var libraryNodes = <ComparisonNode>[];
    for (var filePath in filePaths) {
      var kind = await _session.getSourceKind(filePath);
      if (kind == SourceKind.LIBRARY) {
        var importUri = _uriConverter.pathToUri(filePath);
        var libraryElement =
            await _session.getLibraryByUri(importUri.toString());
        var childNodes = <ComparisonNode>[];
        if (libraryElement.name.isNotEmpty) {
          childNodes.add(ComparisonNode('name=${libraryElement.name}'));
        }
        for (var compilationUnit in libraryElement.units) {
          var unitResult =
              await _session.getResolvedAst(compilationUnit.source.fullName);
          _AnalyzerVisitor(_typeProvider, childNodes)
              ._visitList(unitResult.unit.declarations);
        }
        libraryNodes
            .add(ComparisonNode.sorted(importUri.toString(), childNodes));
      }
    }
    return ComparisonNode.sorted('Component', libraryNodes);
  }

  Future<ComparisonNode> analyzePackage() async {
    return analyzeFiles(_contextRoot.analyzedFiles());
  }

  static Future<_AnalyzerDriver> create(String startingPath) async {
    var contextCollection =
        AnalysisContextCollection(includedPaths: [startingPath]);
    var contexts = contextCollection.contexts;
    if (contexts.length != 1) {
      throw new StateError('Expected exactly one context');
    }
    var context = contexts[0];
    var session = context.currentSession;
    var typeProvider = await session.typeProvider;
    var uriConverter = session.uriConverter;
    var contextRoot = context.contextRoot;
    return _AnalyzerDriver._(session, typeProvider, uriConverter, contextRoot);
  }
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
    visitor._handleClassOrClassTypeAlias(node.declaredElement);
    visitor._visitList(node.members);
    _resultNodes
        .add(ComparisonNode.sorted('Class ${node.name.name}', children));
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    var children = <ComparisonNode>[];
    var visitor = _AnalyzerVisitor(_typeProvider, children);
    visitor._handleClassOrClassTypeAlias(node.declaredElement);
    _resultNodes.add(
        ComparisonNode.sorted('MixinApplication ${node.name.name}', children));
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
    var name = node.name.name;
    String kind;
    if (node.isGetter) {
      kind = 'Getter';
    } else if (node.isSetter) {
      kind = 'Setter';
    } else if (node.isOperator) {
      kind = 'Operator';
      if (name == '-' && node.declaredElement.parameters.isEmpty) {
        name = 'unary-';
      }
    } else {
      kind = 'Method';
    }
    var children = <ComparisonNode>[];
    var visitor = _AnalyzerVisitor(_typeProvider, children);
    visitor._visitTypeParameters(node.declaredElement.typeParameters);
    visitor._visitParameters(node.parameters);
    children
        .add(_translateType('Return type: ', node.declaredElement.returnType));
    _resultNodes.add(ComparisonNode.sorted('$kind $name', children));
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    // At present, kernel doesn't distinguish between mixin and class
    // declarations.  So treat the mixin as a class.
    var children = <ComparisonNode>[];
    var visitor = _AnalyzerVisitor(_typeProvider, children);
    visitor._handleClassOrClassTypeAlias(node.declaredElement);
    visitor._visitList(node.members);
    _resultNodes
        .add(ComparisonNode.sorted('Mixin ${node.name.name}', children));
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

  void _handleClassOrClassTypeAlias(ClassElement element) {
    _visitTypeParameters(element.typeParameters);
    if (element.isMixin) {
      for (int i = 0; i < element.superclassConstraints.length; i++) {
        _resultNodes
            .add(_translateType('On $i: ', element.superclassConstraints[i]));
      }
    } else {
      if (element.supertype != null) {
        _resultNodes.add(_translateType('Extends: ', element.supertype));
      }
      for (int i = 0; i < element.mixins.length; i++) {
        _resultNodes.add(_translateType('Mixin $i: ', element.mixins[i]));
      }
    }
    for (int i = 0; i < element.interfaces.length; i++) {
      _resultNodes
          .add(_translateType('Implements $i: ', element.interfaces[i]));
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
      children.add(_translateType('Return type: ', type.returnType));
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
