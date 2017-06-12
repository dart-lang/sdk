// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

const ASYNC_STAR = 'async*';
const DEFERRED_AS = 'deferred as';
const EXPORT_STATEMENT = "export '';";
const IMPORT_STATEMENT = "import '';";
const PART_STATEMENT = "part '';";
const SYNC_STAR = 'sync*';
const YIELD_STAR = 'yield*';

/**
 * A contributor for calculating `completion.getSuggestions` request results
 * for the local library in which the completion is requested.
 */
class KeywordContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    request.target.containingNode
        .accept(new _KeywordVisitor(request, suggestions));
    return suggestions;
  }
}

/**
 * A visitor for generating keyword suggestions.
 */
class _KeywordVisitor extends GeneralizingAstVisitor {
  final DartCompletionRequest request;
  final Object entity;
  final List<CompletionSuggestion> suggestions;

  _KeywordVisitor(DartCompletionRequest request, this.suggestions)
      : this.request = request,
        this.entity = request.target.entity;

  @override
  visitArgumentList(ArgumentList node) {
    if (request is DartCompletionRequestImpl) {
      //TODO(danrubel) consider adding opType to the API then remove this cast
      OpType opType = (request as DartCompletionRequestImpl).opType;
      if (opType.includeOnlyNamedArgumentSuggestions) {
        return;
      }
    }
    if (entity == node.rightParenthesis) {
      _addExpressionKeywords(node);
      Token previous = (entity as Token).previous;
      if (previous.isSynthetic) {
        previous = previous.previous;
      }
      if (previous.lexeme == ')') {
        _addSuggestion(Keyword.ASYNC);
        _addSuggestion2(ASYNC_STAR);
        _addSuggestion2(SYNC_STAR);
      }
    }
    if (entity is SimpleIdentifier && node.arguments.contains(entity)) {
      _addExpressionKeywords(node);
    }
  }

  @override
  visitAsExpression(AsExpression node) {
    if (identical(entity, node.asOperator) &&
        node.expression is ParenthesizedExpression) {
      _addSuggestion(Keyword.ASYNC, DART_RELEVANCE_HIGH);
      _addSuggestion2(ASYNC_STAR, relevance: DART_RELEVANCE_HIGH);
      _addSuggestion2(SYNC_STAR, relevance: DART_RELEVANCE_HIGH);
    }
  }

