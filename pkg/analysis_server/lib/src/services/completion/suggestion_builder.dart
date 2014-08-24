// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.suggestion.builder;

import 'package:analysis_server/src/protocol2.dart' show
    CompletionRelevance, CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * This class visits elements in a class and provides suggestions based upon
 * the visible members in that class. Clients should call
 * [ClassElementSuggestionBuilder.suggestionsFor].
 */
class ClassElementSuggestionBuilder extends GeneralizingElementVisitor {
  final DartCompletionRequest request;
  final Set<String> _completions = new Set<String>();

  ClassElementSuggestionBuilder(this.request);

  @override
  visitClassElement(ClassElement element) {
    element.visitChildren(this);
    element.allSupertypes.forEach((InterfaceType type) {
      type.element.visitChildren(this);
    });
  }

  @override
  visitElement(Element element) {
    // ignored
  }

  @override
  visitFieldElement(FieldElement element) {
    _addSuggestion(element, CompletionSuggestionKind.FIELD);
  }

  @override
  visitMethodElement(MethodElement element) {
    _addSuggestion(element, CompletionSuggestionKind.METHOD);
  }

  @override
  visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (element.isGetter) {
      _addSuggestion(element, CompletionSuggestionKind.GETTER);
    } else if (element.isSetter) {
      _addSuggestion(element, CompletionSuggestionKind.SETTER);
    }
  }

  void _addSuggestion(Element element, CompletionSuggestionKind kind) {
    if (element.isSynthetic) {
      return;
    }
    if (element.isPrivate) {
      LibraryElement elementLibrary =
          element.getAncestor((parent) => parent is LibraryElement);
      LibraryElement unitLibrary =
          request.unit.element.getAncestor((parent) => parent is LibraryElement);
      if (elementLibrary != unitLibrary) {
        return;
      }
    }
    String completion = element.displayName;
    if (completion == null ||
        completion.length <= 0 ||
        !_completions.add(completion)) {
      return;
    }
    request.suggestions.add(
        new CompletionSuggestion(
            kind,
            CompletionRelevance.DEFAULT,
            completion,
            completion.length,
            0,
            element.isDeprecated,
            false));
  }

  /**
   * Add suggestions for the visible members in the given class
   */
  static void suggestionsFor(DartCompletionRequest request, Element element) {
    if (element is ClassElement) {
      element.accept(new ClassElementSuggestionBuilder(request));
    }
  }
}

/**
 * This class visits elements in a library and provides suggestions based upon
 * the visible members in that library. Clients should call
 * [LibraryElementSuggestionBuilder.suggestionsFor].
 */
class LibraryElementSuggestionBuilder extends GeneralizingElementVisitor {

  final DartCompletionRequest request;

  LibraryElementSuggestionBuilder(this.request);

  @override
  visitClassElement(ClassElement element) {
    _addSuggestion(element);
  }

  @override
  visitCompilationUnitElement(CompilationUnitElement element) {
    element.visitChildren(this);
  }

  @override
  visitElement(Element element) {
    // ignored
  }

  @override
  visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    _addSuggestion(element);
  }

  @override
  visitTopLevelVariableElement(TopLevelVariableElement element) {
    _addSuggestion(element);
  }

  void _addSuggestion(Element element) {
    if (element != null) {
      String completion = element.name;
      if (completion != null && completion.length > 0) {
        request.suggestions.add(
            new CompletionSuggestion(
                new CompletionSuggestionKind.fromElementKind(element.kind),
                CompletionRelevance.DEFAULT,
                completion,
                completion.length,
                0,
                element.isDeprecated,
                false));
      }
    }
  }

  /**
   * Add suggestions for the visible members in the given library
   */
  static void suggestionsFor(DartCompletionRequest request,
      LibraryElement library) {
    if (library != null) {
      library.visitChildren(new LibraryElementSuggestionBuilder(request));
    }
  }
}
