// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.dart.suggestion.builder;

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:path/path.dart' as path;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';

const String DYNAMIC = 'dynamic';

/**
 * Return a suggestion based upon the given element
 * or `null` if a suggestion is not appropriate for the given element.
 * If the suggestion is not currently in scope, then specify
 * importForSource as the source to which an import should be added.
 */
CompletionSuggestion createSuggestion(Element element,
    {String completion,
    CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
    int relevance: DART_RELEVANCE_DEFAULT,
    Source importForSource}) {
  if (element is ExecutableElement && element.isOperator) {
    // Do not include operators in suggestions
    return null;
  }
  if (completion == null) {
    completion = element.displayName;
  }
  bool isDeprecated = element.isDeprecated;
  CompletionSuggestion suggestion = new CompletionSuggestion(
      kind,
      isDeprecated ? DART_RELEVANCE_LOW : relevance,
      completion,
      completion.length,
      0,
      isDeprecated,
      false);
  suggestion.element = protocol.convertElement(element);
  Element enclosingElement = element.enclosingElement;
  if (enclosingElement is ClassElement) {
    suggestion.declaringType = enclosingElement.displayName;
  }
  suggestion.returnType = getReturnTypeString(element);
  if (element is ExecutableElement && element is! PropertyAccessorElement) {
    suggestion.parameterNames = element.parameters
        .map((ParameterElement parameter) => parameter.name)
        .toList();
    suggestion.parameterTypes =
        element.parameters.map((ParameterElement parameter) {
      DartType paramType = parameter.type;
      // Gracefully degrade if type not resolved yet
      return paramType != null ? paramType.displayName : 'var';
    }).toList();
    suggestion.requiredParameterCount = element.parameters
        .where((ParameterElement parameter) =>
            parameter.parameterKind == ParameterKind.REQUIRED)
        .length;
    suggestion.hasNamedParameters = element.parameters.any(
        (ParameterElement parameter) =>
            parameter.parameterKind == ParameterKind.NAMED);
  }
  if (importForSource != null) {
    String srcPath = path.dirname(importForSource.fullName);
    LibraryElement libElem = element.library;
    if (libElem != null) {
      Source libSource = libElem.source;
      if (libSource != null) {
        UriKind uriKind = libSource.uriKind;
        if (uriKind == UriKind.DART_URI) {
          suggestion.importUri = libSource.uri.toString();
        } else if (uriKind == UriKind.PACKAGE_URI) {
          suggestion.importUri = libSource.uri.toString();
        } else if (uriKind == UriKind.FILE_URI &&
            element.source.uriKind == UriKind.FILE_URI) {
          try {
            suggestion.importUri =
                path.relative(libSource.fullName, from: srcPath);
          } catch (_) {
            // ignored
          }
        }
      }
    }
    if (suggestion.importUri == null) {
      // Do not include out of scope suggestions
      // for which we cannot determine an import
      return null;
    }
  }
  return suggestion;
}

/**
 * Common mixin for sharing behavior
 */
abstract class ElementSuggestionBuilder {
  /**
   * A collection of completion suggestions.
   */
  final List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];

  /**
   * Return the kind of suggestions that should be built.
   */
  CompletionSuggestionKind get kind;

  /**
   * Return the request on which the builder is operating.
   */
  DartCompletionRequest get request;

  /**
   * Add a suggestion based upon the given element.
   */
  void addSuggestion(Element element,
      {String prefix, int relevance: DART_RELEVANCE_DEFAULT}) {
    if (element.isPrivate) {
      LibraryElement elementLibrary = element.library;
      CompilationUnitElement unitElem = request.target.unit.element;
      if (unitElem == null) {
        return;
      }
      LibraryElement unitLibrary = unitElem.library;
      if (elementLibrary != unitLibrary) {
        return;
      }
    }
    if (prefix == null && element.isSynthetic) {
      if ((element is PropertyAccessorElement) ||
          element is FieldElement && !_isSpecialEnumField(element)) {
        return;
      }
    }
    String completion = element.displayName;
    if (prefix != null && prefix.length > 0) {
      if (completion == null || completion.length <= 0) {
        completion = prefix;
      } else {
        completion = '$prefix.$completion';
      }
    }
    if (completion == null || completion.length <= 0) {
      return;
    }
    CompletionSuggestion suggestion = createSuggestion(element,
        completion: completion, kind: kind, relevance: relevance);
    if (suggestion != null) {
      suggestions.add(suggestion);
    }
  }

  /**
   * Determine if the given element is one of the synthetic enum accessors
   * for which we should generate a suggestion.
   */
  bool _isSpecialEnumField(FieldElement element) {
    Element parent = element.enclosingElement;
    if (parent is ClassElement && parent.isEnum) {
      if (element.name == 'values') {
        return true;
      }
    }
    return false;
  }
}

/**
 * This class visits elements in a library and provides suggestions based upon
 * the visible members in that library. Clients should call
 * [LibraryElementSuggestionBuilder.suggestionsFor].
 */
class LibraryElementSuggestionBuilder extends GeneralizingElementVisitor
    with ElementSuggestionBuilder {
  final DartCompletionRequest request;
  final CompletionSuggestionKind kind;
  final bool typesOnly;
  final bool instCreation;

  LibraryElementSuggestionBuilder(
      this.request, this.kind, this.typesOnly, this.instCreation);

  @override
  visitClassElement(ClassElement element) {
    if (instCreation) {
      element.visitChildren(this);
    } else {
      addSuggestion(element);
    }
  }

  @override
  visitCompilationUnitElement(CompilationUnitElement element) {
    element.visitChildren(this);
    LibraryElement containingLibrary = element.library;
    if (containingLibrary != null) {
      for (var lib in containingLibrary.exportedLibraries) {
        lib.visitChildren(this);
      }
    }
  }

  @override
  visitConstructorElement(ConstructorElement element) {
    if (instCreation) {
      ClassElement classElem = element.enclosingElement;
      if (classElem != null) {
        String prefix = classElem.name;
        if (prefix != null && prefix.length > 0) {
          addSuggestion(element, prefix: prefix);
        }
      }
    }
  }

  @override
  visitElement(Element element) {
    // ignored
  }

  @override
  visitFunctionElement(FunctionElement element) {
    if (!typesOnly) {
      addSuggestion(element);
    }
  }

  @override
  visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    if (!instCreation) {
      addSuggestion(element);
    }
  }

  @override
  visitTopLevelVariableElement(TopLevelVariableElement element) {
    if (!typesOnly) {
      addSuggestion(element);
    }
  }

  /**
   * Add suggestions for the visible members in the given library
   */
  static void suggestionsFor(
      DartCompletionRequest request,
      CompletionSuggestionKind kind,
      LibraryElement library,
      bool typesOnly,
      bool instCreation) {
    if (library != null) {
      library.visitChildren(new LibraryElementSuggestionBuilder(
          request, kind, typesOnly, instCreation));
    }
  }
}
