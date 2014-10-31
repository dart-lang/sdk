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

  @override
  bool computeFast(DartCompletionRequest request) {
    return false;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    return request.node.accept(new _CombinatorAstVisitor(request));
  }
}

/**
 * A visitor for determining which imported classes and top level variables
 * should be suggested and building those suggestions.
 */
class _CombinatorAstVisitor extends GeneralizingAstVisitor<Future<bool>> {
  final DartCompletionRequest request;

  _CombinatorAstVisitor(this.request);

  @override
  Future<bool> visitCombinator(Combinator node) {
    return _addCombinatorSuggestions(node);
  }

  @override
  Future<bool> visitNode(AstNode node) {
    return new Future.value(false);
  }

  @override
  Future<bool> visitSimpleIdentifier(SimpleIdentifier node) {
    return node.parent.accept(this);
  }

  Future _addCombinatorSuggestions(Combinator node) {
    var directive = node.getAncestor((parent) => parent is NamespaceDirective);
    if (directive is NamespaceDirective) {
      LibraryElement library = directive.uriElement;
      LibraryElementSuggestionBuilder.suggestionsFor(
          request,
          CompletionSuggestionKind.IDENTIFIER,
          library);
      return new Future.value(true);
    }
    return new Future.value(false);
  }
}