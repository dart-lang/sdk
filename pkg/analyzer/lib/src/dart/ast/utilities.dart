// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/lint/linter_visitor.dart';
library;

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;

export 'package:analyzer/src/dart/ast/constant_evaluator.dart';

/// An object used to locate the [AstNode] associated with a source range.
/// More specifically, they will return the deepest [AstNode] which completely
/// encompasses the specified range with some exceptions:
///
/// - Offsets that fall between the name and type/formal parameter list of a
///   declaration will return the declaration node and not the parameter list
///   node.
class NodeLocator2 extends UnifyingAstVisitor<void> {
  /// The inclusive start offset of the range used to identify the node.
  final int _startOffset;

  /// The inclusive end offset of the range used to identify the node.
  final int _endOffset;

  /// The found node or `null` if there is no such node.
  AstNode? _foundNode;

  /// Initialize a newly created locator to locate the deepest [AstNode] for
  /// which `node.offset <= [startOffset]` and `[endOffset] < node.end`.
  ///
  /// If [endOffset] is not provided, then it is considered the same as the
  /// given [startOffset].
  NodeLocator2(int startOffset, [int? endOffset])
    : _startOffset = startOffset,
      _endOffset = endOffset ?? startOffset;

  /// Search within the given AST [node] and return the node that was found,
  /// or `null` if no node was found.
  AstNode? searchWithin(AstNode? node) {
    if (node == null) {
      return null;
    }
    try {
      node.accept(this);
    } catch (exception, stackTrace) {
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService.logException(
        SilentException(
          'Unable to locate element at offset '
          '($_startOffset - $_endOffset)',
          exception,
          stackTrace,
        ),
      );
      return null;
    }
    return _foundNode;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset &&
        _startOffset == node.namePart.typeName.end) {
      _foundNode = node;
      return;
    }

    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset) {
      var end = node.name?.end ?? node.typeName?.end;
      if (end != null && _startOffset == end) {
        _foundNode = node;
        return;
      }
    }

    super.visitConstructorDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset && _startOffset == node.name.end) {
      _foundNode = node;
      return;
    }

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset && _startOffset == node.name.end) {
      _foundNode = node;
      return;
    }

    super.visitMethodDeclaration(node);
  }

  @override
  void visitNode(AstNode node) {
    // Don't visit a new tree if the result has been already found.
    if (_foundNode != null) {
      return;
    }
    // Check whether the current node covers the selection.
    Token beginToken = node.beginToken;
    Token endToken = node.endToken;
    // Don't include synthetic tokens.
    while (endToken != beginToken) {
      // Fasta scanner reports unterminated string literal errors
      // and generates a synthetic string token with non-zero length.
      // Because of this, check for length > 0 rather than !isSynthetic.
      if (endToken.isEof || endToken.length > 0) {
        break;
      }
      endToken = endToken.previous!;
    }
    int end = endToken.end;
    int start = node.offset;
    if (end <= _startOffset || start > _endOffset) {
      return;
    }
    // Check children.
    try {
      node.visitChildren(this);
    } catch (exception, stackTrace) {
      // Ignore the exception and proceed in order to visit the rest of the
      // structure.
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService.logException(
        SilentException(
          "Exception caught while traversing an AST structure.",
          exception,
          stackTrace,
        ),
      );
    }
    // Found a child.
    if (_foundNode != null) {
      return;
    }
    // Check this node.
    if (start <= _startOffset && _endOffset < end) {
      _foundNode = node;
    }
  }
}

/// Traverse the AST from initial child node to successive parents, building a
/// collection of local variable and parameter names visible to the initial
/// child node. In case of name shadowing, the first name seen is the most
/// specific one so names are not redefined.
///
/// Completion test code coverage is 95%. The two basic blocks that are not
/// executed cannot be executed. They are included for future reference.
class ScopedNameFinder extends GeneralizingAstVisitor<void> {
  Declaration? _declarationNode;

  AstNode? _immediateChild;

  final Set<String> _locals = {};

  final int _position;

  bool _referenceIsWithinLocalFunction = false;

  ScopedNameFinder(this._position);

  Declaration? get declaration => _declarationNode;

  Set<String> get locals => _locals;

  @override
  void visitBlock(Block node) {
    _checkStatements(node.statements);
    super.visitBlock(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _addToScope(node.exceptionParameter?.name);
    _addToScope(node.stackTraceParameter?.name);
    super.visitCatchClause(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!identical(_immediateChild, node.parameters)) {
      _addParameters(node.parameters.parameters);
    }
    _declarationNode = node;
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _declarationNode = node;
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _addToScope(node.loopVariable.name);
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _addVariables(node.variables.variables);
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is! FunctionDeclarationStatement) {
      _declarationNode = node;
    } else {
      super.visitFunctionDeclaration(node);
    }
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _referenceIsWithinLocalFunction = true;
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    var parameters = node.parameters;
    if (parameters != null && !identical(_immediateChild, parameters)) {
      _addParameters(parameters.parameters);
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _declarationNode = node;
    var parameters = node.parameters;
    if (parameters != null && !identical(_immediateChild, parameters)) {
      _addParameters(parameters.parameters);
    }
  }

  @override
  void visitNode(AstNode node) {
    _immediateChild = node;
    node.parent?.accept(this);
  }

  @override
  void visitSwitchMember(SwitchMember node) {
    _checkStatements(node.statements);
    super.visitSwitchMember(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _declarationNode = node;
  }

  @override
  void visitTypeAlias(TypeAlias node) {
    _declarationNode = node;
  }

  void _addParameters(NodeList<FormalParameter> vars) {
    for (FormalParameter var2 in vars) {
      _addToScope(var2.name);
    }
  }

  void _addToScope(Token? identifier) {
    if (identifier != null && _isInRange(identifier)) {
      _locals.add(identifier.lexeme);
    }
  }

  void _addVariables(NodeList<VariableDeclaration> variables) {
    for (VariableDeclaration variable in variables) {
      _addToScope(variable.name);
    }
  }

  /// Check the given list of [statements] for any that come before the
  /// immediate child and that define a name that would be visible to the
  /// immediate child.
  void _checkStatements(List<Statement> statements) {
    for (Statement statement in statements) {
      if (identical(statement, _immediateChild)) {
        return;
      }
      if (statement is VariableDeclarationStatement) {
        _addVariables(statement.variables.variables);
      } else if (statement is FunctionDeclarationStatement &&
          !_referenceIsWithinLocalFunction) {
        _addToScope(statement.functionDeclaration.name);
      }
    }
  }

  bool _isInRange(Token token) {
    if (_position < 0) {
      // if source position is not set then all nodes are in range
      return true;
      // not reached
    }
    return token.end < _position;
  }
}
