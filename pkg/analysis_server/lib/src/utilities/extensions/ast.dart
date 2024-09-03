// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class ThrowStatement {
  final ExpressionStatement statement;
  final ThrowExpression expression;

  ThrowStatement({
    required this.statement,
    required this.expression,
  });
}

class _ReferencedUnprefixedNamesCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = <String>{};

  @override
  void visitNamedType(NamedType node) {
    if (node.importPrefix == null) {
      names.add(node.name2.lexeme);
    }

    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!_isPrefixed(node) && !_isLabelName(node)) {
      names.add(node.name);
    }
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    names.add(node.name.lexeme);
    return super.visitVariableDeclaration(node);
  }

  static bool _isLabelName(SimpleIdentifier node) {
    return node.parent is Label;
  }

  static bool _isPrefixed(SimpleIdentifier node) {
    var parent = node.parent;
    return parent is ConstructorName && parent.name == node ||
        parent is MethodInvocation &&
            parent.methodName == node &&
            parent.realTarget != null ||
        parent is PrefixedIdentifier && parent.identifier == node ||
        parent is PropertyAccess && parent.target == node;
  }
}

extension AnnotatedNodeExtension on AnnotatedNode {
  /// Return the first token in this node that is not a comment.
  Token get firstNonCommentToken {
    var metadata = this.metadata;
    if (metadata.isEmpty) {
      return firstTokenAfterCommentAndMetadata;
    }
    return metadata.beginToken!;
  }
}

extension AstNodeExtension on AstNode {
  /// Returns [ExtensionElement] declared by an enclosing node.
  ExtensionElement? get enclosingExtensionElement {
    for (var node in withParents) {
      if (node is ExtensionDeclaration) {
        return node.declaredElement;
      }
    }
    return null;
  }

  /// Return the [IfStatement] associated with `this`.
  IfStatement? get enclosingIfStatement {
    for (var node in withParents) {
      if (node is IfStatement) {
        return node;
      } else if (node is! Expression) {
        return null;
      }
    }
    return null;
  }

  /// Returns [InterfaceElement] declared by an enclosing node.
  InterfaceElement? get enclosingInterfaceElement {
    for (var node in withParents) {
      if (node is ClassDeclaration) {
        return node.declaredElement;
      } else if (node is MixinDeclaration) {
        return node.declaredElement;
      }
    }
    return null;
  }

  /// Return `true` if this node has an `override` annotation.
  bool get hasOverride {
    var node = this;
    if (node is AnnotatedNode) {
      for (var annotation in node.metadata) {
        if (annotation.name.name == 'override' &&
            annotation.arguments == null) {
          return true;
        }
      }
    }
    return false;
  }

  bool get inAsyncMethodOrFunction {
    var body = thisOrAncestorOfType<FunctionBody>();
    return body != null && body.isAsynchronous && body.star == null;
  }

  bool get inAsyncStarOrSyncStarMethodOrFunction {
    var body = thisOrAncestorOfType<FunctionBody>();
    return body != null && body.keyword != null && body.star != null;
  }

  bool get inCatchClause => thisOrAncestorOfType<CatchClause>() != null;

  bool get inClassMemberBody {
    var node = this;
    while (true) {
      var body = node.thisOrAncestorOfType<FunctionBody>();
      if (body == null) {
        return false;
      }
      var parent = body.parent;
      if (parent is ConstructorDeclaration || parent is MethodDeclaration) {
        return true;
      } else if (parent == null) {
        return false;
      }
      node = parent;
    }
  }

  bool get inDoLoop => thisOrAncestorOfType<DoStatement>() != null;

  bool get inForLoop =>
      thisOrAncestorMatching((p) => p is ForStatement) != null;

  bool get inLoop => inDoLoop || inForLoop || inWhileLoop;

  bool get inSwitch => thisOrAncestorOfType<SwitchStatement>() != null;

  bool get inWhileLoop => thisOrAncestorOfType<WhileStatement>() != null;

