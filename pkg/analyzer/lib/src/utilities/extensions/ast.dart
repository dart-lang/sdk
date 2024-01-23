// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

extension AstNodeExtension on AstNode {
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
    final self = this;
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
