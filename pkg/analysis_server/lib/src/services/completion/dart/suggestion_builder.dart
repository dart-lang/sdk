// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:meta/meta.dart';

/// Return a suggestion based upon the given element or `null` if a suggestion
/// is not appropriate for the given element.
CompletionSuggestion createSuggestion(Element element,
    {String completion,
    CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
    int relevance = DART_RELEVANCE_DEFAULT,
    bool useNewRelevance = false}) {
  if (element == null) {
    return null;
  }
  if (element is ExecutableElement && element.isOperator) {
    // Do not include operators in suggestions
    return null;
  }
  completion ??= element.displayName;
  bool isDeprecated = element.hasDeprecated;
  if (!useNewRelevance && isDeprecated) {
    relevance = DART_RELEVANCE_LOW;
  }
  CompletionSuggestion suggestion = CompletionSuggestion(
      kind, relevance, completion, completion.length, 0, isDeprecated, false);

  // Attach docs.
  String doc = getDartDocPlainText(element.documentationComment);
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
      return paramType != null
          ? paramType.getDisplayString(withNullability: false)
          : 'var';
    }).toList();

    Iterable<ParameterElement> requiredParameters = element.parameters
        .where((ParameterElement param) => param.isRequiredPositional);
    suggestion.requiredParameterCount = requiredParameters.length;

    Iterable<ParameterElement> namedParameters =
        element.parameters.where((ParameterElement param) => param.isNamed);
    suggestion.hasNamedParameters = namedParameters.isNotEmpty;

    addDefaultArgDetails(
        suggestion, element, requiredParameters, namedParameters);
  }
  return suggestion;
}

/// Common mixin for sharing behavior.
mixin ElementSuggestionBuilder {
  /// A collection of completion suggestions.
  final List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];

  /// A set of existing completions used to prevent duplicate suggestions.
  final Set<String> _completions = <String>{};

  /// A map of element names to suggestions for synthetic getters and setters.
  final Map<String, CompletionSuggestion> _syntheticMap =
      <String, CompletionSuggestion>{};

  /// Return the library in which the completion is requested.
  LibraryElement get containingLibrary;

  /// Return the kind of suggestions that should be built.
  CompletionSuggestionKind get kind;

  /// Add a suggestion based upon the given element.
  CompletionSuggestion addSuggestion(Element element,
      {String prefix,
      int relevance = DART_RELEVANCE_DEFAULT,
      bool useNewRelevance = false,
      String elementCompletion}) {
    if (element.isPrivate) {
      if (element.library != containingLibrary) {
        return null;
      }
    }
    String completion = elementCompletion ?? element.displayName;
    if (prefix != null && prefix.isNotEmpty) {
      if (completion == null || completion.isEmpty) {
        completion = prefix;
      } else {
        completion = '$prefix.$completion';
      }
    }
    if (completion == null || completion.isEmpty) {
      return null;
    }
    CompletionSuggestion suggestion = createSuggestion(element,
        completion: completion,
        kind: kind,
        relevance: relevance,
        useNewRelevance: useNewRelevance);
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
            existingSuggestion.element = protocol.Element(
                elemKind,
                existingSuggestion.element.name,
                existingSuggestion.element.flags,
                location: getter.element.location,
                typeParameters: getter.element.typeParameters,
                parameters: null,
                returnType: getter.returnType);
            return existingSuggestion;
          }

          // Cache lone getter/setter so that it can be paired
          _syntheticMap[cacheKey] = suggestion;
        }
      }
      if (_completions.add(suggestion.completion)) {
        suggestions.add(suggestion);
      }
    }
    return suggestion;
  }
}

/// This class creates suggestions based upon top-level elements.
class LibraryElementSuggestionBuilder extends SimpleElementVisitor<void>
    with ElementSuggestionBuilder {
  @override
  final LibraryElement containingLibrary;
  @override
  final CompletionSuggestionKind kind;
  final bool typesOnly;
  final bool instCreation;

  LibraryElementSuggestionBuilder(
      this.containingLibrary, this.kind, this.typesOnly, this.instCreation);

  @override
  void visitClassElement(ClassElement element) {
    if (instCreation) {
      element.visitChildren(this);
    } else {
      addSuggestion(element);
    }
  }

  @override
  void visitConstructorElement(ConstructorElement element) {
    if (instCreation) {
      ClassElement classElem = element.enclosingElement;
      if (classElem != null) {
        String prefix = classElem.name;
        if (prefix != null && prefix.isNotEmpty) {
          addSuggestion(element, prefix: prefix);
        }
      }
    }
  }

  @override
  void visitExtensionElement(ExtensionElement element) {
    if (!instCreation) {
      addSuggestion(element);
    }
  }

  @override
  void visitFunctionElement(FunctionElement element) {
    if (!typesOnly) {
      int relevance = element.library == containingLibrary
          ? DART_RELEVANCE_LOCAL_FUNCTION
          : DART_RELEVANCE_DEFAULT;
      addSuggestion(element, relevance: relevance);
    }
  }

  @override
  void visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    if (!instCreation) {
      addSuggestion(element);
    }
  }

  @override
  void visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (!typesOnly) {
      PropertyInducingElement variable = element.variable;
      int relevance = variable.library == containingLibrary
          ? DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE
          : DART_RELEVANCE_DEFAULT;
      addSuggestion(variable, relevance: relevance);
    }
  }
}

