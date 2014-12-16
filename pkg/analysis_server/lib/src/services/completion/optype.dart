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
class OpType {

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

  /**
   * Determine the suggestions that should be made based upon the given
   * [AstNode] and offset.
   */
  factory OpType.forCompletion(AstNode node, int offset) {
    OpType optype = new OpType._();
    node.accept(new _OpTypeAstVisitor(optype, offset));
    return optype;
  }

  OpType._();

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

}

class _OpTypeAstVisitor extends GeneralizingAstVisitor {

  /**
   * The offset within the source at which the completion is requested.
   */
  final int offset;

  /**
   * The [OpType] being initialized
   */
  final OpType optype;

  _OpTypeAstVisitor(this.optype, this.offset);

  bool isAfterSemicolon(Token semicolon) =>
      semicolon != null && !semicolon.isSynthetic && semicolon.offset < offset;

  @override
  void visitAnnotation(Annotation node) {
    Token atSign = node.atSign;
    if (atSign == null || offset <= atSign.offset) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
    } else {
      Token period = node.period;
      if (period == null || offset <= period.offset) {
        optype.includeTypeNameSuggestions = true;
        optype.includeReturnValueSuggestions = true;
      } else {
        optype.includeInvocationSuggestions = true;
      }
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitBlock(Block node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
    optype.includeVoidReturnSuggestions = true;
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    Expression target = node.target;
    if (target != null && offset <= target.end) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    } else {
      optype.includeInvocationSuggestions = true;
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Make suggestions in the body of the class declaration
    Token leftBracket = node.leftBracket;
    if (leftBracket != null && offset >= leftBracket.end) {
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitClassMember(ClassMember node) {
    if (offset <= node.offset || node.end <= offset) {
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitCommentReference(CommentReference node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
    optype.includeVoidReturnSuggestions = true;
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
          optype.includeInvocationSuggestions = true;
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
        optype.includeReturnValueSuggestions = true;
        optype.includeTypeNameSuggestions = true;
      }
    }
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
    optype.includeVoidReturnSuggestions = true;
  }

  @override
  void visitExpression(Expression node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    Token functionDefinition = node.functionDefinition;
    if (functionDefinition != null && functionDefinition.end <= offset) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    Expression expression = node.expression;
    // A pre-variable declaration (e.g. C ^) is parsed as an expression
    // statement. Do not make suggestions for the variable name.
    if (expression is SimpleIdentifier && offset <= expression.end) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
    } else {
      Token semicolon = node.semicolon;
      if (semicolon != null && semicolon.end <= offset) {
        optype.includeReturnValueSuggestions = true;
        optype.includeTypeNameSuggestions = true;
        optype.includeVoidReturnSuggestions = true;
      }
    }
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    Token keyword = node.keyword;
    if (keyword != null && keyword.end < offset) {
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && leftParen.end <= offset) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || offset <= rightParen.offset) {
        optype.includeReturnValueSuggestions = true;
        optype.includeTypeNameSuggestions = true;
      }
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && offset > leftParen.offset) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || offset <= rightParen.offset) {
        optype.includeReturnValueSuggestions = true;
        optype.includeTypeNameSuggestions = true;
      }
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && offset >= leftParen.end) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
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
          optype.includeTypeNameSuggestions = true;
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
        optype.includeReturnValueSuggestions = true;
        optype.includeTypeNameSuggestions = true;
      }
    }
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    Token keyword = node.keyword;
    if (keyword != null && keyword.end < offset) {
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    Expression expression = node.expression;
    if (expression is SimpleIdentifier) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    SimpleIdentifier id = node.name;
    if (id != null && offset < id.offset) {
      optype.includeTypeNameSuggestions = true;
    }
    visitClassMember(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    Token period = node.period;
    if (period == null || offset <= period.offset) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    } else {
      optype.includeInvocationSuggestions = true;
    }
  }

  @override
  void visitNode(AstNode node) {
    // no suggestion by default
  }

  @override
  void visitNormalFormalParameter(NormalFormalParameter node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    Token period = node.period;
    if (period == null || offset <= period.offset) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    } else {
      optype.includeInvocationSuggestions = true;
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    var operator = node.operator;
    if (operator != null && offset < operator.offset) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    } else {
      optype.includeInvocationSuggestions = true;
    }
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    Token keyword = node.keyword;
    if (keyword != null && keyword.end < offset) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
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
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && leftParen.end <= offset) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || offset <= rightParen.offset) {
        optype.includeReturnValueSuggestions = true;
        optype.includeTypeNameSuggestions = true;
      }
    }
  }

  @override
  void visitTypeName(TypeName node) {
    // If suggesting completions within a TypeName node
    // then limit suggestions to only types in specific situations
    AstNode p = node.parent;
    if (p is IsExpression || p is ConstructorName || p is AsExpression) {
      optype.includeTypeNameSuggestions = true;
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
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
    } else {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
    }
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    Token equals = node.equals;
    // Make suggestions for the RHS of a variable declaration
    if (equals != null && offset >= equals.end) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    if (isAfterSemicolon(node.semicolon)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && leftParen.end <= offset) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || offset <= rightParen.offset) {
        optype.includeReturnValueSuggestions = true;
        optype.includeTypeNameSuggestions = true;
      }
    }
  }
}
