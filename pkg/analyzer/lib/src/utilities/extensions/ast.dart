// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

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
    for (var node in withAncestors) {
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

  /// The [ExecutableElement] of the enclosing executable [AstNode].
  ExecutableElement? get enclosingExecutableElement {
    for (var node in withAncestors) {
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

  /// The [InstanceElement] of the enclosing executable [AstNode].
  InstanceElement? get enclosingInstanceElement {
    for (var node in withAncestors) {
      var element = switch (node) {
        ClassDeclaration(:var declaredFragment?) => declaredFragment.element,
        EnumDeclaration(:var declaredFragment?) => declaredFragment.element,
        ExtensionDeclaration(:var declaredFragment?) =>
          declaredFragment.element,
        ExtensionTypeDeclaration(:var declaredFragment?) =>
          declaredFragment.element,
        MixinDeclaration(:var declaredFragment?) => declaredFragment.element,
        _ => null,
      };
      if (element != null) {
        return element;
      }
    }
    return null;
  }

  InterfaceElement? get enclosingInterfaceElement =>
      enclosingInstanceElement.ifTypeOrNull();

  AstNode? get enclosingUnitChild {
    for (var node in withAncestors) {
      if (node.parent is CompilationUnit) {
        return node;
      }
    }
    return null;
  }

  /// This node and all of its ancestors.
  Iterable<AstNode> get withAncestors sync* {
    AstNode? current = this;
    while (current != null) {
      yield current;
      current = current.parent;
    }
  }

  /// Returns the comment token that covers the [offset].
  Token? commentTokenCovering(int offset) {
    for (var token in allTokens) {
      for (
        Token? comment = token.precedingComments;
        comment is Token;
        comment = comment.next
      ) {
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

extension ExtensionElementExtension on ExtensionElement {
  InterfaceElement? get extendedInterfaceElement =>
      extendedType.ifTypeOrNull<InterfaceType>()?.element;
}

extension FieldDeclarationExtension on FieldDeclaration {
  Element get firstVariableElement =>
      fields.variables.first.declaredFragment!.element;
}

extension TopLevelVariableDeclarationExtension on TopLevelVariableDeclaration {
  Element get firstVariableElement =>
      variables.variables.first.declaredFragment!.element;
}

extension VariableDeclarationExtension on VariableDeclaration {
  FieldElementImpl get declaredFieldElement {
    return declaredFragment!.element as FieldElementImpl;
  }

  TopLevelVariableElementImpl get declaredTopLevelVariableElement {
    return declaredFragment!.element as TopLevelVariableElementImpl;
  }
}
