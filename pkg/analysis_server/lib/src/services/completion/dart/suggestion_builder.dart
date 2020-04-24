// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:meta/meta.dart';

/// Return a suggestion based on the given [element], or `null` if a suggestion
/// is not appropriate for the given element.
CompletionSuggestion createSuggestion(
    DartCompletionRequest request, Element element,
    {String completion,
    CompletionSuggestionKind kind,
    int relevance = DART_RELEVANCE_DEFAULT}) {
  if (element == null) {
    return null;
  }
  if (element is ExecutableElement && element.isOperator) {
    // Do not include operators in suggestions
    return null;
  }
  completion ??= element.displayName;
  if (completion == null || completion.isEmpty) {
    return null;
  }
  kind ??= CompletionSuggestionKind.INVOCATION;
  var suggestion = CompletionSuggestion(kind, relevance, completion,
      completion.length, 0, element.hasDeprecated, false);

  // Attach docs.
  var doc = DartUnitHoverComputer.computeDocumentation(
      request.dartdocDirectiveInfo, element);
  if (doc != null) {
    suggestion.docComplete = doc;
    suggestion.docSummary = getDartDocSummary(doc);
  }

  suggestion.element = protocol.convertElement(element);
  var enclosingElement = element.enclosingElement;
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
      var paramType = parameter.type;
      // Gracefully degrade if type not resolved yet
      return paramType != null
          ? paramType.getDisplayString(withNullability: false)
          : 'var';
    }).toList();

    var requiredParameters = element.parameters
        .where((ParameterElement param) => param.isRequiredPositional);
    suggestion.requiredParameterCount = requiredParameters.length;

    var namedParameters =
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

  /// Return the completion request for which suggestions are being built.
  DartCompletionRequest get request;

  /// Add a suggestion based upon the given element.
  CompletionSuggestion addSuggestion(Element element,
      {String prefix,
      int relevance = DART_RELEVANCE_DEFAULT,
      String elementCompletion}) {
    if (element.isPrivate) {
      if (element.library != containingLibrary) {
        return null;
      }
    }
    var completion = elementCompletion ?? element.displayName;
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
    var suggestion = createSuggestion(request, element,
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
          var existingSuggestion = _syntheticMap[cacheKey];

          // Pair getter/setter by updating the existing suggestion
          if (existingSuggestion != null) {
            var getter = element.isGetter ? suggestion : existingSuggestion;
            var elemKind = element.enclosingElement is ClassElement
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
  CompletionSuggestion addSuggestionForAccessor(
      {@required PropertyAccessorElement accessor,
      String containingMethodName,
      @required double inheritanceDistance}) {
    int oldRelevance() {
      if (accessor.hasDeprecated) {
        return DART_RELEVANCE_LOW;
      }
      var identifier = accessor.displayName;
      if (identifier != null && identifier.startsWith(r'$')) {
        // Decrease relevance of suggestions starting with $
        // https://github.com/dart-lang/sdk/issues/27303
        return DART_RELEVANCE_LOW;
      }
      return DART_RELEVANCE_DEFAULT;
    }

    if (!accessor.isAccessibleIn(request.libraryElement)) {
      // Don't suggest private members from imported libraries.
      return null;
    }
    if (accessor.isSynthetic) {
      // Avoid visiting a field twice. All fields induce a getter, but only
      // non-final fields induce a setter, so we don't add a suggestion for a
      // synthetic setter.
      if (accessor.isGetter) {
        var variable = accessor.variable;
        int relevance;
        if (request.useNewRelevance) {
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
        return _addSuggestion(variable, relevance);
      }
    } else {
      var type =
          accessor.isGetter ? accessor.returnType : accessor.parameters[0].type;
      int relevance;
      if (request.useNewRelevance) {
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
      return _addSuggestion(accessor, relevance);
    }
    return null;
  }

  /// Add a suggestion for the given [method].
  CompletionSuggestion addSuggestionForMethod(
      {@required MethodElement method,
      String containingMethodName,
      CompletionSuggestionKind kind,
      @required double inheritanceDistance}) {
    int oldRelevance() {
      if (method.hasDeprecated) {
        return DART_RELEVANCE_LOW;
      } else if (method.name == containingMethodName) {
        // Boost the relevance of a super expression calling a method of the
        // same name as the containing method.
        return DART_RELEVANCE_HIGH;
      }
      var identifier = method.displayName;
      if (identifier != null && identifier.startsWith(r'$')) {
        // Decrease relevance of suggestions starting with $
        // https://github.com/dart-lang/sdk/issues/27303
        return DART_RELEVANCE_LOW;
      }
      return DART_RELEVANCE_DEFAULT;
    }

    if (!method.isAccessibleIn(request.libraryElement)) {
      // Don't suggest private members from imported libraries.
      return null;
    }
    int relevance;
    if (request.useNewRelevance) {
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
    return _addSuggestion(method, relevance, kind: kind);
  }

  /// Add a suggestion for the given [element] with the given [relevance],
  /// provided that it is not shadowed by a previously added suggestion.
  CompletionSuggestion _addSuggestion(Element element, int relevance,
      {CompletionSuggestionKind kind}) {
    var identifier = element.displayName;

    var alreadyGenerated = _completionTypesGenerated.putIfAbsent(
        identifier, () => _COMPLETION_TYPE_NONE);
    if (element is MethodElement) {
      // Anything shadows a method.
      if (alreadyGenerated != _COMPLETION_TYPE_NONE) {
        return null;
      }
      _completionTypesGenerated[identifier] =
          _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET;
    } else if (element is PropertyAccessorElement) {
      if (element.isGetter) {
        // Getters, fields, and methods shadow a getter.
        if ((alreadyGenerated & _COMPLETION_TYPE_GETTER) != 0) {
          return null;
        }
        _completionTypesGenerated[identifier] |= _COMPLETION_TYPE_GETTER;
      } else {
        // Setters, fields, and methods shadow a setter.
        if ((alreadyGenerated & _COMPLETION_TYPE_SETTER) != 0) {
          return null;
        }
        _completionTypesGenerated[identifier] |= _COMPLETION_TYPE_SETTER;
      }
    } else if (element is FieldElement) {
      // Fields and methods shadow a field.  A getter/setter pair shadows a
      // field, but a getter or setter by itself doesn't.
      if (alreadyGenerated == _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET) {
        return null;
      }
      _completionTypesGenerated[identifier] =
          _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET;
    } else {
      // Unexpected element type; skip it.
      assert(false);
      return null;
    }
    var suggestion =
        createSuggestion(request, element, kind: kind, relevance: relevance);
    if (suggestion != null) {
      addCompletionSuggestion(suggestion);
    }
    return suggestion;
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

/// An object used to build a list of suggestions in response to a single
/// completion request.
class SuggestionBuilder {
  /// The completion request for which suggestions are being built.
  final DartCompletionRequest request;

  /// A collection of completion suggestions.
  final List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];

  /// A flag indicating whether the [_cachedContextType] has been computed.
  bool _hasContextType = false;

  /// The context type associated with the completion location, or `null` if
  /// either the location does not have a context type, or if the context type
  /// has not yet been computed. In the latter case, [_hasContextType] will be
  /// `false`.
  DartType _cachedContextType;

  /// Initialize a newly created suggestion builder to build suggestions for the
  /// given [request].
  SuggestionBuilder(this.request);

  DartType get _contextType {
    if (!_hasContextType) {
      _hasContextType = true;
      _cachedContextType = request.featureComputer
          .computeContextType(request.target.containingNode);
    }
    return _cachedContextType;
  }

  /// Add a suggestion for the [classElement].
  void suggestClass(ClassElement classElement,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    int relevance;
    if (request.useNewRelevance) {
      relevance = _computeTopLevelRelevance(classElement,
          elementType: _instantiateClassElement(classElement));
    } else if (classElement.hasDeprecated) {
      relevance = DART_RELEVANCE_LOW;
    } else {
      relevance = request.opType.typeNameSuggestionsFilter(
          _instantiateClassElement(classElement), DART_RELEVANCE_DEFAULT);
    }

    suggestions.add(createSuggestion(request, classElement,
        kind: kind, relevance: relevance));
  }

  /// Add a suggestion for the [constructor]. If a [kind] is provided
  /// it will be used as the kind for the suggestion.
  void suggestConstructor(ConstructorElement constructor,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    var classElement = constructor.enclosingElement;
    if (classElement == null) {
      return;
    }
    var prefix = classElement.name;
    // TODO(brianwilkerson) It shouldn't be necessary to test for an empty
    //  prefix.
    if (prefix == null || prefix.isEmpty) {
      return;
    }

    var completion = constructor.displayName;
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

    int relevance;
    if (request.useNewRelevance) {
      relevance = _computeTopLevelRelevance(constructor);
    } else {
      relevance = constructor.hasDeprecated
          ? DART_RELEVANCE_LOW
          : DART_RELEVANCE_DEFAULT;
    }

    suggestions.add(createSuggestion(request, constructor,
        completion: completion, kind: kind, relevance: relevance));
  }

  /// Add a suggestion for the [element].
  void suggestElement(Element element,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    if (element is ClassElement) {
      suggestClass(element, kind: kind);
    } else if (element is ConstructorElement) {
      suggestConstructor(element, kind: kind);
    } else if (element is ExtensionElement) {
      suggestExtension(element, kind: kind);
    } else if (element is FunctionElement &&
        element.enclosingElement is CompilationUnitElement) {
      suggestTopLevelFunction(element, kind: kind);
    } else if (element is FunctionTypeAliasElement) {
      suggestFunctionTypeAlias(element, kind: kind);
    } else if (element is PropertyAccessorElement &&
        element.enclosingElement is CompilationUnitElement) {
      suggestTopLevelPropertyAccessor(element, kind: kind);
    } else {
      throw ArgumentError('Cannot suggest a ${element.runtimeType}');
    }
  }

  /// Add a suggestion for the [extension].
  void suggestExtension(ExtensionElement extension,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    int relevance;
    if (request.useNewRelevance) {
      relevance = _computeTopLevelRelevance(extension,
          elementType: extension.extendedType);
    } else {
      relevance =
          extension.hasDeprecated ? DART_RELEVANCE_LOW : DART_RELEVANCE_DEFAULT;
    }

    suggestions.add(
        createSuggestion(request, extension, kind: kind, relevance: relevance));
  }

  /// Add a suggestion for the [functionTypeAlias].
  void suggestFunctionTypeAlias(FunctionTypeAliasElement functionTypeAlias,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    int relevance;
    if (request.useNewRelevance) {
      relevance =
          _computeTopLevelRelevance(functionTypeAlias, defaultRelevance: 750);
    } else {
      relevance = functionTypeAlias.hasDeprecated
          ? DART_RELEVANCE_LOW
          : (functionTypeAlias.library == request.libraryElement
              ? DART_RELEVANCE_LOCAL_FUNCTION
              : DART_RELEVANCE_DEFAULT);
    }
    suggestions.add(createSuggestion(request, functionTypeAlias,
        kind: kind, relevance: relevance));
  }

  /// Add a suggestion for the `loadLibrary` [function] associated with a
  /// prefix.
  void suggestLoadLibraryFunction(FunctionElement function) {
    int relevance;
    if (request.useNewRelevance) {
      // TODO(brianwilkerson) This might want to use the context type rather
      //  than a fixed value.
      relevance = Relevance.loadLibrary;
    } else {
      relevance =
          function.hasDeprecated ? DART_RELEVANCE_LOW : DART_RELEVANCE_DEFAULT;
    }

    suggestions.add(createSuggestion(request, function, relevance: relevance));
  }

  /// Add a suggestion for the top-level [function].
  void suggestTopLevelFunction(FunctionElement function,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    int relevance;
    if (request.useNewRelevance) {
      relevance =
          _computeTopLevelRelevance(function, elementType: function.returnType);
    } else {
      relevance = function.hasDeprecated
          ? DART_RELEVANCE_LOW
          : (function.library == request.libraryElement
              ? DART_RELEVANCE_LOCAL_FUNCTION
              : DART_RELEVANCE_DEFAULT);
    }

    suggestions.add(
        createSuggestion(request, function, kind: kind, relevance: relevance));
  }

  /// Add a suggestion for the top-level property [accessor].
  void suggestTopLevelPropertyAccessor(PropertyAccessorElement accessor,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    if (accessor.isSetter && accessor.isSynthetic) {
      // TODO(brianwilkerson) Only discard the setter if a suggestion is built
      //  for the corresponding getter. Currently that's always the case.
      //  Handling this more generally will require the ability to build
      //  suggestions for setters and then remove them later when the
      //  corresponding getter is found.
      return;
    }
    // TODO(brianwilkerson) Should we use the variable only when the [element]
    //  is synthetic?
    var variable = accessor.variable;
    int relevance;
    if (request.useNewRelevance) {
      relevance =
          _computeTopLevelRelevance(variable, elementType: variable.type);
    } else {
      relevance = accessor.hasDeprecated
          ? DART_RELEVANCE_LOW
          : (variable.library == request.libraryElement
              ? DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE
              : DART_RELEVANCE_DEFAULT);
    }

    suggestions.add(
        createSuggestion(request, variable, kind: kind, relevance: relevance));
  }

  /// Return the relevance score for a top-level [element].
  int _computeTopLevelRelevance(Element element,
      {int defaultRelevance = 800, DartType elementType}) {
    // TODO(brianwilkerson) The old relevance computation used a signal based
    //  on whether the element being suggested was from the same library in
    //  which completion is being performed. Explore whether that's a useful
    //  signal.
    var featureComputer = request.featureComputer;
    var contextTypeFeature =
        featureComputer.contextTypeFeature(_contextType, elementType);
    var elementKind = featureComputer.elementKindFeature(
        element, request.opType.completionLocation);
    var hasDeprecated = featureComputer.hasDeprecatedFeature(element);
    return toRelevance(
        weightedAverage(
            [contextTypeFeature, elementKind, hasDeprecated], [0.8, 0.8, 0.2]),
        defaultRelevance);
  }

  InterfaceType _instantiateClassElement(ClassElement element) {
    var typeParameters = element.typeParameters;
    var typeArguments = const <DartType>[];
    if (typeParameters.isNotEmpty) {
      var neverType = request.libraryElement.typeProvider.neverType;
      typeArguments = List.filled(typeParameters.length, neverType);
    }

    var nullabilitySuffix = request.featureSet.isEnabled(Feature.non_nullable)
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;

    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }
}
