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
import 'package:analysis_server/src/utilities/flutter.dart';
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
      completion.length, 0, element.hasOrInheritsDeprecated, false);

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

  /// The builder used to build the suggestions.
  final SuggestionBuilder builder;

  /// Map indicating, for each possible completion identifier, whether we have
  /// already generated completions for a getter, setter, or both.  The "both"
  /// case also handles the case where have generated a completion for a method
  /// or a field.
  ///
  /// Note: the enumerated values stored in this map are intended to be bitwise
  /// compared.
  final Map<String, int> _completionTypesGenerated = HashMap<String, int>();

  MemberSuggestionBuilder(this.request, this.builder);

  /// Add a suggestion for the given [accessor].
  void addSuggestionForAccessor(
      {@required PropertyAccessorElement accessor,
      String containingMethodName,
      @required double inheritanceDistance}) {
    if (accessor.isAccessibleIn(request.libraryElement)) {
      var member = accessor.isSynthetic ? accessor.variable : accessor;
      if (_shouldAddSuggestion(member)) {
        builder.suggestAccessor(accessor,
            containingMemberName: containingMethodName,
            inheritanceDistance: inheritanceDistance);
      }
    }
  }

  /// Add a suggestion for the given [method].
  void addSuggestionForMethod(
      {@required MethodElement method,
      String containingMethodName,
      CompletionSuggestionKind kind,
      @required double inheritanceDistance}) {
    if (method.isAccessibleIn(request.libraryElement) &&
        _shouldAddSuggestion(method)) {
      builder.suggestMethod(method,
          containingMemberName: containingMethodName,
          kind: kind,
          inheritanceDistance: inheritanceDistance);
    }
  }

  /// Return `true` if a suggestion for the given [element] should be created.
  bool _shouldAddSuggestion(Element element) {
    // TODO(brianwilkerson) Consider moving this into SuggestionBuilder.
    var identifier = element.displayName;

    var alreadyGenerated = _completionTypesGenerated.putIfAbsent(
        identifier, () => _COMPLETION_TYPE_NONE);
    if (element is MethodElement) {
      // Anything shadows a method.
      if (alreadyGenerated != _COMPLETION_TYPE_NONE) {
        return false;
      }
      _completionTypesGenerated[identifier] =
          _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET;
    } else if (element is PropertyAccessorElement) {
      if (element.isGetter) {
        // Getters, fields, and methods shadow a getter.
        if ((alreadyGenerated & _COMPLETION_TYPE_GETTER) != 0) {
          return false;
        }
        _completionTypesGenerated[identifier] |= _COMPLETION_TYPE_GETTER;
      } else {
        // Setters, fields, and methods shadow a setter.
        if ((alreadyGenerated & _COMPLETION_TYPE_SETTER) != 0) {
          return false;
        }
        _completionTypesGenerated[identifier] |= _COMPLETION_TYPE_SETTER;
      }
    } else if (element is FieldElement) {
      // Fields and methods shadow a field.  A getter/setter pair shadows a
      // field, but a getter or setter by itself doesn't.
      if (alreadyGenerated == _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET) {
        return false;
      }
      _completionTypesGenerated[identifier] =
          _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET;
    } else {
      // Unexpected element type; skip it.
      assert(false);
      return false;
    }
    return true;
  }
}

/// An object used to build a list of suggestions in response to a single
/// completion request.
class SuggestionBuilder {
  /// The completion request for which suggestions are being built.
  final DartCompletionRequest request;

  /// A map from a completion identifier to a completion suggestion.
  final Map<String, CompletionSuggestion> _suggestionMap =
      <String, CompletionSuggestion>{};

  /// A flag indicating whether a suggestion should replace any earlier
  /// suggestions for the same completion (`true`) or whether earlier
  /// suggestions should take priority over more recent suggestions.
  // TODO(brianwilkerson) Attempt to convert the contributors so that a single
  //  approach is followed.
  bool laterReplacesEarlier = true;

  /// A flag indicating whether the [_cachedContextType] has been computed.
  bool _hasContextType = false;

  /// The context type associated with the completion location, or `null` if
  /// either the location does not have a context type, or if the context type
  /// has not yet been computed. In the latter case, [_hasContextType] will be
  /// `false`.
  DartType _cachedContextType;

  /// The cached instance of the flutter utilities, or `null` if it hasn't been
  /// created yet.
  Flutter _flutter;

