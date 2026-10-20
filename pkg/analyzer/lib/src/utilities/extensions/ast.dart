// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
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
  @V1Ast('The V2 counterpart is enclosingClosure2.')
  FunctionExpression? get enclosingClosure {
    for (var node in withAncestors) {
      switch (node) {
        case FunctionExpression(:var parent)
            when parent is! FunctionDeclaration:
          return node;
        case FunctionDeclaration() ||
            ConstructorDeclaration() ||
            MethodDeclaration():
          return null;
      }
    }
    return null;
  }

  /// The [FunctionExpression] that encloses this node directly or `null` if
  /// there is another enclosing executable element.
  FunctionExpression? get enclosingClosure2 {
    for (var node in withAncestors2) {
      switch (node) {
        case FunctionExpression():
          return node;
        case LocalFunctionDeclaration() ||
            ConstructorDeclaration2() ||
            GetterDeclaration() ||
            MethodDeclaration2() ||
            OperatorDeclaration() ||
            SetterDeclaration() ||
            TopLevelFunctionDeclaration() ||
            TopLevelGetterDeclaration() ||
            TopLevelSetterDeclaration():
          return null;
      }
    }
    return null;
  }

  /// The [ExecutableElement] of the enclosing executable [AstNode].
  @V1Ast('The V2 counterpart is enclosingExecutableElement2.')
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

  /// The [ExecutableElement] of the enclosing executable [AstNode].
  ExecutableElement? get enclosingExecutableElement2 {
    for (var node in withAncestors2) {
      if (node is LocalFunctionDeclaration) {
        return node.declaredFragment?.element;
      }
      if (node is ConstructorDeclaration2) {
        return node.declaredFragment?.element;
      }
      if (node is MethodDeclarationV1OriginImpl) {
        return node.declaredFragment?.element;
      }
      if (node is TopLevelFunctionDeclaration) {
        return node.declaredFragment?.element;
      }
      if (node is TopLevelGetterDeclaration) {
        return node.declaredFragment?.element;
      }
      if (node is TopLevelSetterDeclaration) {
        return node.declaredFragment?.element;
      }
    }
    return null;
  }

  /// The [InstanceElement] of the enclosing executable [AstNode].
  @V1Ast('The V2 counterpart is enclosingInstanceElement2.')
  InstanceElement? get enclosingInstanceElement {
    for (var node in withAncestors) {
      var element = node
          .tryCast<FragmentDeclaringNode>()
          ?.declaredFragment
          ?.element;
      if (element is InstanceElement) {
        return element;
      }
    }
    return null;
  }

  /// The [InstanceElement] of the enclosing executable [AstNode].
  InstanceElement? get enclosingInstanceElement2 {
    for (var node in withAncestors2) {
      var element = node
          .tryCast<FragmentDeclaringNode>()
          ?.declaredFragment
          ?.element;
      if (element is InstanceElement) {
        return element;
      }
    }
    return null;
  }

  @V1Ast('The V2 counterpart is enclosingInterfaceElement2.')
  InterfaceElement? get enclosingInterfaceElement =>
      enclosingInstanceElement.tryCast();

  InterfaceElement? get enclosingInterfaceElement2 =>
      enclosingInstanceElement2.tryCast();

  /// The name scope of this node, or of the closest ancestor that has one.
  ///
  /// Name scopes are recorded during resolution, so this is `null` for
  /// unresolved nodes.
  @V1Ast('The V2 counterpart is enclosingNameScope2.')
  Scope? get enclosingNameScope {
    for (var node in withAncestors) {
      if (node is AstNodeWithNameScopeMixin && node.nameScope != null) {
        return node.nameScope;
      }
    }
    return null;
  }

  /// The name scope of this node, or of the closest ancestor that has one.
  ///
  /// Name scopes are recorded during resolution, so this is `null` for
  /// unresolved nodes.
  Scope? get enclosingNameScope2 {
    for (var node in withAncestors2) {
      if (node is AstNodeWithNameScopeMixin && node.nameScope != null) {
        return node.nameScope;
      }
    }
    return null;
  }

  @V1Ast('The V2 counterpart is enclosingUnitChild2.')
  AstNode? get enclosingUnitChild {
    for (var node in withAncestors) {
      if (node.parent is CompilationUnit) {
        return node;
      }
    }
    return null;
  }

  AstNode? get enclosingUnitChild2 {
    for (var node in withAncestors2) {
      if (node.parent2 is CompilationUnit) {
        return node;
      }
    }
    return null;
  }

  /// This node and all of its ancestors.
  @V1Ast('The V2 counterpart is withAncestors2.')
  Iterable<AstNode> get withAncestors sync* {
    AstNode? current = this;
    while (current != null) {
      yield current;
      current = current.parent;
    }
  }

  /// This node and all of its ancestors.
  Iterable<AstNode> get withAncestors2 sync* {
    AstNode? current = this;
    while (current != null) {
      yield current;
      current = current.parent2;
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
  @V1Ast('The V2 counterpart is classMembers2.')
  List<ClassMember> get classMembers {
    var self = this;
    return switch (self) {
      BlockClassBody() => self.members,
      BlockEnumBody() => self.members,
      ClassDeclaration() => self.body.members,
      EnumDeclaration() => self.body.members,
      ExtensionDeclaration() => self.body.members,
      ExtensionTypeDeclarationImpl() => self.body.members,
      MixinDeclaration() => self.body.members,
      _ => throw UnimplementedError('(${self.runtimeType}) $self'),
    };
  }

  List<AnnotatedNode> get classMembers2 {
    var self = this;
    return switch (self) {
      BlockEnumDeclarationBody() => self.members,
      BlockInstanceDeclarationBody() => self.members,
      ClassDeclaration2Impl() => self.body.members,
      EnumDeclaration2() => self.body.members,
      ExtensionDeclaration2() => self.body.members,
      ExtensionTypeDeclaration2Impl() => self.body.members,
      MixinDeclaration2() => self.body.members,
      _ => throw UnimplementedError('(${self.runtimeType}) $self'),
    };
  }
}

extension ExpressionExtension on Expression {
  /// Whether this expression is found in a [CommentReference].
  @V1Ast('The V2 counterpart is inCommentReference2.')
  bool get inCommentReference =>
      parent is CommentReference ||
      parent?.parent is CommentReference ||
      parent?.parent?.parent is CommentReference;

  /// Whether this expression is found in a [CommentReference].
  bool get inCommentReference2 =>
      parent2 is CommentReference ||
      parent2?.parent2 is CommentReference ||
      parent2?.parent2?.parent2 is CommentReference;
}

extension ExtensionElementExtension on ExtensionElement {
  InterfaceElement? get extendedInterfaceElement =>
      extendedType.tryCast<InterfaceType>()?.element;
}

extension Field2Extension on Field2 {
  FieldElementImpl get declaredElement {
    return declaredFragment!.element as FieldElementImpl;
  }
}

@V1Ast('The V2 counterpart is FieldsDeclarationExtension.')
extension FieldDeclarationExtension on FieldDeclaration {
  Element get firstVariableElement =>
      fields.variables.first.declaredFragment!.element;
}

extension FieldsDeclarationExtension on FieldsDeclaration {
  Element get firstVariableElement => fields.first.declaredFragment!.element;
}

extension InterpolationExpressionExtension on InterpolationExpression {
  static final _identifierPart = RegExp('[a-zA-Z0-9_]');

  /// Whether the braces of this interpolation (`${...}`) could be removed if
  /// its expression were written as [name], an identifier.
  ///
  /// Not if there are no braces to remove, if [name] contains a `$` (which
  /// can't be interpolated without braces), or if the string continues with a
  /// character that would then be taken as part of the identifier, as in
  /// `'${x}y'`.
  ///
  /// [name] is passed in, rather than read from [expression], so that this
  /// also works for a quick fix that is changing the expression at the same
  /// time: what matters is the name the expression will have once the fix
  /// has been applied, not the one it has now. (For example, removing
  /// `self.` from `${self.x}` leaves `${x}`.)
  bool canRemoveBracesAround(String name) {
    var rightBracket = this.rightBracket;
    if (rightBracket == null || name.contains(r'$')) return false;
    var next = rightBracket.next;
    return !(next is StringToken && next.lexeme.startsWith(_identifierPart));
  }
}

extension TokenExtension on Token {
  /// The first preceding comment before this token, or this token if there are
  /// no preceding comments.
  Token get precedingCommentOrThis => precedingComments ?? this;
}

extension TopLevelVariable2Extension on TopLevelVariable2 {
  TopLevelVariableElementImpl get declaredElement {
    return declaredFragment!.element as TopLevelVariableElementImpl;
  }
}

@V1Ast('The V2 counterpart is TopLevelVariablesDeclarationExtension.')
extension TopLevelVariableDeclarationExtension on TopLevelVariableDeclaration {
  Element get firstVariableElement =>
      variables.variables.first.declaredFragment!.element;
}

extension TopLevelVariablesDeclarationExtension
    on TopLevelVariablesDeclaration {
  Element get firstVariableElement => variables.first.declaredFragment!.element;
}

@V1Ast('The V2 counterpart is Field2Extension.')
extension VariableDeclarationExtension on VariableDeclaration {
  FieldElementImpl get declaredFieldElement {
    return declaredFragment!.element as FieldElementImpl;
  }
}
