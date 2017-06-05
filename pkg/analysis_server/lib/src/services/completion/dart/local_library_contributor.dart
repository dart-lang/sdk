// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart'
    show createSuggestion, ElementSuggestionBuilder;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

/**
 * A visitor for building suggestions based upon the elements defined by
 * a source file contained in the same library but not the same as
 * the source in which the completions are being requested.
 */
class LibraryElementSuggestionBuilder extends GeneralizingElementVisitor
    with ElementSuggestionBuilder {
  final DartCompletionRequest request;
  final OpType optype;
  CompletionSuggestionKind kind;
  final String prefix;
  List<String> showNames;
  List<String> hiddenNames;

  LibraryElementSuggestionBuilder(this.request, this.optype, [this.prefix]) {
    this.kind = request.target.isFunctionalArgument()
        ? CompletionSuggestionKind.IDENTIFIER
        : optype.suggestKind;
  }

  @override
  LibraryElement get containingLibrary => request.libraryElement;

  @override
  void visitClassElement(ClassElement element) {
    if (optype.includeTypeNameSuggestions) {
      // if includeTypeNameSuggestions, then use the filter
      int relevance = optype.typeNameSuggestionsFilter(
          element.type, DART_RELEVANCE_DEFAULT);
      if (relevance != null) {
        addSuggestion(element, prefix: prefix, relevance: relevance);
      }
    }
    if (optype.includeConstructorSuggestions) {
      int relevance = optype.constructorSuggestionsFilter(
          element.type, DART_RELEVANCE_DEFAULT);
      if (relevance != null) {
        _addConstructorSuggestions(element, relevance);
      }
    }
  }

  @override
  void visitCompilationUnitElement(CompilationUnitElement element) {
    element.visitChildren(this);
  }

  @override
  void visitElement(Element element) {
    // ignored
  }

  @override
  void visitFunctionElement(FunctionElement element) {
    // Do not suggest operators or local functions
    if (element.isOperator) {
      return;
    }
    if (element.enclosingElement is! CompilationUnitElement) {
      return;
    }
    int relevance = element.library == containingLibrary
        ? DART_RELEVANCE_LOCAL_FUNCTION
        : DART_RELEVANCE_DEFAULT;
    DartType returnType = element.returnType;
    if (returnType != null && returnType.isVoid) {
      if (optype.includeVoidReturnSuggestions) {
        addSuggestion(element, prefix: prefix, relevance: relevance);
      }
    } else {
      if (optype.includeReturnValueSuggestions) {
        addSuggestion(element, prefix: prefix, relevance: relevance);
      }
    }
  }

  @override
  void visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    if (optype.includeTypeNameSuggestions) {
      int relevance = element.library == containingLibrary
          ? DART_RELEVANCE_LOCAL_FUNCTION
          : DART_RELEVANCE_DEFAULT;
      addSuggestion(element, prefix: prefix, relevance: relevance);
    }
  }

  @override
  void visitLibraryElement(LibraryElement element) {
    element.visitChildren(this);
  }

  @override
  void visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (optype.includeReturnValueSuggestions) {
      int relevance;
      if (element.library == containingLibrary) {
        if (element.enclosingElement is ClassElement) {
          relevance = DART_RELEVANCE_LOCAL_FIELD;
        } else {
          relevance = DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE;
        }
      } else {
        relevance = DART_RELEVANCE_DEFAULT;
      }
      addSuggestion(element, prefix: prefix, relevance: relevance);
    }
  }

  @override
  void visitTopLevelVariableElement(TopLevelVariableElement element) {
    if (optype.includeReturnValueSuggestions) {
      int relevance = element.library == containingLibrary
          ? DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE
          : DART_RELEVANCE_DEFAULT;
      addSuggestion(element, prefix: prefix, relevance: relevance);
    }
  }

  /**
   * Add constructor suggestions for the given class.
   */
  void _addConstructorSuggestions(ClassElement classElem, int relevance) {
    String className = classElem.name;
    for (ConstructorElement constructor in classElem.constructors) {
      if (!constructor.isPrivate) {
        CompletionSuggestion suggestion =
            createSuggestion(constructor, relevance: relevance);
        if (suggestion != null) {
          String name = suggestion.completion;
          name = name.length > 0 ? '$className.$name' : className;
          if (prefix != null && prefix.length > 0) {
            name = '$prefix.$name';
          }
          suggestion.completion = name;
          suggestion.selectionOffset = suggestion.completion.length;
          suggestions.add(suggestion);
        }
      }
    }
  }
}

/**
 * A contributor for calculating suggestions for top level members
 * in the library in which the completion is requested
 * but outside the file in which the completion is requested.
 */
class LocalLibraryContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    if (!request.includeIdentifiers) {
      return EMPTY_LIST;
    }

    List<CompilationUnitElement> libraryUnits =
        request.result.unit.element.library.units;
    if (libraryUnits == null) {
      return EMPTY_LIST;
    }

    OpType optype = (request as DartCompletionRequestImpl).opType;
    LibraryElementSuggestionBuilder visitor =
        new LibraryElementSuggestionBuilder(request, optype);
    for (CompilationUnitElement unit in libraryUnits) {
      if (unit != null && unit.source != request.source) {
        unit.accept(visitor);
      }
    }
    return visitor.suggestions;
  }
}
