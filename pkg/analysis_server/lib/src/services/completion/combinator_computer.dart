// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.combinator;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart' hide Element,
    ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/suggestion_builder.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A computer for calculating `completion.getSuggestions` request results
 * for the import combinators show and hide.
 */
class CombinatorComputer extends DartCompletionComputer {
  _CombinatorSuggestionBuilder builder;

  @override
  bool computeFast(DartCompletionRequest request) {
    builder = request.node.accept(new _CombinatorAstVisitor(request));
    return builder == null;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    if (builder != null) {
      return builder.execute(request.node);
    }
    return new Future.value(false);
  }
}

/**
 * A visitor for determining which imported classes and top level variables
 * should be suggested and building those suggestions.
 */
class _CombinatorAstVisitor extends
    GeneralizingAstVisitor<_CombinatorSuggestionBuilder> {
  final DartCompletionRequest request;

  _CombinatorAstVisitor(this.request);

  @override
  _CombinatorSuggestionBuilder visitCombinator(Combinator node) {
    return new _CombinatorSuggestionBuilder(
        request,
        CompletionSuggestionKind.IDENTIFIER);
  }

  @override
  _CombinatorSuggestionBuilder visitNode(AstNode node) {
    return null;
  }

  @override
  _CombinatorSuggestionBuilder visitSimpleIdentifier(SimpleIdentifier node) {
    return node.parent.accept(this);
  }
}

/**
 * A `_CombinatorSuggestionBuilder` determines which imported classes
 * and top level variables should be suggested and builds those suggestions.
 * This operation is instantiated during `computeFast`
 * and calculates the suggestions during `computeFull`.
 */
class _CombinatorSuggestionBuilder extends LibraryElementSuggestionBuilder {

  _CombinatorSuggestionBuilder(DartCompletionRequest request,
      CompletionSuggestionKind kind)
      : super(request, kind);

  Future<bool> execute(AstNode node) {
    var directive = node.getAncestor((parent) => parent is NamespaceDirective);
    if (directive is NamespaceDirective) {
      LibraryElement library = directive.uriElement;
      if (library != null) {
        library.visitChildren(this);
      }
    }
    return new Future.value(false);
  }
}