  /// The [Token]s contained within `this`.
  List<Token> get tokens {
    var result = <Token>[];
    for (var token = beginToken;; token = token.next!) {
      result.add(token);
      if (token == endToken) {
        break;
      }
    }
    return result;
  }

  /// Returns the [ExpressionStatement] associated with `this` if `this` points
  /// to the identifier for a simple `print`, and `null` otherwise.
  ExpressionStatement? findSimplePrintInvocation() {
    var parent = this.parent;
    var grandparent = parent?.parent;
    if (this case SimpleIdentifier(:var staticElement)) {
      if (staticElement is FunctionElement &&
          staticElement.name == 'print' &&
          staticElement.library.isDartCore &&
          parent is MethodInvocation &&
          grandparent is ExpressionStatement) {
        return grandparent;
      }
    }
    return null;
  }
}

extension BinaryExpressionExtension on BinaryExpression {
  bool get isNotEqNull {
    return operator.type == TokenType.BANG_EQ && rightOperand is NullLiteral;
  }
}

extension CompilationUnitExtension on CompilationUnit {
  /// Return the list of tokens that comprise the file header comment for this
  /// compilation unit.
  ///
  /// If there is no file comment the list will be empty. If the file comment is
  /// a block comment the list will contain a single token. If the file comment
  /// is comprised of one or more single line comments, then the list will
  /// contain all of the tokens, and the comment is assumed to stop at the first
  /// line that contains anything other than a single line comment (either a
  /// blank line, a directive, a declaration, or a multi-line comment). The list
  /// will never include a documentation comment.
  List<Token> get fileHeader {
    var lineInfo = this.lineInfo;
    var firstToken = beginToken;
    if (firstToken.type == TokenType.SCRIPT_TAG) {
      firstToken = firstToken.next!;
    }
    var firstComment = firstToken.precedingComments;
    if (firstComment == null ||
        firstComment.lexeme.startsWith('/**') ||
        firstComment.lexeme.startsWith('///')) {
      return const [];
    } else if (firstComment.lexeme.startsWith('/*')) {
      return [firstComment];
    } else if (!firstComment.lexeme.startsWith('//')) {
      return const [];
    }
    var header = <Token>[firstComment];
    var previousLine = lineInfo.getLocation(firstComment.offset).lineNumber;
    var currentToken = firstComment.next;
    while (currentToken != null) {
      if (!currentToken.lexeme.startsWith('//') ||
          currentToken.lexeme.startsWith('///')) {
        return header;
      }
      var currentLine = lineInfo.getLocation(currentToken.offset).lineNumber;
      if (currentLine != previousLine + 1) {
        return header;
      }
      header.add(currentToken);
      currentToken = currentToken.next;
      previousLine = currentLine;
    }
    return header;
  }

  /// Returns names of elements that might conflict with a new local variable
  /// declared at [offset].
  Set<String> findPossibleLocalVariableConflicts(int offset) {
    var conflicts = <String>{};
    var enclosingNode = NodeLocator(offset).searchWithin(this)!;
    var enclosingBlock = enclosingNode.thisOrAncestorOfType<Block>();
    if (enclosingBlock != null) {
      var visitor = _ReferencedUnprefixedNamesCollector();
      enclosingBlock.accept(visitor);
      return visitor.names;
    }
    return conflicts;
  }
}

extension DeclaredVariablePatternExtension on DeclaredVariablePattern {
  Token? get finalKeyword {
    return keyword.asFinalKeyword;
  }

  Token? get varKeyword {
    return keyword.asVarKeyword;
  }
}

extension DirectiveExtension on Directive {
  /// If the target imports or exports a [LibraryElement], returns it.
  LibraryElement? get referencedLibrary {
    var element = this.element;
    if (element is LibraryExportElement) {
      return element.exportedLibrary;
    } else if (element is LibraryImportElement) {
      return element.importedLibrary;
    }
    return null;
  }

  /// If [referencedUri] is a [DirectiveUriWithSource], returns the [Source]
  /// from it.
  Source? get referencedSource {
    var uri = referencedUri;
    if (uri is DirectiveUriWithSource) {
      return uri.source;
    }
    return null;
  }

