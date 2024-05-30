// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';

extension AstNodeExtension on AstNode {
  /// Returns all tokens, from [beginToken] to [endToken] including.
  List<Token> get allTokens {
    var result = <Token>[];
    var token = beginToken;
    while (true) {
      result.add(token);
      if (token == endToken) {
        break;
      }
      if (token.next case var next?) {
        token = next;
      } else {
        break;
      }
    }
    return result;
  }

  /// The [ExecutableElement] of the enclosing executable [AstNode].
  ExecutableElement? get enclosingExecutableElement {
    for (var node in withParents) {
      if (node is FunctionDeclaration) {
        return node.declaredElement;
      }
      if (node is ConstructorDeclaration) {
        return node.declaredElement;
      }
      if (node is MethodDeclaration) {
        return node.declaredElement;
      }
    }
    return null;
  }

  AstNode? get enclosingUnitChild {
    for (var node in withParents) {
      if (node.parent is CompilationUnit) {
        return node;
      }
    }
    return null;
  }

  /// This node and all its parents.
  Iterable<AstNode> get withParents sync* {
    var current = this;
    while (true) {
      yield current;
      var parent = current.parent;
      if (parent == null) {
        break;
      }
      current = parent;
    }
  }

  /// Returns the comment token that covers the [offset].
  Token? commentTokenCovering(int offset) {
    for (var token in allTokens) {
      for (Token? comment = token.precedingComments;
          comment is Token;
          comment = comment.next) {
        if (comment.offset <= offset && offset <= comment.end) {
          return comment;
        }
      }
    }
    return null;
  }

  /// Return the minimal cover node for the range of characters beginning at the
  /// [offset] with the given [length], or `null` if the range is outside the
  /// range covered by the receiver.
  ///
  /// The minimal covering node is the node, rooted at the receiver, with the
  /// shortest length whose range completely includes the given range.
  AstNode? nodeCovering({required int offset, int length = 0}) {
    var end = offset + length;

    /// Return `true` if the [node] contains the range.
    ///
    /// When the range is an insertion point between two adjacent tokens, one of
    /// which belongs to the [node] and the other to a different node, then the
    /// [node] is considered to contain the insertion point unless the token
    /// that doesn't belonging to the [node] is an identifier.
    bool containsOffset(AstNode node) {
      if (length == 0) {
        if (offset == node.offset) {
          var previous = node.beginToken.previous;
          if (previous != null &&
              offset == previous.end &&
              previous.isIdentifier) {
            return false;
          }
        }
        if (offset == node.end) {
          var next = node.endToken.next;
          if (next != null && offset == next.offset && next.isIdentifier) {
            return false;
          }
        }
      }
      return node.offset <= offset && node.end >= end;
    }

    /// Return the child of the [node] that completely contains the range, or
    /// `null` if none of the children contain the range (which means that the
    /// [node] is the covering node).
    AstNode? childContainingRange(AstNode node) {
      for (var entity in node.childEntities) {
        if (entity is AstNode && containsOffset(entity)) {
          return entity;
        }
      }
      return null;
    }

    if (this is CompilationUnit) {
      if (offset < 0 || end > this.end) {
        return null;
      }
    } else if (!containsOffset(this)) {
      return null;
    }
    var previousNode = this;
    var currentNode = childContainingRange(previousNode);
    while (currentNode != null) {
      previousNode = currentNode;
      currentNode = childContainingRange(previousNode);
    }
    return previousNode;
  }
}

extension AstNodeNullableExtension on AstNode? {
  List<ClassMember> get classMembers {
    var self = this;
    return switch (self) {
      ClassDeclaration() => self.members,
      EnumDeclaration() => self.members,
      ExtensionDeclaration() => self.members,
      ExtensionTypeDeclaration() => self.members,
      MixinDeclaration() => self.members,
      _ => throw UnimplementedError('(${self.runtimeType}) $self'),
    };
  }
}

extension CompilationUnitExtension on CompilationUnit {
  /// Whether this [CompilationUnit] is found in a "test" directory.
  bool get inTestDir {
    var declaredElement = this.declaredElement;
    if (declaredElement == null) return false;
    var pathContext = declaredElement.session.resourceProvider.pathContext;
    var path = declaredElement.source.fullName;
    return switch (pathContext.separator) {
      '/' => const [
          '/test/',
          '/integration_test/',
          '/test_driver/',
          '/testing/',
        ].any(path.contains),
      r'\' => const [
          r'\test\',
          r'\integration_test\',
          r'\test_driver\',
          r'\testing\',
        ].any(path.contains),
      _ => false,
    };
  }
}
