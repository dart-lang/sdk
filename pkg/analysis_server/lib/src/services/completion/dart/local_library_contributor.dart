// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.local_lib;

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart'
    show createSuggestion, ElementSuggestionBuilder;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

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

    List<Directive> directives = await request.resolveDirectives();
    if (directives == null) {
      return EMPTY_LIST;
    }

    OpType optype = (request as DartCompletionRequestImpl).opType;
    LibraryElementSuggestionBuilder visitor =
        new LibraryElementSuggestionBuilder(request, optype);
    if (request.librarySource != request.source) {
      request.libraryElement.definingCompilationUnit.accept(visitor);
    }
    for (Directive directive in directives) {
      if (directive is PartDirective) {
        CompilationUnitElement partElem = directive.element;
        if (partElem != null && partElem.source != request.source) {
          partElem.accept(visitor);
        }
      }
    }
    return visitor.suggestions;
  }
}

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
      addSuggestion(element, prefix: prefix, relevance: DART_RELEVANCE_DEFAULT);
    }
    if (optype.includeConstructorSuggestions) {
      _addConstructorSuggestions(element, DART_RELEVANCE_DEFAULT);
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
