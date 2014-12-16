// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.optype;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';

/**
 * An [AstVisitor] for determining whether top level suggestions or invocation
 * suggestions should be made based upon the type of node in which the
 * suggestions were requested.
 */
class OpTypeAstVisitor extends GeneralizingAstVisitor {

  /**
   * The offset within the source at which the completion is requested.
   */
  int offset;

  /**
   * Indicates whether invocation suggestions should be included.
   */
  bool includeInvocationSuggestions = false;

  /**
   * Indicates whether type names should be suggested.
   */
  bool includeTypeNameSuggestions = false;

  /**
   * Indicates whether setters along with methods and functions that
   * have a [void] return type should be suggested.
   */
  bool includeVoidReturnSuggestions = false;

  /**
   * Indicates whether fields and getters along with methods and functions that
   * have a non-[void] return type should be suggested.
   */
  bool includeReturnValueSuggestions = false;

  OpTypeAstVisitor(this.offset);

  /**
   * Indicate whether only type names should be suggested
   */
  bool get includeOnlyTypeNameSuggestions =>
      includeTypeNameSuggestions &&
          !includeReturnValueSuggestions &&
          !includeVoidReturnSuggestions &&
          !includeInvocationSuggestions;

  /**
   * Indicate whether top level elements should be suggested
   */
  bool get includeTopLevelSuggestions =>
      includeReturnValueSuggestions ||
          includeTypeNameSuggestions ||
          includeVoidReturnSuggestions;

  bool isAfterSemicolon(Token semicolon) =>
      semicolon != null && !semicolon.isSynthetic && semicolon.offset < offset;