/// This class provides suggestions based upon the visible instance members in
/// an interface type.
class MemberSuggestionBuilder {
  /// Enumerated value indicating that we have not generated any completions for
  /// a given identifier yet.
  static const int _COMPLETION_TYPE_NONE = 0;

  /// Enumerated value indicating that we have generated a completion for a
  /// getter.
  static const int _COMPLETION_TYPE_GETTER = 1;

  /// Enumerated value indicating that we have generated a completion for a
  /// setter.
  static const int _COMPLETION_TYPE_SETTER = 2;

  /// Enumerated value indicating that we have generated a completion for a
  /// field, a method, or a getter/setter pair.
  static const int _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET = 3;

  /// The request for which suggestions are being built.
  final DartCompletionRequest request;

  /// Map indicating, for each possible completion identifier, whether we have
  /// already generated completions for a getter, setter, or both.  The "both"
  /// case also handles the case where have generated a completion for a method
  /// or a field.
  ///
  /// Note: the enumerated values stored in this map are intended to be bitwise
  /// compared.
  final Map<String, int> _completionTypesGenerated = HashMap<String, int>();

  /// A map from a completion identifier to a completion suggestion.
  final Map<String, CompletionSuggestion> _suggestionMap =
      <String, CompletionSuggestion>{};

  MemberSuggestionBuilder(this.request);

  Iterable<CompletionSuggestion> get suggestions => _suggestionMap.values;

  /// Add the given completion [suggestion].
  void addCompletionSuggestion(CompletionSuggestion suggestion) {
    _suggestionMap[suggestion.completion] = suggestion;
  }

  /// Add a suggestion for the given [method].
  void addSuggestionForAccessor(
      {@required PropertyAccessorElement accessor,
      String containingMethodName,
      @required double inheritanceDistance}) {
    int oldRelevance() {
      if (accessor.hasDeprecated) {
        return DART_RELEVANCE_LOW;
      }
      String identifier = accessor.displayName;
      if (identifier != null && identifier.startsWith(r'$')) {
        // Decrease relevance of suggestions starting with $
        // https://github.com/dart-lang/sdk/issues/27303
        return DART_RELEVANCE_LOW;
      }
      return DART_RELEVANCE_DEFAULT;
    }

    if (!accessor.isAccessibleIn(request.libraryElement)) {
      // Don't suggest private members from imported libraries.
      return;
    }
    if (accessor.isSynthetic) {
      // Avoid visiting a field twice. All fields induce a getter, but only
      // non-final fields induce a setter, so we don't add a suggestion for a
      // synthetic setter.
      if (accessor.isGetter) {
        var variable = accessor.variable;
        int relevance;
        var useNewRelevance = request.useNewRelevance;
        if (useNewRelevance) {
          var featureComputer = request.featureComputer;
          var contextType = featureComputer.contextTypeFeature(
              request.contextType, variable.type);
          var hasDeprecated = featureComputer.hasDeprecatedFeature(accessor);
          var startsWithDollar =
              featureComputer.startsWithDollarFeature(accessor.name);
          var superMatches = featureComputer.superMatchesFeature(
              containingMethodName, accessor.name);
          relevance = _computeRelevance(
              contextType: contextType,
              hasDeprecated: hasDeprecated,
              inheritanceDistance: inheritanceDistance,
              startsWithDollar: startsWithDollar,
              superMatches: superMatches);
        } else {
          relevance = oldRelevance();
        }
        _addSuggestion(variable, relevance, useNewRelevance);
      }
    } else {
      var type =
          accessor.isGetter ? accessor.returnType : accessor.parameters[0].type;
      int relevance;
      var useNewRelevance = request.useNewRelevance;
      if (useNewRelevance) {
        var featureComputer = request.featureComputer;
        var contextType =
            featureComputer.contextTypeFeature(request.contextType, type);
        var hasDeprecated = featureComputer.hasDeprecatedFeature(accessor);
        var startsWithDollar =
            featureComputer.startsWithDollarFeature(accessor.name);
        var superMatches = featureComputer.superMatchesFeature(
            containingMethodName, accessor.name);
        relevance = _computeRelevance(
            contextType: contextType,
            hasDeprecated: hasDeprecated,
            inheritanceDistance: inheritanceDistance,
            startsWithDollar: startsWithDollar,
            superMatches: superMatches);
      } else {
        relevance = oldRelevance();
      }
      _addSuggestion(accessor, relevance, useNewRelevance);
    }
  }