  /// Returns the [DirectiveUri] from the element.
  DirectiveUri? get referencedUri {
    var self = this;
    if (self is AugmentationImportDirective) {
      return self.element?.uri;
    } else if (self is ExportDirective) {
      return self.element?.uri;
    } else if (self is ImportDirective) {
      return self.element?.uri;
    } else if (self is PartDirective) {
      return self.element?.uri;
    }
    return null;
  }
}

extension ExpressionExtension on Expression {
  /// Return `true` if this expression is an invocation of the method `cast`
  /// from either Iterable`, `List`, `Map`, or `Set`.
  bool get isCastMethodInvocation {
    if (this is MethodInvocation) {
      var element = (this as MethodInvocation).methodName.staticElement;
      return element is MethodElement && element.isCastMethod;
    }
    return false;
  }

  /// Return `true` if this expression is an invocation of the method `toList`
  /// from `Iterable`.
  bool get isToListMethodInvocation {
    if (this is MethodInvocation) {
      var element = (this as MethodInvocation).methodName.staticElement;
      return element is MethodElement && element.isToListMethod;
    }
    return false;
  }

  /// Return `true` if this expression is an invocation of the method `toSet`
  /// from `Iterable`.
  bool get isToSetMethodInvocation {
    if (this is MethodInvocation) {
      var element = (this as MethodInvocation).methodName.staticElement;
      return element is MethodElement && element.isToSetMethod;
    }
    return false;
  }

  /// Whether this [Expression] should be wrapped with parentheses when we want
  /// to use it as operand of a logical and-expression.
  bool get shouldWrapParenthesisBeforeAnd {
    var self = this;
    if (self is! BinaryExpression) {
      return false;
    }
    var precedence = self.operator.type.precedence;
    return precedence < TokenClass.LOGICAL_AND_OPERATOR.precedence;
  }
}

extension FunctionBodyExtension on FunctionBody {
  bool get isEmpty =>
      this is EmptyFunctionBody ||
      (this is BlockFunctionBody && beginToken.isSynthetic);
}

extension MethodDeclarationExtension on MethodDeclaration {
  Token? get propertyKeywordGet {
    var propertyKeyword = this.propertyKeyword;
    return propertyKeyword != null && propertyKeyword.keyword == Keyword.GET
        ? propertyKeyword
        : null;
  }
}

extension NamedTypeExtension on NamedType {
  String get qualifiedName {
    var importPrefix = this.importPrefix;
    if (importPrefix != null) {
      return '${importPrefix.name.lexeme}.${name2.lexeme}';
    } else {
      return name2.lexeme;
    }
  }
}

extension NodeListExtension<E extends AstNode> on NodeList<E> {
  /// Return the last element of the list whose end is at or before the
  /// [offset], or `null` if the list is empty or if the offset is before the
  /// end of the first element.
  E? elementBefore(int offset) {
    for (var i = length - 1; i >= 0; i--) {
      var element = this[i];
      if (element.end <= offset) {
        return element;
      }
    }
    return null;
  }
}

extension StatementExtension on Statement {
  ThrowStatement? get followingThrow {
    var block = parent;
    if (block is Block) {
      var next = block.statements.nextOrNull(this);
      if (next is ExpressionStatement) {
        var throwExpression = next.expression;
        if (throwExpression is ThrowExpression) {
          return ThrowStatement(
            statement: next,
            expression: throwExpression,
          );
        }
      }
    }
    return null;
  }

  List<Statement> get selfOrBlockStatements {
    var self = this;
    return self is Block ? self.statements : [self];
  }
}

extension TokenQuestionExtension on Token? {
  Token? get asFinalKeyword {
    var self = this;
    return self != null && self.keyword == Keyword.FINAL ? self : null;
  }

  Token? get asVarKeyword {
    var self = this;
    return self != null && self.keyword == Keyword.VAR ? self : null;
  }
}

extension VariableDeclarationListExtension on VariableDeclarationList {
  Token? get finalKeyword {
    return keyword.asFinalKeyword;
  }

  Token? get varKeyword {
    return keyword.asVarKeyword;
  }
}
