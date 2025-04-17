// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/element/element.dart';

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

  /// The [FunctionExpression] that encloses this node directly or `null` if
  /// there is another enclosing executable element.
  FunctionExpression? get enclosingClosure {
    for (var node in withParents) {
      switch (node) {
        case FunctionExpression(:var parent)
            when parent is! FunctionDeclaration:
          return node;
        case FunctionDeclaration() ||
              ConstructorDeclaration() ||
              MethodDeclaration():
          break;
      }
    }
    return null;
  }

  /// The [ExecutableElement2] of the enclosing executable [AstNode].
  ExecutableElement2? get enclosingExecutableElement2 {
    for (var node in withParents) {
      if (node is FunctionDeclaration) {
        return node.declaredFragment?.element;
      }
      if (node is ConstructorDeclaration) {
        return node.declaredFragment?.element;
      }
      if (node is MethodDeclaration) {
        return node.declaredFragment?.element;
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
    var declaredFragment = this.declaredFragment;
    if (declaredFragment == null) return false;
    var pathContext =
        declaredFragment.element.session.resourceProvider.pathContext;
    var path = declaredFragment.source.fullName;
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

extension VariableDeclarationExtension on VariableDeclaration {
  FieldElementImpl2 get declaredFieldElement {
    return declaredFragment!.element as FieldElementImpl2;
  }

  TopLevelVariableElementImpl2 get declaredTopLevelVariableElement {
    return declaredFragment!.element as TopLevelVariableElementImpl2;
  }
}