  @override
  void visitAnnotation(Annotation node) {
    Token atSign = node.atSign;
    if (atSign == null || offset <= atSign.offset) {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
      includeVoidReturnSuggestions = true;
    } else {
      Token period = node.period;
      if (period == null || offset <= period.offset) {
        includeTypeNameSuggestions = true;
        includeReturnValueSuggestions = true;
      } else {
        includeInvocationSuggestions = true;
      }
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    includeReturnValueSuggestions = true;
    includeTypeNameSuggestions = true;
  }

  @override
  void visitBlock(Block node) {
    includeReturnValueSuggestions = true;
    includeTypeNameSuggestions = true;
    includeVoidReturnSuggestions = true;
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    Expression target = node.target;
    if (target != null && offset <= target.end) {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
    } else {
      includeInvocationSuggestions = true;
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Make suggestions in the body of the class declaration
    Token leftBracket = node.leftBracket;
    if (leftBracket != null && offset >= leftBracket.end) {
      includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitClassMember(ClassMember node) {
    if (offset <= node.offset || node.end <= offset) {
      includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitCommentReference(CommentReference node) {
    includeReturnValueSuggestions = true;
    includeTypeNameSuggestions = true;
    includeVoidReturnSuggestions = true;
  }

  @override
  visitConstructorName(ConstructorName node) {
    // some PrefixedIdentifier nodes are transformed into
    // ConstructorName nodes during the resolution process.
    Token period = node.period;
    if (period != null && offset > period.offset) {
      TypeName type = node.type;
      if (type != null) {
        SimpleIdentifier prefix = type.name;
        if (prefix != null) {
          includeInvocationSuggestions = true;
        }
      }
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && leftParen.end <= offset) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || offset <= rightParen.offset) {
        includeReturnValueSuggestions = true;
        includeTypeNameSuggestions = true;
      }
    }
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    includeReturnValueSuggestions = true;
    includeTypeNameSuggestions = true;
    includeVoidReturnSuggestions = true;
  }

  @override
  void visitExpression(Expression node) {
    includeReturnValueSuggestions = true;
    includeTypeNameSuggestions = true;
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    Token functionDefinition = node.functionDefinition;
    if (functionDefinition != null && functionDefinition.end <= offset) {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    Expression expression = node.expression;
    // A pre-variable declaration (e.g. C ^) is parsed as an expression
    // statement. Do not make suggestions for the variable name.
    if (expression is SimpleIdentifier && offset <= expression.end) {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
      includeVoidReturnSuggestions = true;
    } else {
      Token semicolon = node.semicolon;
      if (semicolon != null && semicolon.end <= offset) {
        includeReturnValueSuggestions = true;
        includeTypeNameSuggestions = true;
        includeVoidReturnSuggestions = true;
      }
    }
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    Token keyword = node.keyword;
    if (keyword != null && keyword.end < offset) {
      includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && leftParen.end <= offset) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || offset <= rightParen.offset) {
        includeReturnValueSuggestions = true;
        includeTypeNameSuggestions = true;
      }
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && offset > leftParen.offset) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || offset <= rightParen.offset) {
        includeReturnValueSuggestions = true;
        includeTypeNameSuggestions = true;
      }
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && offset >= leftParen.end) {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
      includeVoidReturnSuggestions = true;
      // TODO (danrubel) void return suggestions only belong after
      // the 2nd semicolon.  Return value suggestions only belong after the
      // e1st or second semicolon.
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    Token keyword = node.keyword;
    if (keyword != null && keyword.end <= offset) {
      SimpleIdentifier id = node.name;
      if (id != null) {
        TypeName returnType = node.returnType;
        if (offset <= (returnType != null ? returnType.end : id.end)) {
          includeTypeNameSuggestions = true;
        }
      }
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && offset >= leftParen.end) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || offset <= rightParen.offset) {
        includeReturnValueSuggestions = true;
        includeTypeNameSuggestions = true;
      }
    }
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    Token keyword = node.keyword;
    if (keyword != null && keyword.end < offset) {
      includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    Expression expression = node.expression;
    if (expression is SimpleIdentifier) {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    SimpleIdentifier id = node.name;
    if (id != null && offset < id.offset) {
      includeTypeNameSuggestions = true;
    }
    visitClassMember(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    Token period = node.period;
    if (period == null || offset <= period.offset) {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
    } else {
      includeInvocationSuggestions = true;
    }
  }

  @override
  void visitNode(AstNode node) {
    // no suggestion by default
  }

  @override
  void visitNormalFormalParameter(NormalFormalParameter node) {
    includeReturnValueSuggestions = true;
    includeTypeNameSuggestions = true;
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    Token period = node.period;
    if (period == null || offset <= period.offset) {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
    } else {
      includeInvocationSuggestions = true;
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    var operator = node.operator;
    if (operator != null && offset < operator.offset) {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
    } else {
      includeInvocationSuggestions = true;
    }
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    Token keyword = node.keyword;
    if (keyword != null && keyword.end < offset) {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    node.parent.accept(this);
  }

  @override
  void visitStringLiteral(StringLiteral node) {
    // no suggestions
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    Token keyword = node.keyword;
    if (keyword == null || keyword.end < offset) {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
      includeVoidReturnSuggestions = true;
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && leftParen.end <= offset) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || offset <= rightParen.offset) {
        includeReturnValueSuggestions = true;
        includeTypeNameSuggestions = true;
      }
    }
  }

  @override
  void visitTypeName(TypeName node) {
    // If suggesting completions within a TypeName node
    // then limit suggestions to only types in specific situations
    AstNode p = node.parent;
    if (p is IsExpression || p is ConstructorName || p is AsExpression) {
      includeTypeNameSuggestions = true;
      // TODO (danrubel) Possible future improvement:
      // on the RHS of an "is" or "as" expression, don't suggest types that are
      // guaranteed to pass or guaranteed to fail the cast.
      // See dartbug.com/18860
    } else if (p is VariableDeclarationList) {
      // TODO (danrubel) When entering 1st of 2 identifiers on assignment LHS
      // the user may be either (1) entering a type for the assignment
      // or (2) starting a new statement.
      // Consider suggesting only types
      // if only spaces separates the 1st and 2nd identifiers.
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
      includeVoidReturnSuggestions = true;
    } else {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
      includeVoidReturnSuggestions = true;
    }
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    includeTypeNameSuggestions = true;
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    Token equals = node.equals;
    // Make suggestions for the RHS of a variable declaration
    if (equals != null && offset >= equals.end) {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    if (isAfterSemicolon(node.semicolon)) {
      includeReturnValueSuggestions = true;
      includeTypeNameSuggestions = true;
      includeVoidReturnSuggestions = true;
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && leftParen.end <= offset) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || offset <= rightParen.offset) {
        includeReturnValueSuggestions = true;
        includeTypeNameSuggestions = true;
      }
    }
  }
}
