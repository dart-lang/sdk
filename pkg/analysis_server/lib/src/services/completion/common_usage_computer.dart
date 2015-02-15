// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.relevance;

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart' show
    CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A map of <library>.<classname> to an ordered list of method names,
 * field names, getter names, and named constructors.
 * The names are ordered from most relevant to least relevant.
 * Names not listed are considered equally less relevant than those listed.
 */
const Map<String, List<String>> defaultSelectorRelevance = const {//
// Sample implementation which updates the relevance of the following
//     new Random().nextInt(...)
//     new Random().nextDouble(...)
//     new Random().nextBool() - not commonly used thus omitted from list
// Entries should look something like this
//     'dart.math.Random': const ['nextInt', 'nextDouble'],
//     'dart.async.Future': const ['value', 'wait'],
};

/**
 * A computer for adjusting the relevance of completions computed by others
 * based upon common Dart usage patterns.
 */
class CommonUsageComputer {
  /**
   * A map of <library>.<classname> to an ordered list of method names,
   * field names, getter names, and named constructors.
   * The names are ordered from most relevant to least relevant.
   * Names not listed are considered equally less relevant than those listed.
   */
  Map<String, List<String>> selectorRelevance;

  CommonUsageComputer([this.selectorRelevance = defaultSelectorRelevance]);

  /**
   * Adjusts the relevance based on the given completion context.
   * The compilation unit and completion node
   * in the given completion context may not be resolved.
   * This method should execute quickly and not block waiting for any analysis.
   */
  void computeFast(DartCompletionRequest request) {
    _update(request);
  }

  /**
   * Adjusts the relevance based on the given completion context.
   * The compilation unit and completion node
   * in the given completion context are resolved.
   */
  void computeFull(DartCompletionRequest request) {
    _update(request);
  }

  /**
   * Adjusts the relevance based on the given completion context.
   * The compilation unit and completion node
   * in the given completion context may not be resolved.
   */
  void _update(DartCompletionRequest request) {
    var visitor = new _BestTypeVisitor(request.target.entity);
    DartType type = request.target.containingNode.accept(visitor);
    if (type != null) {
      Element typeElem = type.element;
      if (typeElem != null) {
        LibraryElement libElem = typeElem.library;
        if (libElem != null) {
          _updateInvocationRelevance(request, type, libElem);
        }
      }
    }
  }

  /**
   * Adjusts the relevance of all method suggestions based upon the given
   * target type and library.
   */
  void _updateInvocationRelevance(DartCompletionRequest request, DartType type,
      LibraryElement libElem) {
    String typeName = type.name;
    List<String> selectors = selectorRelevance['${libElem.name}.${typeName}'];
    if (selectors != null) {
      for (CompletionSuggestion suggestion in request.suggestions) {
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
class _BestTypeVisitor extends GeneralizingAstVisitor {

  /**
   * The entity which the completed text will replace (or which will be
   * displaced once the completed text is inserted).  This may be an AstNode or
   * a Token, or it may be null if the cursor is after all tokens in the file.
   * See field of the same name in [CompletionTarget].
   */
  final Object entity;

  _BestTypeVisitor(this.entity);

  DartType visitConstructorName(ConstructorName node) {
    if (node.period != null && node.name == entity) {
      TypeName typeName = node.type;
      if (typeName != null) {
        return typeName.type;
      }
    }
    return null;
  }

  DartType visitNode(AstNode node) {
    return null;
  }

  DartType visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier == entity) {
      SimpleIdentifier prefix = node.prefix;
      if (prefix != null) {
        return prefix.bestType;
      }
    }
    return null;
  }

  DartType visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName == entity) {
      Expression target = node.realTarget;
      if (target != null) {
        return target.bestType;
      }
    }
    return null;
  }
}
