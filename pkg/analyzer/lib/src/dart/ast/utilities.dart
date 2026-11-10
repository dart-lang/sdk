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
@V1Ast('The V2 counterpart is NodeLocator2.')
class NodeLocator extends UnifyingAstVisitor<void> {
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
  new(int startOffset, [int? endOffset])
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
      var end = node.name?.end ?? node.typeName2?.end;
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
          'Exception caught while traversing an AST structure.',
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

/// An object used to locate the [AstNode] associated with a source range.
/// More specifically, they will return the deepest [AstNode] which completely
/// encompasses the specified range with some exceptions:
///
/// - Offsets that fall between the name and type/formal parameter list of a
///   declaration will return the declaration node and not the parameter list
///   node.
class NodeLocator2 extends UnifyingAstVisitor2<void> {
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
  new(int startOffset, [int? endOffset])
    : _startOffset = startOffset,
      _endOffset = endOffset ?? startOffset;

  /// Search within the given AST [node] and return the node that was found,
  /// or `null` if no node was found.
  AstNode? searchWithin(AstNode? node) {
    if (node == null) {
      return null;
    }
    try {
      node.accept2(this);
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
  void visitClassDeclaration2(ClassDeclaration2 node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset &&
        _startOffset == node.namePart.typeName.end) {
      _foundNode = node;
      return;
    }

    super.visitClassDeclaration2(node);
  }

  @override
  void visitConstructorDeclaration2(ConstructorDeclaration2 node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset) {
      var end = node.name?.end ?? node.typeName?.end;
      if (end != null && _startOffset == end) {
        _foundNode = node;
        return;
      }
    }

    super.visitConstructorDeclaration2(node);
  }

  @override
  void visitGetterDeclaration(covariant GetterDeclarationImpl node) {
    _visitMethodDeclaration(node, () => super.visitGetterDeclaration(node));
  }

  @override
  void visitLocalFunctionDeclaration(LocalFunctionDeclaration node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset && _startOffset == node.name.end) {
      _foundNode = node;
      return;
    }

    super.visitLocalFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration2(covariant MethodDeclaration2Impl node) {
    _visitMethodDeclaration(node, () => super.visitMethodDeclaration2(node));
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
      node.visitChildren2(this);
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

  @override
  void visitOperatorDeclaration(covariant OperatorDeclarationImpl node) {
    _visitMethodDeclaration(node, () => super.visitOperatorDeclaration(node));
  }

  @override
  void visitSetterDeclaration(covariant SetterDeclarationImpl node) {
    _visitMethodDeclaration(node, () => super.visitSetterDeclaration(node));
  }

  @override
  void visitTopLevelFunctionDeclaration(TopLevelFunctionDeclaration node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset && _startOffset == node.name.end) {
      _foundNode = node;
      return;
    }

    super.visitTopLevelFunctionDeclaration(node);
  }

  @override
  void visitTopLevelGetterDeclaration(TopLevelGetterDeclaration node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not body or recovery parameter list).
    if (_startOffset == _endOffset && _startOffset == node.name.end) {
      _foundNode = node;
      return;
    }

    super.visitTopLevelGetterDeclaration(node);
  }

  @override
  void visitTopLevelSetterDeclaration(TopLevelSetterDeclaration node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset && _startOffset == node.name.end) {
      _foundNode = node;
      return;
    }

    super.visitTopLevelSetterDeclaration(node);
  }

  void _visitMethodDeclaration(
    MethodDeclarationV1OriginImpl node,
    void Function() visitSuper,
  ) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset && _startOffset == node.nameToken.end) {
      _foundNode = node;
      return;
    }

    visitSuper();
  }
}
