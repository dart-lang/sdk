// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.keyword;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';

/**
 * A contributor for calculating `completion.getSuggestions` request results
 * for the local library in which the completion is requested.
 */
class KeywordContributor extends DartCompletionContributor {
  @override
  bool computeFast(DartCompletionRequest request) {
    request.target.containingNode.accept(new _KeywordVisitor(request));
    return true;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    return new Future.value(false);
  }
}

/**
 * A vistor for generating keyword suggestions.
 */
class _KeywordVisitor extends GeneralizingAstVisitor {
  final DartCompletionRequest request;
  final Object entity;

  _KeywordVisitor(DartCompletionRequest request)
      : this.request = request,
        this.entity = request.target.entity;

  @override
  visitBlock(Block node) {
    if (_isInClassMemberBody(node)) {
      _addSuggestions([Keyword.SUPER, Keyword.THIS,]);
    }
    _addSuggestions([
      Keyword.ASSERT,
      Keyword.CASE,
      Keyword.CONTINUE,
      Keyword.DO,
      Keyword.FINAL,
      Keyword.FOR,
      Keyword.IF,
      Keyword.NEW,
      Keyword.RETHROW,
      Keyword.RETURN,
      Keyword.SWITCH,
      Keyword.THROW,
      Keyword.TRY,
      Keyword.VAR,
      Keyword.VOID,
      Keyword.WHILE
    ]);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    // Don't suggest class name
    if (entity == node.name) {
      return;
    }
    if (entity == node.rightBracket || entity is ClassMember) {
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
      return;
    }
    _addClassDeclarationKeywords(node);
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
      _addSuggestions(
          [Keyword.EXPORT, Keyword.IMPORT, Keyword.PART], DART_RELEVANCE_HIGH);
    }
    if (entity == null || entity is Declaration) {
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
  }

  @override
  visitImportDirective(ImportDirective node) {
    if (entity == node.asKeyword) {
      if (node.deferredKeyword == null) {
        _addSuggestion(Keyword.DEFERRED, DART_RELEVANCE_HIGH);
      }
    }
    if (entity == node.semicolon || node.combinators.contains(entity)) {
      _addImportDirectiveKeywords(node);
    }
  }

  void _addImportDirectiveKeywords(ImportDirective node) {
    if (node.asKeyword == null) {
      _addSuggestion(Keyword.AS, DART_RELEVANCE_HIGH);
      if (node.deferredKeyword == null) {
        _addSuggestion(Keyword.DEFERRED, DART_RELEVANCE_HIGH);
      }
    }
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

  void _addSuggestion(Keyword keyword,
      [int relevance = DART_RELEVANCE_DEFAULT]) {
    String completion = keyword.syntax;
    request.addSuggestion(new CompletionSuggestion(
        CompletionSuggestionKind.KEYWORD, relevance, completion,
        completion.length, 0, false, false));
  }

  void _addSuggestions(List<Keyword> keywords,
      [int relevance = DART_RELEVANCE_KEYWORD]) {
    keywords.forEach((Keyword keyword) {
      _addSuggestion(keyword, relevance);
    });
  }

  bool _isInClassMemberBody(AstNode node) {
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
}