  /// Initialize a newly created suggestion builder to build suggestions for the
  /// given [request].
  SuggestionBuilder(this.request);

  /// Return an object that can answer questions about Flutter code based on the
  /// flavor of Flutter being used.
  Flutter get flutter => _flutter ??= Flutter.of(request.result);

  /// Return an iterable that can be used to access the completion suggestions
  /// that have been built.
  Iterable<CompletionSuggestion> get suggestions => _suggestionMap.values;

  DartType get _contextType {
    if (!_hasContextType) {
      _hasContextType = true;
      _cachedContextType = request.featureComputer
          .computeContextType(request.target.containingNode);
    }
    return _cachedContextType;
  }

  /// Add a suggestion for the [accessor]. If the accessor is being invoked with
  /// a target of `super`, then the [containingMemberName] should be the name of
  /// the member containing the invocation. The [inheritanceDistance] is the
  /// value of the inheritance distance feature computed for the method.
  void suggestAccessor(PropertyAccessorElement accessor,
      {String containingMemberName, @required double inheritanceDistance}) {
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
          var elementKind = featureComputer.elementKindFeature(
              variable, request.opType.completionLocation);
          var hasDeprecated = featureComputer.hasDeprecatedFeature(accessor);
          var startsWithDollar =
              featureComputer.startsWithDollarFeature(accessor.name);
          var superMatches = featureComputer.superMatchesFeature(
              containingMemberName, accessor.name);
          relevance = _computeMemberRelevance(
              contextType: contextType,
              elementKind: elementKind,
              hasDeprecated: hasDeprecated,
              inheritanceDistance: inheritanceDistance,
              startsWithDollar: startsWithDollar,
              superMatches: superMatches);
        } else {
          relevance = _computeOldMemberRelevance(accessor);
        }
        _add(createSuggestion(request, variable, relevance: relevance));
      }
    } else {
      var type =
          accessor.isGetter ? accessor.returnType : accessor.parameters[0].type;
      int relevance;
      if (request.useNewRelevance) {
        var featureComputer = request.featureComputer;
        var contextType =
            featureComputer.contextTypeFeature(request.contextType, type);
        var elementKind = featureComputer.elementKindFeature(
            accessor, request.opType.completionLocation);
        var hasDeprecated = featureComputer.hasDeprecatedFeature(accessor);
        var startsWithDollar =
            featureComputer.startsWithDollarFeature(accessor.name);
        var superMatches = featureComputer.superMatchesFeature(
            containingMemberName, accessor.name);
        relevance = _computeMemberRelevance(
            contextType: contextType,
            elementKind: elementKind,
            hasDeprecated: hasDeprecated,
            inheritanceDistance: inheritanceDistance,
            startsWithDollar: startsWithDollar,
            superMatches: superMatches);
      } else {
        relevance = _computeOldMemberRelevance(accessor);
      }
      _add(createSuggestion(request, accessor, relevance: relevance));
    }
  }

  /// Add a suggestion for the [classElement]. If a [kind] is provided it will
  /// be used as the kind for the suggestion.
  void suggestClass(ClassElement classElement,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    int relevance;
    if (request.useNewRelevance) {
      relevance = _computeTopLevelRelevance(classElement,
          elementType: _instantiateClassElement(classElement));
    } else if (classElement.hasOrInheritsDeprecated) {
      relevance = DART_RELEVANCE_LOW;
    } else {
      relevance = request.opType.typeNameSuggestionsFilter(
          _instantiateClassElement(classElement), DART_RELEVANCE_DEFAULT);
      if (relevance == null) {
        return;
      }
    }

    _add(createSuggestion(request, classElement,
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
      relevance = constructor.hasOrInheritsDeprecated
          ? DART_RELEVANCE_LOW
          : DART_RELEVANCE_DEFAULT;
    }

    _add(createSuggestion(request, constructor,
        completion: completion, kind: kind, relevance: relevance));
  }

  /// Add a suggestion for the top-level [element]. If a [kind] is provided it
  /// will be used as the kind for the suggestion.
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

  /// Add a suggestion for the enum [constant].
  void suggestEnumConstant(FieldElement constant) {
    var constantName = constant.name;
    var enumElement = constant.enclosingElement;
    var enumName = enumElement.name;
    var completion = '$enumName.$constantName';

    int relevance;
    if (request.useNewRelevance) {
      relevance =
          _computeTopLevelRelevance(constant, elementType: constant.type);
    } else if (constant.hasOrInheritsDeprecated) {
      relevance = DART_RELEVANCE_LOW;
    } else {
      relevance = request.opType.returnValueSuggestionsFilter(
          _instantiateClassElement(enumElement), DART_RELEVANCE_DEFAULT);
      if (relevance == null) {
        return;
      }
    }

    _add(createSuggestion(request, constant,
        completion: completion, relevance: relevance));
  }

  /// Add a suggestion for the [extension]. If a [kind] is provided it will be
  /// used as the kind for the suggestion.
  void suggestExtension(ExtensionElement extension,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    int relevance;
    if (request.useNewRelevance) {
      relevance = _computeTopLevelRelevance(extension,
          elementType: extension.extendedType);
    } else {
      relevance = extension.hasOrInheritsDeprecated
          ? DART_RELEVANCE_LOW
          : DART_RELEVANCE_DEFAULT;
    }

    _add(
        createSuggestion(request, extension, kind: kind, relevance: relevance));
  }

  /// Add a suggestion to reference the [field] in a field formal parameter.
  void suggestFieldFormalParameter(FieldElement field) {
    // TODO(brianwilkerson) Add a parameter (`bool includePrefix`) indicating
    //  whether to include the `this.` prefix in the completion.
    var relevance = request.useNewRelevance
        ? Relevance.fieldFormalParameter
        : DART_RELEVANCE_LOCAL_FIELD;

    _add(createSuggestion(request, field, relevance: relevance));
  }

  /// Add a suggestion for the `call` method defined on functions.
  void suggestFunctionCall() {
    const callString = 'call()';
    final element = protocol.Element(
        protocol.ElementKind.METHOD, callString, protocol.Element.makeFlags(),
        location: null,
        typeParameters: null,
        parameters: null,
        returnType: 'void');
    _add(CompletionSuggestion(
      CompletionSuggestionKind.INVOCATION,
      request.useNewRelevance ? Relevance.callFunction : DART_RELEVANCE_HIGH,
      callString,
      callString.length,
      0,
      false,
      false,
      displayText: callString,
      element: element,
      returnType: 'void',
    ));
  }

  /// Add a suggestion for the [functionTypeAlias]. If a [kind] is provided it
  /// will be used as the kind for the suggestion.
  void suggestFunctionTypeAlias(FunctionTypeAliasElement functionTypeAlias,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    int relevance;
    if (request.useNewRelevance) {
      relevance = _computeTopLevelRelevance(functionTypeAlias,
          defaultRelevance: 750,
          elementType: _instantiateFunctionTypeAlias(functionTypeAlias));
    } else if (functionTypeAlias.hasOrInheritsDeprecated) {
      relevance = DART_RELEVANCE_LOW;
    } else {
      relevance = functionTypeAlias.library == request.libraryElement
          ? DART_RELEVANCE_LOCAL_FUNCTION
          : DART_RELEVANCE_DEFAULT;
    }
    _add(createSuggestion(request, functionTypeAlias,
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
      relevance = function.hasOrInheritsDeprecated
          ? DART_RELEVANCE_LOW
          : DART_RELEVANCE_DEFAULT;
    }

    _add(createSuggestion(request, function, relevance: relevance));
  }

  /// Add a suggestion for the [method]. If the method is being invoked with a
  /// target of `super`, then the [containingMemberName] should be the name of
  /// the member containing the invocation. If a [kind] is provided it will be
  /// used as the kind for the suggestion. The [inheritanceDistance] is the
  /// value of the inheritance distance feature computed for the method.
  void suggestMethod(MethodElement method,
      {String containingMemberName,
      CompletionSuggestionKind kind,
      @required double inheritanceDistance}) {
    // TODO(brianwilkerson) Refactor callers so that we're passing in the type
    //  of the target (assuming we don't already have that type available via
    //  the [request]) and compute the [inheritanceDistance] in this method.
    int relevance;
    if (request.useNewRelevance) {
      var featureComputer = request.featureComputer;
      var contextType = featureComputer.contextTypeFeature(
          request.contextType, method.returnType);
      var elementKind = featureComputer.elementKindFeature(
          method, request.opType.completionLocation);
      var hasDeprecated = featureComputer.hasDeprecatedFeature(method);
      var startsWithDollar =
          featureComputer.startsWithDollarFeature(method.name);
      var superMatches = featureComputer.superMatchesFeature(
          containingMemberName, method.name);
      relevance = _computeMemberRelevance(
          contextType: contextType,
          elementKind: elementKind,
          hasDeprecated: hasDeprecated,
          inheritanceDistance: inheritanceDistance,
          startsWithDollar: startsWithDollar,
          superMatches: superMatches);
    } else {
      relevance = _computeOldMemberRelevance(method,
          containingMethodName: containingMemberName);
    }

    var suggestion =
        createSuggestion(request, method, kind: kind, relevance: relevance);
    if (suggestion != null) {
      if (method.name == 'setState' &&
          flutter.isExactState(method.enclosingElement)) {
        // TODO(brianwilkerson) Make this more efficient by creating the correct
        //  suggestion in the first place.
        // Find the line indentation.
        var indent = getRequestLineIndent(request);

        // Let the user know that we are going to insert a complete statement.
        suggestion.displayText = 'setState(() {});';

        // Build the completion and the selection offset.
        var buffer = StringBuffer();
        buffer.writeln('setState(() {');
        buffer.write('$indent  ');
        suggestion.selectionOffset = buffer.length;
        buffer.writeln();
        buffer.write('$indent});');
        suggestion.completion = buffer.toString();

        // There are no arguments to fill.
        suggestion.parameterNames = null;
        suggestion.parameterTypes = null;
        suggestion.requiredParameterCount = null;
        suggestion.hasNamedParameters = null;
      }
      _add(suggestion);
    }
  }

  /// Add a suggestion for the top-level [function]. If a [kind] is provided it
  /// will be used as the kind for the suggestion.
  void suggestTopLevelFunction(FunctionElement function,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    int relevance;
    if (request.useNewRelevance) {
      relevance =
          _computeTopLevelRelevance(function, elementType: function.returnType);
    } else if (function.hasOrInheritsDeprecated) {
      relevance = DART_RELEVANCE_LOW;
    } else {
      relevance = function.library == request.libraryElement
          ? DART_RELEVANCE_LOCAL_FUNCTION
          : DART_RELEVANCE_DEFAULT;
    }

    _add(createSuggestion(request, function, kind: kind, relevance: relevance));
  }

  /// Add a suggestion for the top-level property [accessor]. If a [kind] is
  /// provided it will be used as the kind for the suggestion.
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
    } else if (accessor.hasOrInheritsDeprecated) {
      relevance = DART_RELEVANCE_LOW;
    } else {
      relevance = variable.library == request.libraryElement
          ? DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE
          : DART_RELEVANCE_DEFAULT;
    }

    _add(createSuggestion(request, variable, kind: kind, relevance: relevance));
  }

  /// Add the given [suggestion] if it isn't `null`.
  void _add(protocol.CompletionSuggestion suggestion) {
    if (suggestion != null) {
      if (laterReplacesEarlier) {
        _suggestionMap[suggestion.completion] = suggestion;
      } else {
        _suggestionMap.putIfAbsent(suggestion.completion, () => suggestion);
      }
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
  int _computeMemberRelevance(
      {@required double contextType,
      @required double elementKind,
      @required double hasDeprecated,
      @required double inheritanceDistance,
      @required double startsWithDollar,
      @required double superMatches}) {
    var score = weightedAverage([
      contextType,
      elementKind,
      hasDeprecated,
      inheritanceDistance,
      startsWithDollar,
      superMatches
    ], [
      1.0,
      0.75,
      0.5,
      1.0,
      0.5,
      1.0
    ]);
    return toRelevance(score, Relevance.member);
  }

  /// Compute the old relevance score for a member.
  int _computeOldMemberRelevance(Element member,
      {String containingMethodName}) {
    if (member.hasOrInheritsDeprecated) {
      return DART_RELEVANCE_LOW;
    } else if (member.name == containingMethodName) {
      // Boost the relevance of a super expression calling a method of the
      // same name as the containing method.
      return DART_RELEVANCE_HIGH;
    }
    var identifier = member.displayName;
    if (identifier != null && identifier.startsWith(r'$')) {
      // Decrease relevance of suggestions starting with $
      // https://github.com/dart-lang/sdk/issues/27303
      return DART_RELEVANCE_LOW;
    }
    return DART_RELEVANCE_DEFAULT;
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
            [contextTypeFeature, elementKind, hasDeprecated], [1.0, 0.75, 0.2]),
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

  FunctionType _instantiateFunctionTypeAlias(FunctionTypeAliasElement element) {
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
