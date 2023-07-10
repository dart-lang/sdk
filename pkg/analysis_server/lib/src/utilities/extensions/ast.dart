// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class ThrowStatement {
  final ExpressionStatement statement;
  final ThrowExpression expression;

  ThrowStatement({
    required this.statement,
    required this.expression,
  });
}

extension AnnotatedNodeExtensions on AnnotatedNode {
  /// Return the first token in this node that is not a comment.
  Token get firstNonCommentToken {
    final metadata = this.metadata;
    if (metadata.isEmpty) {
      return firstTokenAfterCommentAndMetadata;
    }
    return metadata.beginToken!;
  }
}

extension AstNodeExtensions on AstNode {
  /// Returns [ExtensionElement] declared by an enclosing node.
  ExtensionElement? get enclosingExtensionElement {
    for (final node in withParents) {
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
    for (final node in withParents) {
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

  /// Return this node and all its parents.
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
}

extension BinaryExpressionExtensions on BinaryExpression {
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
    final lineInfo = this.lineInfo;
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

  /// Return `true` if library being analyzed is non-nullable by default.
  ///
  /// Will return `false` if the AST structure has not been resolved.
  bool get isNonNullableByDefault =>
      declaredElement?.library.isNonNullableByDefault ?? false;
}

extension DeclaredVariablePatternExtension on DeclaredVariablePattern {
  Token? get finalKeyword {
    return keyword.asFinalKeyword;
  }

  Token? get varKeyword {
    return keyword.asVarKeyword;
  }
}

extension DirectiveExtensions on Directive {
  /// If the target imports or exports a [LibraryElement], returns it.
  LibraryElement? get referencedLibrary {
    final element = this.element;
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
    final uri = referencedUri;
    if (uri is DirectiveUriWithSource) {
      return uri.source;
    }
    return null;
  }

  /// Returns the [DirectiveUri] from the element.
  DirectiveUri? get referencedUri {
    final self = this;
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

extension ExpressionExtensions on Expression {
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
}

extension FunctionBodyExtensions on FunctionBody {
  bool get isEmpty =>
      this is EmptyFunctionBody ||
      (this is BlockFunctionBody && beginToken.isSynthetic);
}

extension MethodDeclarationExtension on MethodDeclaration {
  Token? get propertyKeywordGet {
    final propertyKeyword = this.propertyKeyword;
    return propertyKeyword != null && propertyKeyword.keyword == Keyword.GET
        ? propertyKeyword
        : null;
  }
}

extension NamedTypeExtension on NamedType {
  String get qualifiedName {
    final importPrefix = this.importPrefix;
    if (importPrefix != null) {
      return '${importPrefix.name.lexeme}.${name2.lexeme}';
    } else {
      return name2.lexeme;
    }
  }
}

extension NodeListExtension<E extends AstNode> on NodeList<E> {
  /// Return the first element of the list whose end is at or before the
  /// [offset], or `null` if the list is empty or if the offset is before the
  /// end of the first element.
  E? elementBefore(int offset) {
    for (var element in this) {
      if (element.end <= offset) {
        return element;
      }
    }
    return null;
  }
}

extension StatementExtension on Statement {
  ThrowStatement? get followingThrow {
    final block = parent;
    if (block is Block) {
      final next = block.statements.nextOrNull(this);
      if (next is ExpressionStatement) {
        final throwExpression = next.expression;
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
    final self = this;
    return self is Block ? self.statements : [self];
  }
}

extension TokenQuestionExtension on Token? {
  Token? get asFinalKeyword {
    final self = this;
    return self != null && self.keyword == Keyword.FINAL ? self : null;
  }

  Token? get asVarKeyword {
    final self = this;
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
