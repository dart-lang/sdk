// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Computer of local elements and source ranges in which they are visible.
class VisibleRangesComputer extends GeneralizingAstVisitor<void> {
  final Map<LocalElement, SourceRange> _map = {};

  final Map<PromotableElement2, SourceRange> _map2 = {};

  @override
  void visitCatchClause(CatchClause node) {
    _addLocalVariable(
      node,
      node.exceptionParameter?.declaredElement,
      node.exceptionParameter?.declaredElement2,
    );
    _addLocalVariable(
      node,
      node.stackTraceParameter?.declaredElement,
      node.stackTraceParameter?.declaredElement2,
    );
    node.body.accept(this);
  }

  @override
  void visitFormalParameter(FormalParameter node) {
    var element = node.declaredElement;
    if (element is ParameterElement) {
      var body = _getFunctionBody(node);
      if (body is BlockFunctionBody) {
        _map[element] = range.node(body);
      } else if (body is ExpressionFunctionBody) {
        _map[element] = range.node(body);
      }
    }

    var element2 = node.declaredFragment?.element;
    if (element2 is FormalParameterElement) {
      var body = _getFunctionBody(node);
      if (body is BlockFunctionBody) {
        _map2[element2] = range.node(body);
      } else if (body is ExpressionFunctionBody) {
        _map2[element2] = range.node(body);
      }
    }
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    var loop = node.parent;
    if (loop != null) {
      for (var variable in node.variables.variables) {
        _addLocalVariable(
          loop,
          variable.declaredElement,
          variable.declaredElement2,
        );
        variable.initializer?.accept(this);
      }
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
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    // TODO(brianwilkerson): Figure out why this isn't handled.
    super.visitPatternVariableDeclaration(node);
  }

  @override
  void visitPatternVariableDeclarationStatement(
    PatternVariableDeclarationStatement node,
  ) {
    // TODO(brianwilkerson): Figure out why this isn't handled.
    super.visitPatternVariableDeclarationStatement(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    var block = node.parent;
    if (block != null) {
      for (var variable in node.variables.variables) {
        _addLocalVariable(
          block,
          variable.declaredElement,
          variable.declaredElement2,
        );
        variable.initializer?.accept(this);
      }
    }
  }

  void _addLocalVariable(
    AstNode scopeNode,
    Element? element,
    Element2? element2,
  ) {
    if (element is LocalVariableElement) {
      // TODO(brianwilkerson): Figure out why this isn't `PromotableElement`. It
      //  appears to be missing parameter elements.
      _map[element] = range.node(scopeNode);
    }
    if (element2 is PromotableElement2) {
      _map2[element2] = range.node(scopeNode);
    }
  }

  static Map<LocalElement, SourceRange> forNode(AstNode unit) {
    var computer = VisibleRangesComputer();
    unit.accept(computer);
    return computer._map;
  }

  static Map<PromotableElement2, SourceRange> forNode2(AstNode unit) {
    var computer = VisibleRangesComputer();
    unit.accept(computer);
    return computer._map2;
  }

  /// Return the body of the function that contains the given [parameter], or
  /// `null` if no function body could be found.
  static FunctionBody? _getFunctionBody(FormalParameter parameter) {
    var parent = parameter.parent?.parent;
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
