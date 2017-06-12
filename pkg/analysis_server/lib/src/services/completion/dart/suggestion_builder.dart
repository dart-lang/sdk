// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/ide_options.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/utilities/documentation.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:path/path.dart' as path;

const String DYNAMIC = 'dynamic';

/**
 * Return a suggestion based upon the given element
 * or `null` if a suggestion is not appropriate for the given element.
 * If the suggestion is not currently in scope, then specify
 * importForSource as the source to which an import should be added.
 */
CompletionSuggestion createSuggestion(Element element, IdeOptions options,
    {String completion,
    CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
    int relevance: DART_RELEVANCE_DEFAULT,
    Source importForSource}) {
  if (element == null) {
    return null;
  }
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

  // Attach docs.
  String doc = removeDartDocDelimiters(element.documentationComment);
  suggestion.docComplete = doc;
  suggestion.docSummary = getDartDocSummary(doc);

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

    Iterable<ParameterElement> requiredParameters = element.parameters.where(
        (ParameterElement param) =>
            param.parameterKind == ParameterKind.REQUIRED);
    suggestion.requiredParameterCount = requiredParameters.length;

    Iterable<ParameterElement> namedParameters = element.parameters.where(
        (ParameterElement param) => param.parameterKind == ParameterKind.NAMED);
    suggestion.hasNamedParameters = namedParameters.isNotEmpty;

    addDefaultArgDetails(
        suggestion, element, requiredParameters, namedParameters, options);
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
   * A set of existing completions used to prevent duplicate suggestions.
   */
  final Set<String> _completions = new Set<String>();

  /**
   * A map of element names to suggestions for synthetic getters and setters.
   */
  final Map<String, CompletionSuggestion> _syntheticMap =
      <String, CompletionSuggestion>{};

  /**
   * Return the library in which the completion is requested.
   */
  LibraryElement get containingLibrary;

  /**
   * Return the kind of suggestions that should be built.
   */
  CompletionSuggestionKind get kind;

  /**
   * Add a suggestion based upon the given element.
   */
  void addSuggestion(Element element, IdeOptions ideOptions,
      {String prefix, int relevance: DART_RELEVANCE_DEFAULT}) {
    if (element.isPrivate) {
      if (element.library != containingLibrary) {
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
    CompletionSuggestion suggestion = createSuggestion(element, ideOptions,
        completion: completion, kind: kind, relevance: relevance);
    if (suggestion != null) {
      if (element.isSynthetic && element is PropertyAccessorElement) {
        String cacheKey;
        if (element.isGetter) {
          cacheKey = element.name;
        }
        if (element.isSetter) {
          cacheKey = element.name;
          cacheKey = cacheKey.substring(0, cacheKey.length - 1);
        }
        if (cacheKey != null) {
          CompletionSuggestion existingSuggestion = _syntheticMap[cacheKey];

          // Pair getter/setter by updating the existing suggestion
          if (existingSuggestion != null) {
            CompletionSuggestion getter =
                element.isGetter ? suggestion : existingSuggestion;
            protocol.ElementKind elemKind =
                element.enclosingElement is ClassElement
                    ? protocol.ElementKind.FIELD
                    : protocol.ElementKind.TOP_LEVEL_VARIABLE;
            existingSuggestion.element = new protocol.Element(
                elemKind,
                existingSuggestion.element.name,
                existingSuggestion.element.flags,
                location: getter.element.location,
                typeParameters: getter.element.typeParameters,
                parameters: null,
                returnType: getter.returnType);
            return;
          }

          // Cache lone getter/setter so that it can be paired
          _syntheticMap[cacheKey] = suggestion;
        }
      }
      if (_completions.add(suggestion.completion)) {
        suggestions.add(suggestion);
      }
    }
  }
}

/**
 * This class visits elements in a library and provides suggestions based upon
 * the visible members in that library.
 */
class LibraryElementSuggestionBuilder extends GeneralizingElementVisitor
    with ElementSuggestionBuilder {
  final LibraryElement containingLibrary;
  final CompletionSuggestionKind kind;
  final bool typesOnly;
  final bool instCreation;
  final IdeOptions options;

  LibraryElementSuggestionBuilder(this.containingLibrary, this.kind,
      this.typesOnly, this.instCreation, this.options);

  @override
  visitClassElement(ClassElement element) {
    if (instCreation) {
      element.visitChildren(this);
    } else {
      addSuggestion(element, options);
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
          addSuggestion(element, options, prefix: prefix);
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
      int relevance = element.library == containingLibrary
          ? DART_RELEVANCE_LOCAL_FUNCTION
          : DART_RELEVANCE_DEFAULT;
      addSuggestion(element, options, relevance: relevance);
    }
  }

  @override
  visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    if (!instCreation) {
      addSuggestion(element, options);
    }
  }

  @override
  visitTopLevelVariableElement(TopLevelVariableElement element) {
    if (!typesOnly) {
      int relevance = element.library == containingLibrary
          ? DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE
          : DART_RELEVANCE_DEFAULT;
      addSuggestion(element, options, relevance: relevance);
    }
  }
}
