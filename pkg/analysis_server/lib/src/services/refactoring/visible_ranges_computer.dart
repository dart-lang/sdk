// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Computer of local elements and source ranges in which they are visible.
class VisibleRangesComputer extends GeneralizingAstVisitor<void> {
  final Map<LocalElement, SourceRange> _map = {};

  @override
  void visitCatchClause(CatchClause node) {
    _addLocalVariable(node, node.exceptionParameter?.staticElement);
    _addLocalVariable(node, node.stackTraceParameter?.staticElement);
    node.body.accept(this);
  }

  @override
  void visitFormalParameter(FormalParameter node) {
    var element = node.declaredElement;
    if (element is ParameterElement) {
      var body = _getFunctionBody(node);
      if (body is BlockFunctionBody || body is ExpressionFunctionBody) {
        _map[element] = range.node(body);
      }
    }
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    var loop = node.parent;
    for (var variable in node.variables.variables) {
      _addLocalVariable(loop, variable.declaredElement);
      variable.initializer?.accept(this);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var block = node.parent?.parent;
    if (block is Block) {
      var element = node.declaredElement as FunctionElement;
      _map[element] = range.node(block);
    }

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    var block = node.parent;
    for (var variable in node.variables.variables) {
      _addLocalVariable(block, variable.declaredElement);
      variable.initializer?.accept(this);
    }
  }

  void _addLocalVariable(AstNode scopeNode, Element element) {
    if (element is LocalVariableElement) {
      _map[element] = range.node(scopeNode);
    }
  }

  static Map<LocalElement, SourceRange> forNode(AstNode unit) {
    var computer = VisibleRangesComputer();
    unit.accept(computer);
    return computer._map;
  }

  /// Return the body of the function that contains the given [parameter], or
  /// `null` if no function body could be found.
  static FunctionBody _getFunctionBody(FormalParameter parameter) {
    var parent = parameter?.parent?.parent;
    if (parent is ConstructorDeclaration) {
      return parent.body;
    } else if (parent is FunctionExpression) {
      return parent.body;
    } else if (parent is MethodDeclaration) {
      return parent.body;
    }
    return null;
  }
}
