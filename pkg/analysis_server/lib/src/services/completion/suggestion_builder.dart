// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.suggestion.builder;

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart' hide Element,
    ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * This class visits elements in a class and provides suggestions based upon
 * the visible members in that class. Clients should call
 * [ClassElementSuggestionBuilder.suggestionsFor].
 */
class ClassElementSuggestionBuilder extends _AbstractSuggestionBuilder {

  ClassElementSuggestionBuilder(DartCompletionRequest request) : super(request);

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
    _addElementSuggestion(
        element,
        CompletionSuggestionKind.GETTER,
        element.type,
        element.enclosingElement);
  }

  @override
  visitMethodElement(MethodElement element) {
    _addElementSuggestion(
        element,
        CompletionSuggestionKind.METHOD,
        element.returnType,
        element.enclosingElement);
  }

  @override
  visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (element.isGetter) {
      _addElementSuggestion(
          element,
          CompletionSuggestionKind.GETTER,
          element.returnType,
          element.enclosingElement);
    } else if (element.isSetter) {
      _addElementSuggestion(
          element,
          CompletionSuggestionKind.SETTER,
          element.returnType,
          element.enclosingElement);
    }
  }

  /**
   * Add suggestions for the visible members in the given class
   */
  static void suggestionsFor(DartCompletionRequest request, Element element) {
    if (element is ClassElement) {
      return element.accept(new ClassElementSuggestionBuilder(request));
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
        CompletionSuggestion suggestion = new CompletionSuggestion(
            protocol.newCompletionSuggestionKind_fromElementKind(element.kind),
            CompletionRelevance.DEFAULT,
            completion,
            completion.length,
            0,
            element.isDeprecated,
            false);

        suggestion.element = newElement_fromEngine(element);

        request.suggestions.add(suggestion);
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

/**
 * This class visits elements in a class and provides suggestions based upon
 * the visible named constructors in that class. Clients should call
 * [NamedConstructorSuggestionBuilder.suggestionsFor].
 */
class NamedConstructorSuggestionBuilder extends _AbstractSuggestionBuilder {

  NamedConstructorSuggestionBuilder(DartCompletionRequest request)
      : super(request);

  @override
  visitClassElement(ClassElement element) {
    element.visitChildren(this);
  }

  @override
  visitConstructorElement(ConstructorElement element) {
    _addElementSuggestion(
        element,
        CompletionSuggestionKind.CONSTRUCTOR,
        element.returnType,
        element.enclosingElement);
  }

  @override
  visitElement(Element element) {
    // ignored
  }

  /**
   * Add suggestions for the visible members in the given class
   */
  static void suggestionsFor(DartCompletionRequest request, Element element) {
    if (element is ClassElement) {
      element.accept(new NamedConstructorSuggestionBuilder(request));
    }
  }
}

/**
 * Common superclass for sharing behavior
 */
class _AbstractSuggestionBuilder extends GeneralizingElementVisitor {
  final DartCompletionRequest request;
  final Set<String> _completions = new Set<String>();

  _AbstractSuggestionBuilder(this.request);

  void _addElementSuggestion(Element element, CompletionSuggestionKind kind,
      DartType type, ClassElement enclosingElement) {
    if (element.isSynthetic) {
      return;
    }
    if (element.isPrivate) {
      LibraryElement elementLibrary = element.library;
      LibraryElement unitLibrary = request.unit.element.library;
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
    CompletionSuggestion suggestion = new CompletionSuggestion(
        kind,
        CompletionRelevance.DEFAULT,
        completion,
        completion.length,
        0,
        element.isDeprecated,
        false);
    suggestion.element = protocol.newElement_fromEngine(element);
    if (suggestion.element != null) {
      if (element is FieldElement) {
        suggestion.element.kind = protocol.ElementKind.GETTER;
        suggestion.element.returnType =
            element.type != null ? element.type.displayName : 'dynamic';
      }
    }
    if (enclosingElement != null) {
      suggestion.declaringType = enclosingElement.displayName;
    }
    if (type != null) {
      String typeName = type.displayName;
      if (typeName != null && typeName.length > 0 && typeName != 'dynamic') {
        suggestion.returnType = typeName;
      }
    }
    request.suggestions.add(suggestion);
  }
}
