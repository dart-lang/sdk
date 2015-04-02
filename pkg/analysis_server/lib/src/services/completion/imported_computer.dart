// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.toplevel;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_cache.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/optype.dart';
import 'package:analysis_server/src/services/completion/suggestion_builder.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A computer for calculating imported class and top level variable
 * `completion.getSuggestions` request results.
 */
class ImportedComputer extends DartCompletionComputer {
  bool shouldWaitForLowPrioritySuggestions;
  bool suggestionsComputed;
  _ImportedSuggestionBuilder builder;

  ImportedComputer({this.shouldWaitForLowPrioritySuggestions: false});

  @override
  bool computeFast(DartCompletionRequest request) {
    OpType optype = request.optype;
    if (optype.includeReturnValueSuggestions ||
        optype.includeTypeNameSuggestions ||
        optype.includeVoidReturnSuggestions ||
        optype.includeConstructorSuggestions) {
      builder = new _ImportedSuggestionBuilder(request, optype);
      builder.shouldWaitForLowPrioritySuggestions =
          shouldWaitForLowPrioritySuggestions;
      // If target is an argument in an argument list
      // then suggestions may need to be adjusted
      suggestionsComputed = builder.computeFast(request.target.containingNode);
      return suggestionsComputed && request.target.argIndex == null;
    }
    return true;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) async {
    if (builder != null) {
      if (!suggestionsComputed) {
        bool result = await builder.computeFull(request.target.containingNode);
        _updateSuggestions(request);
        return result;
      }
      _updateSuggestions(request);
      return true;
    }
    return false;
  }

  /**
   * If target is a function argument, suggest identifiers not invocations
   */
  void _updateSuggestions(DartCompletionRequest request) {
    if (request.target.isFunctionalArgument()) {
      request.convertInvocationsToIdentifiers();
    }
  }
}

/**
 * [_ImportedSuggestionBuilder] traverses the imports and builds suggestions
 * based upon imported elements.
 */
