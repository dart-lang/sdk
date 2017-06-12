// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.dart.sorter.common;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/contribution_sorter.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';

part 'common_usage_sorter.g.dart';

/**
 * A computer for adjusting the relevance of completions computed by others
 * based upon common Dart usage patterns. This is a long-lived object
 * that should not maintain state between calls to it's [sort] method.
 */
class CommonUsageSorter implements DartContributionSorter {
  /**
   * A map of <library>.<classname> to an ordered list of method names,
   * field names, getter names, and named constructors.
   * The names are ordered from most relevant to least relevant.
   * Names not listed are considered equally less relevant than those listed.
   */
  Map<String, List<String>> selectorRelevance;

  CommonUsageSorter([this.selectorRelevance = defaultSelectorRelevance]);

  @override
  Future sort(DartCompletionRequest request,
      Iterable<CompletionSuggestion> suggestions) {
    _update(request, suggestions);
    return new Future.value();
  }

  CompletionTarget _getCompletionTarget(CompletionRequest request) =>
      new CompletionTarget.forOffset(request.result.unit, request.offset);

  /**
   * Adjusts the relevance based on the given completion context.
   * The compilation unit and completion node
   * in the given completion context may not be resolved.
   */
  void _update(
      CompletionRequest request, Iterable<CompletionSuggestion> suggestions) {
    var target = _getCompletionTarget(request);
    if (target != null) {
      var visitor = new _BestTypeVisitor(target.entity);
      DartType type = target.containingNode.accept(visitor);
      if (type != null) {
        Element typeElem = type.element;
        if (typeElem != null) {
          LibraryElement libElem = typeElem.library;
          if (libElem != null) {
            _updateInvocationRelevance(type, libElem, suggestions);
          }
        }
      }
    }
  }

  /**
   * Adjusts the relevance of all method suggestions based upon the given
   * target type and library.
   */
  void _updateInvocationRelevance(DartType type, LibraryElement libElem,
      Iterable<CompletionSuggestion> suggestions) {
    String typeName = type.name;
    List<String> selectors = selectorRelevance['${libElem.name}.$typeName'];
    if (selectors != null) {
      for (CompletionSuggestion suggestion in suggestions) {
        protocol.Element element = suggestion.element;
        if (element != null &&
            (element.kind == protocol.ElementKind.CONSTRUCTOR ||
                element.kind == protocol.ElementKind.FIELD ||
                element.kind == protocol.ElementKind.GETTER ||
                element.kind == protocol.ElementKind.METHOD ||
                element.kind == protocol.ElementKind.SETTER) &&
            suggestion.kind == CompletionSuggestionKind.INVOCATION &&
            suggestion.declaringType == typeName) {
          int index = selectors.indexOf(suggestion.completion);
          if (index != -1) {
            suggestion.relevance = DART_RELEVANCE_COMMON_USAGE - index;
          }
        }
      }
    }
  }
}

/**
 * An [AstVisitor] used to determine the best defining type of a node.
 */
class _BestTypeVisitor extends GeneralizingAstVisitor<DartType> {
  /**
   * The entity which the completed text will replace (or which will be
   * displaced once the completed text is inserted).  This may be an AstNode or
   * a Token, or it may be null if the cursor is after all tokens in the file.
   * See field of the same name in [CompletionTarget].
   */
  final Object entity;

  _BestTypeVisitor(this.entity);

  DartType visitConstructorName(ConstructorName node) =>
      node.period != null && node.name == entity ? node.type?.type : null;

  DartType visitNode(AstNode node) {
    return null;
  }

  DartType visitPrefixedIdentifier(PrefixedIdentifier node) =>
      node.identifier == entity ? node.prefix?.bestType : null;

  DartType visitPropertyAccess(PropertyAccess node) =>
      node.propertyName == entity ? node.realTarget?.bestType : null;
}