  @override
  visitBlock(Block node) {
    Statement prevStmt = OpType.getPreviousStatement(node, entity);
    if (prevStmt is TryStatement) {
      if (prevStmt.finallyBlock == null) {
        _addSuggestion(Keyword.ON);
        _addSuggestion(Keyword.CATCH);
        _addSuggestion(Keyword.FINALLY);
        if (prevStmt.catchClauses.isEmpty) {
          // If try statement with no catch, on, or finally
          // then only suggest these keywords
          return;
        }
      }
    }

    if (entity is ExpressionStatement) {
      Expression expression = (entity as ExpressionStatement).expression;
      if (expression is SimpleIdentifier) {
        Token token = expression.token;
        Token previous = token.previous;
        if (previous.isSynthetic) {
          previous = previous.previous;
        }
        Token next = token.next;
        if (next.isSynthetic) {
          next = next.next;
        }
        if (previous.type == TokenType.CLOSE_PAREN &&
            next.type == TokenType.OPEN_CURLY_BRACKET) {
          _addSuggestion(Keyword.ASYNC);
          _addSuggestion2(ASYNC_STAR);
          _addSuggestion2(SYNC_STAR);
        }
      }
    }
    _addStatementKeywords(node);
    if (_inCatchClause(node)) {
      _addSuggestion(Keyword.RETHROW, DART_RELEVANCE_KEYWORD - 1);
    }
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    // Don't suggest class name
    if (entity == node.name) {
      return;
    }
    if (entity == node.rightBracket) {
      _addClassBodyKeywords();
    } else if (entity is ClassMember) {
      _addClassBodyKeywords();
      int index = node.members.indexOf(entity);
      ClassMember previous = index > 0 ? node.members[index - 1] : null;
      if (previous is MethodDeclaration && previous.body is EmptyFunctionBody) {
        _addSuggestion(Keyword.ASYNC);
        _addSuggestion2(ASYNC_STAR);
        _addSuggestion2(SYNC_STAR);
      }
    } else {
      _addClassDeclarationKeywords(node);
    }
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    var previousMember = null;
    for (var member in node.childEntities) {
      if (entity == member) {
        break;
      }
      previousMember = member;
    }
    if (previousMember is ClassDeclaration) {
      if (previousMember.leftBracket == null ||
          previousMember.leftBracket.isSynthetic) {
        // If the prior member is an unfinished class declaration
        // then the user is probably finishing that
        _addClassDeclarationKeywords(previousMember);
        return;
      }
    }
    if (previousMember is ImportDirective) {
      if (previousMember.semicolon == null ||
          previousMember.semicolon.isSynthetic) {
        // If the prior member is an unfinished import directive
        // then the user is probably finishing that
        _addImportDirectiveKeywords(previousMember);
        return;
      }
    }
    if (previousMember == null || previousMember is Directive) {
      if (previousMember == null &&
          !node.directives.any((d) => d is LibraryDirective)) {
        _addSuggestions([Keyword.LIBRARY], DART_RELEVANCE_HIGH);
      }
      _addSuggestion2(IMPORT_STATEMENT,
          offset: 8, relevance: DART_RELEVANCE_HIGH);
      _addSuggestion2(EXPORT_STATEMENT,
          offset: 8, relevance: DART_RELEVANCE_HIGH);
      _addSuggestion2(PART_STATEMENT,
          offset: 6, relevance: DART_RELEVANCE_HIGH);
    }
    if (entity == null || entity is Declaration) {
      if (previousMember is FunctionDeclaration &&
          previousMember.functionExpression is FunctionExpression &&
          previousMember.functionExpression.body is EmptyFunctionBody) {
        _addSuggestion(Keyword.ASYNC, DART_RELEVANCE_HIGH);
        _addSuggestion2(ASYNC_STAR, relevance: DART_RELEVANCE_HIGH);
        _addSuggestion2(SYNC_STAR, relevance: DART_RELEVANCE_HIGH);
      }
      _addCompilationUnitKeywords();
    }
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.initializers.isNotEmpty && node.initializers.last == entity) {
      _addSuggestion(Keyword.SUPER);
    }
  }

  @override
  visitDefaultFormalParameter(DefaultFormalParameter node) {
    if (entity == node.defaultValue) {
      _addExpressionKeywords(node);
    }
  }

  @override
  visitExpression(Expression node) {
    _addExpressionKeywords(node);
  }

  @override
  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (entity == node.expression) {
      _addExpressionKeywords(node);
    }
  }

  @override
  visitForEachStatement(ForEachStatement node) {
    if (entity == node.inKeyword) {
      Token previous = node.inKeyword.previous;
      if (previous is SyntheticStringToken && previous.lexeme == 'in') {
        previous = previous.previous;
      }
      if (previous != null && previous.type == TokenType.EQ) {
        _addSuggestions([
          Keyword.CONST,
          Keyword.FALSE,
          Keyword.NEW,
          Keyword.NULL,
          Keyword.TRUE
        ]);
      } else {
        _addSuggestion(Keyword.IN, DART_RELEVANCE_HIGH);
      }
    }
  }

  @override
  visitFormalParameterList(FormalParameterList node) {
    AstNode constructorDeclaration =
        node.getAncestor((p) => p is ConstructorDeclaration);
    if (constructorDeclaration != null) {
      _addSuggestions([Keyword.THIS]);
    }
  }

  @override
  visitForStatement(ForStatement node) {
    // Actual: for (va^)
    // Parsed: for (va^; ;)
    if (node.initialization == entity && entity is SimpleIdentifier) {
      if (_isNextTokenSynthetic(entity, TokenType.SEMICOLON)) {
        _addSuggestion(Keyword.VAR, DART_RELEVANCE_HIGH);
      }
    }
    // Actual: for (int x i^)
    // Parsed: for (int x; i^;)
    // Handle the degenerate case while typing - for (int x i^)
    if (node.condition == entity &&
        entity is SimpleIdentifier &&
        node.variables != null) {
      if (_isPreviousTokenSynthetic(entity, TokenType.SEMICOLON)) {
        _addSuggestion(Keyword.IN, DART_RELEVANCE_HIGH);
      }
    }
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    if (entity == node.body) {
      FunctionBody body = node.body;
      if (!body.isAsynchronous) {
        _addSuggestion(Keyword.ASYNC, DART_RELEVANCE_HIGH);
        if (body is! ExpressionFunctionBody) {
          _addSuggestion2(ASYNC_STAR, relevance: DART_RELEVANCE_HIGH);
          _addSuggestion2(SYNC_STAR, relevance: DART_RELEVANCE_HIGH);
        }
      }
      if (node.body is EmptyFunctionBody &&
          node.parent is FunctionDeclaration &&
          node.parent.parent is CompilationUnit) {
        _addCompilationUnitKeywords();
      }
    }
  }

  @override
  visitIfStatement(IfStatement node) {
    if (_isPreviousTokenSynthetic(entity, TokenType.CLOSE_PAREN)) {
      // Actual: if (x i^)
      // Parsed: if (x) i^
      _addSuggestion(Keyword.IS, DART_RELEVANCE_HIGH);
    } else if (entity == node.thenStatement || entity == node.elseStatement) {
      _addStatementKeywords(node);
    } else if (entity == node.condition) {
      _addExpressionKeywords(node);
    }
  }

  @override
  visitImportDirective(ImportDirective node) {
    if (entity == node.asKeyword) {
      if (node.deferredKeyword == null) {
        _addSuggestion(Keyword.DEFERRED, DART_RELEVANCE_HIGH);
      }
    }
    // Handle degenerate case where import statement does not have a semicolon
    // and the cursor is in the uri string
    if ((entity == node.semicolon &&
            node.uri != null &&
            node.uri.offset + 1 != request.offset) ||
        node.combinators.contains(entity)) {
      _addImportDirectiveKeywords(node);
    }
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (entity == node.constructorName) {
      // no keywords in 'new ^' expression
    } else {
      super.visitInstanceCreationExpression(node);
    }
  }

  @override
  visitIsExpression(IsExpression node) {
    if (entity == node.isOperator) {
      _addSuggestion(Keyword.IS, DART_RELEVANCE_HIGH);
    } else {
      _addExpressionKeywords(node);
    }
  }

  @override
  visitLibraryIdentifier(LibraryIdentifier node) {
    // no suggestions
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    if (entity == node.body) {
      if (node.body is EmptyFunctionBody) {
        _addClassBodyKeywords();
        _addSuggestion(Keyword.ASYNC);
        _addSuggestion2(ASYNC_STAR);
        _addSuggestion2(SYNC_STAR);
      } else {
        _addSuggestion(Keyword.ASYNC, DART_RELEVANCE_HIGH);
        if (node.body is! ExpressionFunctionBody) {
          _addSuggestion2(ASYNC_STAR, relevance: DART_RELEVANCE_HIGH);
          _addSuggestion2(SYNC_STAR, relevance: DART_RELEVANCE_HIGH);
        }
      }
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (entity == node.methodName) {
      // no keywords in '.' expression
    } else {
      super.visitMethodInvocation(node);
    }
  }

  @override
  visitNamedExpression(NamedExpression node) {
    if (entity is SimpleIdentifier && entity == node.expression) {
      _addExpressionKeywords(node);
    }
  }

  @override
  visitNode(AstNode node) {
    // ignored
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (entity != node.identifier) {
      _addExpressionKeywords(node);
    }
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    // suggestions before '.' but not after
    if (entity != node.propertyName) {
      super.visitPropertyAccess(node);
    }
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    if (entity == node.expression) {
      _addExpressionKeywords(node);
    }
  }

  @override
  visitStringLiteral(StringLiteral node) {
    // ignored
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    if (entity == node.expression) {
      _addExpressionKeywords(node);
    } else if (entity == node.rightBracket) {
      if (node.members.isEmpty) {
        _addSuggestions([Keyword.CASE, Keyword.DEFAULT], DART_RELEVANCE_HIGH);
      } else {
        _addSuggestions([Keyword.CASE, Keyword.DEFAULT]);
        _addStatementKeywords(node);
      }
    }
    if (node.members.contains(entity)) {
      if (entity == node.members.first) {
        _addSuggestions([Keyword.CASE, Keyword.DEFAULT], DART_RELEVANCE_HIGH);
      } else {
        _addSuggestions([Keyword.CASE, Keyword.DEFAULT]);
        _addStatementKeywords(node);
      }
    }
  }

  @override
  visitTryStatement(TryStatement node) {
    var obj = entity;
    if (obj is CatchClause ||
        (obj is KeywordToken && obj.value() == Keyword.FINALLY)) {
      _addSuggestion(Keyword.ON);
      _addSuggestion(Keyword.CATCH);
      return null;
    }
    return visitStatement(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    if (entity == node.initializer) {
      _addExpressionKeywords(node);
    }
  }

  void _addClassBodyKeywords() {
    _addSuggestions([
      Keyword.CONST,
      Keyword.DYNAMIC,
      Keyword.FACTORY,
      Keyword.FINAL,
      Keyword.GET,
      Keyword.OPERATOR,
      Keyword.SET,
      Keyword.STATIC,
      Keyword.VAR,
      Keyword.VOID
    ]);
  }

  void _addClassDeclarationKeywords(ClassDeclaration node) {
    // Very simplistic suggestion because analyzer will warn if
    // the extends / with / implements keywords are out of order
    if (node.extendsClause == null) {
      _addSuggestion(Keyword.EXTENDS, DART_RELEVANCE_HIGH);
    } else if (node.withClause == null) {
      _addSuggestion(Keyword.WITH, DART_RELEVANCE_HIGH);
    }
    if (node.implementsClause == null) {
      _addSuggestion(Keyword.IMPLEMENTS, DART_RELEVANCE_HIGH);
    }
  }

  void _addCompilationUnitKeywords() {
    _addSuggestions([
      Keyword.ABSTRACT,
      Keyword.CLASS,
      Keyword.CONST,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.TYPEDEF,
      Keyword.VAR,
      Keyword.VOID
    ], DART_RELEVANCE_HIGH);
  }

  void _addExpressionKeywords(AstNode node) {
    _addSuggestions([
      Keyword.CONST,
      Keyword.FALSE,
      Keyword.NEW,
      Keyword.NULL,
      Keyword.TRUE,
    ]);
    if (_inClassMemberBody(node)) {
      _addSuggestions([Keyword.SUPER, Keyword.THIS]);
    }
    if (_inAsyncMethodOrFunction(node)) {
      _addSuggestion(Keyword.AWAIT);
    }
  }

  void _addImportDirectiveKeywords(ImportDirective node) {
    bool hasDeferredKeyword = node.deferredKeyword != null;
    bool hasAsKeyword = node.asKeyword != null;
    if (!hasAsKeyword) {
      _addSuggestion(Keyword.AS, DART_RELEVANCE_HIGH);
    }
    if (!hasDeferredKeyword) {
      if (!hasAsKeyword) {
        _addSuggestion2(DEFERRED_AS, relevance: DART_RELEVANCE_HIGH);
      } else if (entity == node.asKeyword) {
        _addSuggestion(Keyword.DEFERRED, DART_RELEVANCE_HIGH);
      }
    }
    if (!hasDeferredKeyword || hasAsKeyword) {
      if (node.combinators.isEmpty) {
        _addSuggestion(Keyword.SHOW, DART_RELEVANCE_HIGH);
        _addSuggestion(Keyword.HIDE, DART_RELEVANCE_HIGH);
      }
    }
  }

  void _addStatementKeywords(AstNode node) {
    if (_inClassMemberBody(node)) {
      _addSuggestions([Keyword.SUPER, Keyword.THIS]);
    }
    if (_inAsyncMethodOrFunction(node)) {
      _addSuggestion(Keyword.AWAIT);
    } else if (_inAsyncStarOrSyncStarMethodOrFunction(node)) {
      _addSuggestion(Keyword.AWAIT);
      _addSuggestion(Keyword.YIELD);
      _addSuggestion2(YIELD_STAR);
    }
    if (_inLoop(node)) {
      _addSuggestions([Keyword.BREAK, Keyword.CONTINUE]);
    }
    if (_inSwitch(node)) {
      _addSuggestions([Keyword.BREAK]);
    }
    if (_isEntityAfterIfWithoutElse(node)) {
      _addSuggestions([Keyword.ELSE]);
    }
    _addSuggestions([
      Keyword.ASSERT,
      Keyword.CONST,
      Keyword.DO,
      Keyword.FINAL,
      Keyword.FOR,
      Keyword.IF,
      Keyword.NEW,
      Keyword.RETURN,
      Keyword.SWITCH,
      Keyword.THROW,
      Keyword.TRY,
      Keyword.VAR,
      Keyword.VOID,
      Keyword.WHILE
    ]);
  }

  void _addSuggestion(Keyword keyword,
      [int relevance = DART_RELEVANCE_KEYWORD]) {
    _addSuggestion2(keyword.lexeme, relevance: relevance);
  }

  void _addSuggestion2(String completion,
      {int offset, int relevance: DART_RELEVANCE_KEYWORD}) {
    if (offset == null) {
      offset = completion.length;
    }
    suggestions.add(new CompletionSuggestion(CompletionSuggestionKind.KEYWORD,
        relevance, completion, offset, 0, false, false));
  }

  void _addSuggestions(List<Keyword> keywords,
      [int relevance = DART_RELEVANCE_KEYWORD]) {
    keywords.forEach((Keyword keyword) {
      _addSuggestion(keyword, relevance);
    });
  }

  bool _inAsyncMethodOrFunction(AstNode node) {
    FunctionBody body = node.getAncestor((n) => n is FunctionBody);
    return body != null && body.isAsynchronous && body.star == null;
  }

  bool _inAsyncStarOrSyncStarMethodOrFunction(AstNode node) {
    FunctionBody body = node.getAncestor((n) => n is FunctionBody);
    return body != null && body.keyword != null && body.star != null;
  }

  bool _inCatchClause(Block node) =>
      node.getAncestor((p) => p is CatchClause) != null;

  bool _inClassMemberBody(AstNode node) {
    while (true) {
      AstNode body = node.getAncestor((n) => n is FunctionBody);
      if (body == null) {
        return false;
      }
      AstNode parent = body.parent;
      if (parent is ConstructorDeclaration || parent is MethodDeclaration) {
        return true;
      }
      node = parent;
    }
  }

  bool _inDoLoop(AstNode node) =>
      node.getAncestor((p) => p is DoStatement) != null;

  bool _inForLoop(AstNode node) =>
      node.getAncestor((p) => p is ForStatement || p is ForEachStatement) !=
      null;

  bool _inLoop(AstNode node) =>
      _inDoLoop(node) || _inForLoop(node) || _inWhileLoop(node);

  bool _inSwitch(AstNode node) =>
      node.getAncestor((p) => p is SwitchStatement) != null;

  bool _inWhileLoop(AstNode node) =>
      node.getAncestor((p) => p is WhileStatement) != null;

  bool _isEntityAfterIfWithoutElse(AstNode node) {
    Block block = node?.getAncestor((n) => n is Block);
    if (block == null) {
      return false;
    }
    Object entity = this.entity;
    if (entity is Statement) {
      int entityIndex = block.statements.indexOf(entity);
      if (entityIndex > 0) {
        Statement prevStatement = block.statements[entityIndex - 1];
        return prevStatement is IfStatement &&
            prevStatement.elseStatement == null;
      }
    }
    if (entity is Token) {
      for (Statement statement in block.statements) {
        if (statement.endToken.next == entity) {
          return statement is IfStatement && statement.elseStatement == null;
        }
      }
    }
    return false;
  }

  static bool _isNextTokenSynthetic(Object entity, TokenType type) {
    if (entity is AstNode) {
      Token token = entity.beginToken;
      Token nextToken = token.next;
      return nextToken.isSynthetic && nextToken.type == type;
    }
    return false;
  }

  static bool _isPreviousTokenSynthetic(Object entity, TokenType type) {
    if (entity is AstNode) {
      Token token = entity.beginToken;
      Token previousToken = token.previous;
      return previousToken.isSynthetic && previousToken.type == type;
    }
    return false;
  }
}
