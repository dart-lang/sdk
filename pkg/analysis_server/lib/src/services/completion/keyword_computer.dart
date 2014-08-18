// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.keyword;

import 'dart:async';

import 'package:analysis_server/src/services/completion/completion_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';

/**
 * A computer for calculating `completion.getSuggestions` request results
 * for the local library in which the completion is requested.
 */
class KeywordComputer extends DartCompletionComputer {

  @override
  bool computeFast(DartCompletionRequest request) {
    request.node.accept(new _KeywordVisitor(request));
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

  _KeywordVisitor(this.request);

  @override
  visitClassDeclaration(ClassDeclaration node) {
    _addSuggestions([Keyword.EXTENDS, Keyword.IMPLEMENTS, Keyword.WITH]);
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    _addSuggestions(
        [
            Keyword.ABSTRACT,
            Keyword.CLASS,
            Keyword.CONST,
            Keyword.EXPORT,
            Keyword.FINAL,
            Keyword.IMPORT,
            Keyword.LIBRARY,
            Keyword.PART,
            Keyword.TYPEDEF,
            Keyword.VAR]);
  }

  @override
  visitNode(AstNode node) {
    // ignored
  }

  void _addSuggestions(List<Keyword> keywords) {
    keywords.forEach((Keyword keyword) {
      String completion = keyword.syntax;
      request.suggestions.add(
          new CompletionSuggestion(
              CompletionSuggestionKind.KEYWORD,
              CompletionRelevance.DEFAULT,
              completion,
              completion.length,
              0,
              false,
              false));
    });
  }
}
