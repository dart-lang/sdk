// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.local_lib;

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/optype.dart';
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

    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    OpType optype = (request as DartCompletionRequestImpl).opType;
    _Visitor visitor = new _Visitor(request, optype, suggestions);
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
    return suggestions;
  }
}

/**
 * A visitor for building suggestions based upon the elements defined by
 * a source file contained in the same library but not the same as
 * the source in which the completions are being requested.
 */
class _Visitor extends GeneralizingElementVisitor {
  final DartCompletionRequest request;
  final OpType optype;
  final List<CompletionSuggestion> suggestions;

  _Visitor(this.request, this.optype, this.suggestions);

  @override
  void visitClassElement(ClassElement element) {
    _addSuggestion(element, DART_RELEVANCE_DEFAULT);
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
    _addSuggestion(element, DART_RELEVANCE_LOCAL_FUNCTION);
  }

  @override
  void visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    _addSuggestion(element, DART_RELEVANCE_LOCAL_FUNCTION);
  }

  @override
  void visitTopLevelVariableElement(TopLevelVariableElement element) {
    _addSuggestion(element, DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE);
  }

  /**
   * Add a suggestion for the given element.
   */
  void _addSuggestion(Element element, int relevance) {
    if (element is ExecutableElement) {
      // Do not suggest operators or local functions
      if (element.isOperator) {
        return;
      }
      if (element is FunctionElement) {
        if (element.enclosingElement is! CompilationUnitElement) {
          return;
        }
      }
    }

    CompletionSuggestion suggestion =
        createSuggestion(element, relevance: relevance);

    if (suggestion != null) {
      if (element is ExecutableElement) {
        DartType returnType = element.returnType;
        if (returnType != null && returnType.isVoid) {
          if (optype.includeVoidReturnSuggestions) {
            suggestions.add(suggestion);
          }
        } else {
          if (optype.includeReturnValueSuggestions) {
            suggestions.add(suggestion);
          }
        }
      } else if (element is FunctionTypeAliasElement) {
        if (optype.includeTypeNameSuggestions) {
          suggestions.add(suggestion);
        }
      } else if (element is ClassElement) {
        if (optype.includeTypeNameSuggestions) {
          suggestions.add(suggestion);
        }
        if (optype.includeConstructorSuggestions) {
          _addConstructorSuggestions(element, relevance);
        }
      } else {
        if (optype.includeReturnValueSuggestions) {
          suggestions.add(suggestion);
        }
      }
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
          suggestion.completion = name;
          suggestion.selectionOffset = suggestion.completion.length;
          suggestions.add(suggestion);
        }
      }
    }
  }
}