  /// Add a suggestion for the given [method].
  void addSuggestionForMethod(
      {@required MethodElement method,
      String containingMethodName,
      @required double inheritanceDistance}) {
    int oldRelevance() {
      if (method.hasDeprecated) {
        return DART_RELEVANCE_LOW;
      } else if (method.name == containingMethodName) {
        // Boost the relevance of a super expression calling a method of the
        // same name as the containing method.
        return DART_RELEVANCE_HIGH;
      }
      String identifier = method.displayName;
      if (identifier != null && identifier.startsWith(r'$')) {
        // Decrease relevance of suggestions starting with $
        // https://github.com/dart-lang/sdk/issues/27303
        return DART_RELEVANCE_LOW;
      }
      return DART_RELEVANCE_DEFAULT;
    }

    if (!method.isAccessibleIn(request.libraryElement)) {
      // Don't suggest private members from imported libraries.
      return;
    }
    int relevance;
    var useNewRelevance = request.useNewRelevance;
    if (useNewRelevance) {
      var featureComputer = request.featureComputer;
      var contextType = featureComputer.contextTypeFeature(
          request.contextType, method.returnType);
      var hasDeprecated = featureComputer.hasDeprecatedFeature(method);
      var startsWithDollar =
          featureComputer.startsWithDollarFeature(method.name);
      var superMatches = featureComputer.superMatchesFeature(
          containingMethodName, method.name);
      relevance = _computeRelevance(
          contextType: contextType,
          hasDeprecated: hasDeprecated,
          inheritanceDistance: inheritanceDistance,
          startsWithDollar: startsWithDollar,
          superMatches: superMatches);
    } else {
      relevance = oldRelevance();
    }
    _addSuggestion(method, relevance, useNewRelevance);
  }

  /// Add a suggestion for the given [element] with the given [relevance],
  /// provided that it is not shadowed by a previously added suggestion.
  void _addSuggestion(Element element, int relevance, bool useNewRelevance) {
    String identifier = element.displayName;

    int alreadyGenerated = _completionTypesGenerated.putIfAbsent(
        identifier, () => _COMPLETION_TYPE_NONE);
    if (element is MethodElement) {
      // Anything shadows a method.
      if (alreadyGenerated != _COMPLETION_TYPE_NONE) {
        return;
      }
      _completionTypesGenerated[identifier] =
          _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET;
    } else if (element is PropertyAccessorElement) {
      if (element.isGetter) {
        // Getters, fields, and methods shadow a getter.
        if ((alreadyGenerated & _COMPLETION_TYPE_GETTER) != 0) {
          return;
        }
        _completionTypesGenerated[identifier] |= _COMPLETION_TYPE_GETTER;
      } else {
        // Setters, fields, and methods shadow a setter.
        if ((alreadyGenerated & _COMPLETION_TYPE_SETTER) != 0) {
          return;
        }
        _completionTypesGenerated[identifier] |= _COMPLETION_TYPE_SETTER;
      }
    } else if (element is FieldElement) {
      // Fields and methods shadow a field.  A getter/setter pair shadows a
      // field, but a getter or setter by itself doesn't.
      if (alreadyGenerated == _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET) {
        return;
      }
      _completionTypesGenerated[identifier] =
          _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET;
    } else {
      // Unexpected element type; skip it.
      assert(false);
      return;
    }
    CompletionSuggestion suggestion = createSuggestion(element,
        relevance: relevance, useNewRelevance: useNewRelevance);
    if (suggestion != null) {
      addCompletionSuggestion(suggestion);
    }
  }

  /// Compute a relevance value from the given feature scores:
  /// - [contextType] is higher if the type of the element matches the context
  ///   type,
  /// - [hasDeprecated] is higher if the element is not deprecated,
  /// - [inheritanceDistance] is higher if the element is defined closer to the
  ///   target type,
  /// - [startsWithDollar] is higher if the element's name doe _not_ start with
  ///   a dollar sign, and
  /// - [superMatches] is higher if the element is being invoked through `super`
  ///   and the element's name matches the name of the enclosing method.
  int _computeRelevance(
      {@required double contextType,
      @required double hasDeprecated,
      @required double inheritanceDistance,
      @required double startsWithDollar,
      @required double superMatches}) {
    var score = weightedAverage([
      contextType,
      hasDeprecated,
      inheritanceDistance,
      startsWithDollar,
      superMatches
    ], [
      1.0,
      0.5,
      1.0,
      0.5,
      1.0
    ]);
    return toRelevance(score, Relevance.member);
  }
}
