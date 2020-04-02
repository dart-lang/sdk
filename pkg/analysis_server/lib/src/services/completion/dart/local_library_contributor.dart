// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart'
    show createSuggestion, ElementSuggestionBuilder;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

/// A visitor for building suggestions based upon the elements defined by
/// a source file contained in the same library but not the same as
/// the source in which the completions are being requested.
class LibraryElementSuggestionBuilder extends GeneralizingElementVisitor
    with ElementSuggestionBuilder {
  final DartCompletionRequest request;

  final OpType optype;

  DartType contextType;

  @override
  CompletionSuggestionKind kind;

  final String prefix;

  /// The set of libraries that have been, or are currently being, visited.
  final Set<LibraryElement> visitedLibraries = <LibraryElement>{};

  LibraryElementSuggestionBuilder(this.request, [this.prefix])
      : optype = request.opType {
    contextType = request.featureComputer
        .computeContextType(request.target.containingNode);
    kind = request.target.isFunctionalArgument()
        ? CompletionSuggestionKind.IDENTIFIER
        : optype.suggestKind;
  }

  @override
  LibraryElement get containingLibrary => request.libraryElement;

  @override
  void visitClassElement(ClassElement element) {
    if (optype.includeTypeNameSuggestions) {
      // if includeTypeNameSuggestions, then use the filter
      var useNewRelevance = request.useNewRelevance;
      int relevance;
      if (useNewRelevance) {
        relevance = _relevanceForType(element.thisType);
      } else {
        relevance = optype.typeNameSuggestionsFilter(
            _instantiateClassElement(element), DART_RELEVANCE_DEFAULT);
      }
      if (relevance != null) {
        addSuggestion(element,
            prefix: prefix,
            relevance: relevance,
            useNewRelevance: useNewRelevance);
      }
    }
    if (optype.includeConstructorSuggestions) {
      var useNewRelevance = request.useNewRelevance;
      int relevance;
      if (useNewRelevance) {
        relevance = _relevanceForType(element.thisType);
      } else {
        relevance = optype.returnValueSuggestionsFilter(
            _instantiateClassElement(element), DART_RELEVANCE_DEFAULT);
      }
      _addConstructorSuggestions(element, relevance, useNewRelevance);
    }
    if (optype.includeReturnValueSuggestions) {
      if (element.isEnum) {
        var enumName = element.displayName;
        var useNewRelevance = request.useNewRelevance;
        int relevance;
        if (useNewRelevance) {
          relevance = _relevanceForType(element.thisType);
        } else {
          relevance = optype.returnValueSuggestionsFilter(
              _instantiateClassElement(element), DART_RELEVANCE_DEFAULT);
        }
        for (var field in element.fields) {
          if (field.isEnumConstant) {
            addSuggestion(field,
                prefix: prefix,
                relevance: relevance,
                elementCompletion: '$enumName.${field.name}',
                useNewRelevance: useNewRelevance);
          }
        }
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
  void visitExtensionElement(ExtensionElement element) {
    if (optype.includeReturnValueSuggestions) {
      var useNewRelevance = request.useNewRelevance;
      int relevance;
      if (useNewRelevance) {
        relevance = _relevanceForType(element.extendedType);
      } else {
        relevance = DART_RELEVANCE_DEFAULT;
      }
      addSuggestion(element,
          prefix: prefix,
          relevance: relevance,
          useNewRelevance: useNewRelevance);
    }
    element.visitChildren(this);
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
    var returnType = element.returnType;
    var useNewRelevance = request.useNewRelevance;
    int relevance;
    if (useNewRelevance) {
      relevance = _relevanceForType(returnType);
    } else {
      relevance = element.library == containingLibrary
          ? DART_RELEVANCE_LOCAL_FUNCTION
          : DART_RELEVANCE_DEFAULT;
    }
    if (returnType != null && returnType.isVoid) {
      if (optype.includeVoidReturnSuggestions) {
        addSuggestion(element,
            prefix: prefix,
            relevance: relevance,
            useNewRelevance: useNewRelevance);
      }
    } else {
      if (optype.includeReturnValueSuggestions) {
        addSuggestion(element,
            prefix: prefix,
            relevance: relevance,
            useNewRelevance: useNewRelevance);
      }
    }
  }

  @override
  void visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    if (optype.includeTypeNameSuggestions) {
      var useNewRelevance = request.useNewRelevance;
      int relevance;
      if (useNewRelevance) {
        // TODO(brianwilkerson) Figure out whether there are any features that
        //  ought to be used here and what the right default value is.
        relevance = 400;
      } else {
        relevance = element.library == containingLibrary
            ? DART_RELEVANCE_LOCAL_FUNCTION
            : DART_RELEVANCE_DEFAULT;
      }
      addSuggestion(element,
          prefix: prefix,
          relevance: relevance,
          useNewRelevance: useNewRelevance);
    }
  }

  @override
  void visitLibraryElement(LibraryElement element) {
    if (visitedLibraries.add(element)) {
      element.visitChildren(this);
    }
  }

  @override
  void visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (optype.includeReturnValueSuggestions) {
      var useNewRelevance = request.useNewRelevance;
      int relevance;
      if (useNewRelevance) {
        relevance = _relevanceForType(element.returnType);
      } else {
        if (element.library == containingLibrary) {
          if (element.enclosingElement is ClassElement) {
            relevance = DART_RELEVANCE_LOCAL_FIELD;
          } else {
            relevance = DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE;
          }
        } else {
          relevance = DART_RELEVANCE_DEFAULT;
        }
      }
      addSuggestion(element,
          prefix: prefix,
          relevance: relevance,
          useNewRelevance: useNewRelevance);
    }
  }

  @override
  void visitTopLevelVariableElement(TopLevelVariableElement element) {
    if (optype.includeReturnValueSuggestions) {
      var useNewRelevance = request.useNewRelevance;
      int relevance;
      if (useNewRelevance) {
        relevance = _relevanceForType(element.type);
      } else {
        relevance = element.library == containingLibrary
            ? DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE
            : DART_RELEVANCE_DEFAULT;
      }
      addSuggestion(element,
          prefix: prefix,
          relevance: relevance,
          useNewRelevance: useNewRelevance);
    }
  }

  /// Add constructor suggestions for the given class.
  void _addConstructorSuggestions(
      ClassElement classElem, int relevance, bool useNewRelevance) {
    var className = classElem.name;
    for (var constructor in classElem.constructors) {
      if (constructor.isPrivate) {
        continue;
      }
      if (classElem.isAbstract && !constructor.isFactory) {
        continue;
      }

      var suggestion = createSuggestion(constructor,
          relevance: relevance, useNewRelevance: useNewRelevance);
      if (suggestion != null) {
        var name = suggestion.completion;
        name = name.isNotEmpty ? '$className.$name' : className;
        if (prefix != null && prefix.isNotEmpty) {
          name = '$prefix.$name';
        }
        suggestion.completion = name;
        suggestion.selectionOffset = suggestion.completion.length;
        suggestions.add(suggestion);
      }
    }
  }

  InterfaceType _instantiateClassElement(ClassElement element) {
    var typeParameters = element.typeParameters;
    var typeArguments = const <DartType>[];
    if (typeParameters.isNotEmpty) {
      var typeProvider = request.libraryElement.typeProvider;
      typeArguments = typeParameters.map((t) {
        return typeProvider.dynamicType;
      }).toList();
    }

    var nullabilitySuffix = request.featureSet.isEnabled(Feature.non_nullable)
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;

    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  int _relevanceForType(DartType elementType) {
    var contextTypeFeature =
        request.featureComputer.contextTypeFeature(contextType, elementType);
    // TODO(brianwilkerson) Figure out whether there are other features that
    //  ought to be used here and what the right default value is.
    return toRelevance(contextTypeFeature, 800);
  }
}

/// A contributor that produces suggestions based on the top level members in
/// the library in which the completion is requested but outside the file in
/// which the completion is requested.
class LocalLibraryContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    if (!request.includeIdentifiers) {
      return const <CompletionSuggestion>[];
    }

    var libraryUnits = request.result.unit.declaredElement.library.units;
    if (libraryUnits == null) {
      return const <CompletionSuggestion>[];
    }

    var visitor = LibraryElementSuggestionBuilder(request);
    for (var unit in libraryUnits) {
      if (unit != null && unit.source != request.source) {
        unit.accept(visitor);
      }
    }
    return visitor.suggestions;
  }
}