class _ImportedSuggestionBuilder extends ElementSuggestionBuilder
    implements SuggestionBuilder {
  bool shouldWaitForLowPrioritySuggestions;
  final DartCompletionRequest request;
  final OpType optype;
  DartCompletionCache cache;

  _ImportedSuggestionBuilder(this.request, this.optype) {
    cache = request.cache;
  }

  @override
  CompletionSuggestionKind get kind => CompletionSuggestionKind.INVOCATION;

  /**
   * If the needed information is cached, then add suggestions and return `true`
   * else return `false` indicating that additional work is necessary.
   */
  bool computeFast(AstNode node) {
    CompilationUnit unit = request.unit;
    if (cache.isImportInfoCached(unit)) {
      _addSuggestions(node);
      return true;
    }
    return false;
  }

  /**
   * Compute suggested based upon imported elements.
   */
  Future<bool> computeFull(AstNode node) {
    Future<bool> addSuggestions(_) {
      _addSuggestions(node);
      return new Future.value(true);
    }

    Future future = null;
    if (!cache.isImportInfoCached(request.unit)) {
      future = cache.computeImportInfo(request.unit, request.searchEngine,
          shouldWaitForLowPrioritySuggestions);
    }
    if (future != null) {
      return future.then(addSuggestions);
    }
    return addSuggestions(true);
  }

  /**
   * Add constructor and library prefix suggestions from the cache.
   * To reduce the number of suggestions sent to the client,
   * filter the suggestions based upon the first character typed.
   * If no characters are available to use for filtering,
   * then exclude all low priority suggestions.
   */
  void _addConstructorSuggestions() {
    String filterText = request.filterText;
    if (filterText.length > 1) {
      filterText = filterText.substring(0, 1);
    }
    DartCompletionCache cache = request.cache;
    _addFilteredSuggestions(filterText, cache.importedConstructorSuggestions);
    _addFilteredSuggestions(filterText, cache.libraryPrefixSuggestions);
  }

  /**
   * Add imported element suggestions.
   */
  void _addElementSuggestions(List<Element> elements,
      {int relevance: DART_RELEVANCE_DEFAULT}) {
    for (Element elem in elements) {
      if (elem is! ClassElement) {
        if (optype.includeOnlyTypeNameSuggestions) {
          return;
        }
        if (elem is ExecutableElement) {
          DartType returnType = elem.returnType;
          if (returnType != null && returnType.isVoid) {
            if (!optype.includeVoidReturnSuggestions) {
              return;
            }
          }
        }
      }
      addSuggestion(elem, relevance: relevance);
    }
    ;
  }

  /**
   * Add suggestions which start with the given text.
   */
  _addFilteredSuggestions(
      String filterText, List<CompletionSuggestion> unfiltered) {
    //TODO (danrubel) Revisit this filtering once paged API has been added
    unfiltered.forEach((CompletionSuggestion suggestion) {
      if (filterText.length > 0) {
        if (suggestion.completion.startsWith(filterText)) {
          request.addSuggestion(suggestion);
        }
      } else {
        if (suggestion.relevance != DART_RELEVANCE_LOW) {
          request.addSuggestion(suggestion);
        }
      }
    });
  }

  /**
   * Add suggestions for any inherited imported members.
   */
  void _addInheritedSuggestions(AstNode node) {
    var classDecl = node.getAncestor((p) => p is ClassDeclaration);
    if (classDecl is ClassDeclaration) {
      // Build a list of inherited types that are imported
      // and include any inherited imported members
      List<String> inheritedTypes = new List<String>();
      visitInheritedTypes(classDecl, (_) {
        // local declarations are handled by the local computer
      }, (String typeName) {
        inheritedTypes.add(typeName);
      });
      HashSet<String> visited = new HashSet<String>();
      while (inheritedTypes.length > 0) {
        String name = inheritedTypes.removeLast();
        ClassElement elem = cache.importedClassMap[name];
        if (visited.add(name) && elem != null) {
          _addElementSuggestions(elem.fields,
              relevance: DART_RELEVANCE_INHERITED_FIELD);
          _addElementSuggestions(elem.accessors,
              relevance: DART_RELEVANCE_INHERITED_ACCESSOR);
          _addElementSuggestions(elem.methods,
              relevance: DART_RELEVANCE_INHERITED_METHOD);
          elem.allSupertypes.forEach((InterfaceType type) {
            if (visited.add(type.name) && type.element != null) {
              _addElementSuggestions(type.element.fields,
                  relevance: DART_RELEVANCE_INHERITED_FIELD);
              _addElementSuggestions(type.element.accessors,
                  relevance: DART_RELEVANCE_INHERITED_ACCESSOR);
              _addElementSuggestions(type.element.methods,
                  relevance: DART_RELEVANCE_INHERITED_METHOD);
            }
          });
        }
      }
    }
  }

  /**
   * Add suggested based upon imported elements.
   */
  void _addSuggestions(AstNode node) {
    if (optype.includeConstructorSuggestions) {
      _addConstructorSuggestions();
    }
    if (optype.includeReturnValueSuggestions ||
        optype.includeTypeNameSuggestions ||
        optype.includeVoidReturnSuggestions) {
      _addInheritedSuggestions(node);
      _addTopLevelSuggestions();
    }
  }

  /**
   * Add top level suggestions from the cache.
   * To reduce the number of suggestions sent to the client,
   * filter the suggestions based upon the first character typed.
   * If no characters are available to use for filtering,
   * then exclude all low priority suggestions.
   */
  void _addTopLevelSuggestions() {
    String filterText = request.filterText;
    if (filterText.length > 1) {
      filterText = filterText.substring(0, 1);
    }
    DartCompletionCache cache = request.cache;
    if (optype.includeTypeNameSuggestions) {
      _addFilteredSuggestions(filterText, cache.importedTypeSuggestions);
      _addFilteredSuggestions(filterText, cache.libraryPrefixSuggestions);
    }
    if (optype.includeReturnValueSuggestions) {
      _addFilteredSuggestions(filterText, cache.otherImportedSuggestions);
    }
    if (optype.includeVoidReturnSuggestions) {
      _addFilteredSuggestions(filterText, cache.importedVoidReturnSuggestions);
    }
  }
}
