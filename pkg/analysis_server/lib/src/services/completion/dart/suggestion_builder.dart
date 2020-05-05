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
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:meta/meta.dart';

/// Return a suggestion based on the given [element], or `null` if a suggestion
/// is not appropriate for the given element.
CompletionSuggestion createSuggestion(
    DartCompletionRequest request, Element element,
    {String completion,
    protocol.ElementKind elementKind,
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
  if (elementKind != null) {
    suggestion.element.kind = elementKind;
  }
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
      @required double inheritanceDistance}) {
    if (accessor.isAccessibleIn(request.libraryElement)) {
      var member = accessor.isSynthetic ? accessor.variable : accessor;
      if (_shouldAddSuggestion(member)) {
        builder.suggestAccessor(accessor,
            inheritanceDistance: inheritanceDistance);
      }
    }
  }

  /// Add a suggestion for the given [method].
  void addSuggestionForMethod(
      {@required MethodElement method,
      CompletionSuggestionKind kind,
      @required double inheritanceDistance}) {
    if (method.isAccessibleIn(request.libraryElement) &&
        _shouldAddSuggestion(method)) {
      builder.suggestMethod(method,
          kind: kind, inheritanceDistance: inheritanceDistance);
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

  /// A flag indicating whether the [_cachedContainingMemberName] has been
  /// computed.
  bool _hasContainingMemberName = false;

  /// The name of the member containing the completion location, or `null` if
  /// either the completion location isn't within a member, the target of the
  /// completion isn't `super`, or the name of the member hasn't yet been
  /// computed. In the latter case, [_hasContainingMemberName] will be `false`.
  String _cachedContainingMemberName;

  /// A flag indicating whether the [_cachedContextType] has been computed.
  bool _hasContextType = false;

  /// The context type associated with the completion location, or `null` if
  /// either the location doesn't have a context type, or the context type
  /// hasn't yet been computed. In the latter case, [_hasContextType] will be
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

  /// Return the name of the member containing the completion location, or
  /// `null` if the completion location isn't within a member or if the target
  /// of the completion isn't `super`.
  String get _containingMemberName {
    if (!_hasContainingMemberName) {
      _hasContainingMemberName = true;
      if (request.dotTarget is SuperExpression) {
        var containingMethod = request.target.containingNode
            .thisOrAncestorOfType<MethodDeclaration>();
        if (containingMethod != null) {
          var id = containingMethod.name;
          if (id != null) {
            _cachedContainingMemberName = id.name;
          }
        }
      }
    }
    return _cachedContainingMemberName;
  }

  /// Return the context type associated with the completion location, or `null`
  /// if the location doesn't have a context type.
  DartType get _contextType {
    if (!_hasContextType) {
      _hasContextType = true;
      _cachedContextType = request.featureComputer
          .computeContextType(request.target.containingNode);
    }
    return _cachedContextType;
  }

  /// Add a suggestion for an [accessor] declared within a class or extension.
  /// If the accessor is being invoked with a target of `super`, then the
  /// [containingMemberName] should be the name of the member containing the
  /// invocation. The [inheritanceDistance] is the value of the inheritance
  /// distance feature computed for the accessor (or `-1.0` if the accessor is a
  /// static accessor).
  void suggestAccessor(PropertyAccessorElement accessor,
      {@required double inheritanceDistance}) {
    assert(accessor.enclosingElement is ClassElement ||
        accessor.enclosingElement is ExtensionElement);
    if (accessor.isSynthetic) {
      // Avoid visiting a field twice. All fields induce a getter, but only
      // non-final fields induce a setter, so we don't add a suggestion for a
      // synthetic setter.
      if (accessor.isGetter) {
        var variable = accessor.variable;
        if (variable is FieldElement) {
          suggestField(variable, inheritanceDistance: inheritanceDistance);
        }
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
            _containingMemberName, accessor.name);
        relevance = _computeMemberRelevance(
            contextType: contextType,
            elementKind: elementKind,
            hasDeprecated: hasDeprecated,
            inheritanceDistance: inheritanceDistance,
            startsWithDollar: startsWithDollar,
            superMatches: superMatches);
      } else {
        relevance = _computeOldMemberRelevance(accessor);
        if (request.opType.includeReturnValueSuggestions) {
          relevance =
              request.opType.returnValueSuggestionsFilter(type, relevance);
        }
        if (relevance == null) {
          return;
        }
      }
      _add(createSuggestion(request, accessor, relevance: relevance));
    }
  }

  /// Add a suggestion for a catch [parameter].
  void suggestCatchParameter(LocalVariableElement parameter) {
    var variableType = parameter.type;
    int relevance;
    if (request.useNewRelevance) {
      var contextTypeFeature = request.featureComputer
          .contextTypeFeature(_contextType, variableType);
      relevance = toRelevance(contextTypeFeature, 800);
    } else {
      relevance = _computeOldMemberRelevance(parameter);
      relevance =
          request.opType.returnValueSuggestionsFilter(variableType, relevance);
      if (relevance == null) {
        return;
      }
    }

    _add(createSuggestion(request, parameter,
        elementKind: protocol.ElementKind.PARAMETER, relevance: relevance));
  }

  /// Add a suggestion for a [classElement]. If a [kind] is provided it will
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

  /// Add a suggestion for a [constructor]. If a [kind] is provided it will be
  /// used as the kind for the suggestion. The flag [hasClassName] should be
  /// `true` if the completion is occurring after the name of the class and a
  /// period, and hence should not include the name of the class.
  void suggestConstructor(ConstructorElement constructor,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      bool hasClassName = false}) {
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
    if (!hasClassName && prefix != null && prefix.isNotEmpty) {
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

  /// Add a suggestion for a top-level [element]. If a [kind] is provided it
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

  /// Add a suggestion for an enum [constant].
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

  /// Add a suggestion for an [extension]. If a [kind] is provided it will be
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

  /// Add a suggestion for a [field]. If the field is being referenced with a
  /// target of `super`, then the [containingMemberName] should be the name of
  /// the member containing the reference. The [inheritanceDistance] is the
  /// value of the inheritance distance feature computed for the field (or
  /// `-1.0` if the field is a static field).
  void suggestField(FieldElement field,
      {@required double inheritanceDistance}) {
    int relevance;
    if (request.useNewRelevance) {
      var featureComputer = request.featureComputer;
      var contextType =
          featureComputer.contextTypeFeature(request.contextType, field.type);
      var elementKind = featureComputer.elementKindFeature(
          field, request.opType.completionLocation);
      var hasDeprecated = featureComputer.hasDeprecatedFeature(field);
      var startsWithDollar =
          featureComputer.startsWithDollarFeature(field.name);
      var superMatches = featureComputer.superMatchesFeature(
          _containingMemberName, field.name);
      relevance = _computeMemberRelevance(
          contextType: contextType,
          elementKind: elementKind,
          hasDeprecated: hasDeprecated,
          inheritanceDistance: inheritanceDistance,
          startsWithDollar: startsWithDollar,
          superMatches: superMatches);
    } else {
      relevance = _computeOldMemberRelevance(field);
      if (request.opType.includeReturnValueSuggestions) {
        relevance =
            request.opType.returnValueSuggestionsFilter(field.type, relevance);
      }
      if (relevance == null) {
        return;
      }
    }
    _add(createSuggestion(request, field, relevance: relevance));
  }

  /// Add a suggestion to reference a [field] in a field formal parameter.
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

  /// Add a suggestion for a [functionTypeAlias]. If a [kind] is provided it
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

  /// Add a suggestion for a [keyword]. The [offset] is the offset from the
  /// beginning of the keyword where the cursor will be left.
  void suggestKeyword(String keyword, {int offset, @required int relevance}) {
    // TODO(brianwilkerson) Use the location at which the keyword is being
    //  inserted to compute the relevance.
    _add(CompletionSuggestion(CompletionSuggestionKind.KEYWORD, relevance,
        keyword, offset ?? keyword.length, 0, false, false));
  }

  /// Add a suggestion for a [label].
  void suggestLabel(Label label) {
    var completion = label.label?.name;
    // TODO(brianwilkerson) Figure out why we're excluding labels consisting of
    //  a single underscore.
    if (completion != null && completion.isNotEmpty && completion != '_') {
      var suggestion = CompletionSuggestion(
          CompletionSuggestionKind.IDENTIFIER,
          request.useNewRelevance ? Relevance.label : DART_RELEVANCE_DEFAULT,
          completion,
          completion.length,
          0,
          false,
          false);
      suggestion.element = createLocalElement(
          request.source, protocol.ElementKind.LABEL, label.label,
          returnType: NO_RETURN_TYPE);
      _add(suggestion);
    }
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

  /// Add a suggestion for a local [variable].
  void suggestLocalVariable(LocalVariableElement variable) {
    var variableType = variable.type;
    int relevance;
    if (request.useNewRelevance) {
      // TODO(brianwilkerson) Use the distance to the local variable as
      //  another feature.
      var contextTypeFeature = request.featureComputer
          .contextTypeFeature(_contextType, variableType);
      relevance = toRelevance(contextTypeFeature, 800);
    } else {
      relevance = _computeOldMemberRelevance(variable);
      relevance =
          request.opType.returnValueSuggestionsFilter(variableType, relevance);
      if (relevance == null) {
        return;
      }
    }

    _add(createSuggestion(request, variable, relevance: relevance));
  }

  /// Add a suggestion for a [method]. If the method is being invoked with a
  /// target of `super`, then the [containingMemberName] should be the name of
  /// the member containing the invocation. If a [kind] is provided it will be
  /// used as the kind for the suggestion. The [inheritanceDistance] is the
  /// value of the inheritance distance feature computed for the method.
  void suggestMethod(MethodElement method,
      {CompletionSuggestionKind kind, @required double inheritanceDistance}) {
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
          _containingMemberName, method.name);
      relevance = _computeMemberRelevance(
          contextType: contextType,
          elementKind: elementKind,
          hasDeprecated: hasDeprecated,
          inheritanceDistance: inheritanceDistance,
          startsWithDollar: startsWithDollar,
          superMatches: superMatches);
    } else {
      relevance = _computeOldMemberRelevance(method);
      if (request.opType.includeReturnValueSuggestions) {
        relevance = request.opType
            .returnValueSuggestionsFilter(method.returnType, relevance);
      }
      if (relevance == null) {
        return;
      }
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

  /// Add a suggestion to use the [name] at a declaration site.
  void suggestName(String name) {
    // TODO(brianwilkerson) Explore whether there are any features of the name
    //  that can be used to provide better relevance scores.
    _add(CompletionSuggestion(
        CompletionSuggestionKind.IDENTIFIER,
        request.useNewRelevance ? 500 : DART_RELEVANCE_DEFAULT,
        name,
        name.length,
        0,
        false,
        false));
  }

  /// Add a suggestion to replace the [targetId] with an override of the given
  /// [element]. If [invokeSuper] is `true`, then the override will contain an
  /// invocation of an overridden member.
  Future<void> suggestOverride(SimpleIdentifier targetId,
      ExecutableElement element, bool invokeSuper) async {
    var displayTextBuffer = StringBuffer();
    var builder = DartChangeBuilder(request.result.session);
    await builder.addFileEdit(request.result.path, (builder) {
      builder.addReplacement(range.node(targetId), (builder) {
        builder.writeOverride(
          element,
          displayTextBuffer: displayTextBuffer,
          invokeSuper: invokeSuper,
        );
      });
    });

    var fileEdits = builder.sourceChange.edits;
    if (fileEdits.length != 1) {
      return;
    }

    var sourceEdits = fileEdits[0].edits;
    if (sourceEdits.length != 1) {
      return;
    }

    var replacement = sourceEdits[0].replacement;
    var completion = replacement.trim();
    var overrideAnnotation = '@override';
    if (_hasOverride(request.target.containingNode) &&
        completion.startsWith(overrideAnnotation)) {
      completion = completion.substring(overrideAnnotation.length).trim();
    }
    if (completion.isEmpty) {
      return;
    }

    var selectionRange = builder.selectionRange;
    if (selectionRange == null) {
      return;
    }
    var offsetDelta = targetId.offset + replacement.indexOf(completion);
    var displayText =
        displayTextBuffer.isNotEmpty ? displayTextBuffer.toString() : null;
    var suggestion = CompletionSuggestion(
        CompletionSuggestionKind.OVERRIDE,
        request.useNewRelevance ? Relevance.override : DART_RELEVANCE_HIGH,
        completion,
        selectionRange.offset - offsetDelta,
        selectionRange.length,
        element.hasDeprecated,
        false,
        displayText: displayText);
    suggestion.element = protocol.convertElement(element);
    _add(suggestion);
  }

  /// Add a suggestion for a [parameter].
  void suggestParameter(ParameterElement parameter) {
    var variableType = parameter.type;
    int relevance;
    if (request.useNewRelevance) {
      // TODO(brianwilkerson) Use the distance to the declaring function as
      //  another feature.
      var contextTypeFeature = request.featureComputer
          .contextTypeFeature(_contextType, variableType);
      relevance = toRelevance(contextTypeFeature, 800);
    } else {
      relevance = _computeOldMemberRelevance(parameter);
      relevance =
          request.opType.returnValueSuggestionsFilter(variableType, relevance);
      if (relevance == null) {
        return;
      }
    }

    _add(createSuggestion(request, parameter, relevance: relevance));
  }

  /// Add a suggestiuon for a [prefix] associated with a [library].
  void suggestPrefix(LibraryElement library, String prefix) {
    var relevance;
    if (request.useNewRelevance) {
      relevance = Relevance.prefix;
    } else {
      relevance =
          library.hasDeprecated ? DART_RELEVANCE_LOW : DART_RELEVANCE_DEFAULT;
    }
    _add(createSuggestion(request, library,
        completion: prefix,
        kind: CompletionSuggestionKind.IDENTIFIER,
        relevance: relevance));
  }

  /// Add a suggestion for a top-level [function]. If a [kind] is provided it
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
      relevance =
          request.opType.returnValueSuggestionsFilter(function.type, relevance);
      if (relevance == null) {
        return;
      }
    }

    _add(createSuggestion(request, function, kind: kind, relevance: relevance));
  }

  /// Add a suggestion for a top-level property [accessor]. If a [kind] is
  /// provided it will be used as the kind for the suggestion.
  void suggestTopLevelPropertyAccessor(PropertyAccessorElement accessor,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    assert(accessor.enclosingElement is CompilationUnitElement);
    if (accessor.isSynthetic) {
      // Avoid visiting a field twice. All fields induce a getter, but only
      // non-final fields induce a setter, so we don't add a suggestion for a
      // synthetic setter.
      if (accessor.isGetter) {
        var variable = accessor.variable;
        if (variable is TopLevelVariableElement) {
          suggestTopLevelVariable(variable, kind: kind);
        }
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
        relevance = _computeMemberRelevance(
            contextType: contextType,
            elementKind: elementKind,
            hasDeprecated: hasDeprecated,
            inheritanceDistance: -1.0,
            startsWithDollar: startsWithDollar,
            superMatches: -1.0);
      } else {
        relevance = _computeOldMemberRelevance(accessor);
        if (request.opType.includeReturnValueSuggestions) {
          relevance =
              request.opType.returnValueSuggestionsFilter(type, relevance);
        }
        if (relevance == null) {
          return;
        }
      }
      _add(createSuggestion(request, accessor, relevance: relevance));
    }
  }

  /// Add a suggestion for a top-level [variable]. If a [kind] is provided it
  /// will be used as the kind for the suggestion.
  void suggestTopLevelVariable(TopLevelVariableElement variable,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    assert(variable.enclosingElement is CompilationUnitElement);
    int relevance;
    if (request.useNewRelevance) {
      relevance =
          _computeTopLevelRelevance(variable, elementType: variable.type);
    } else if (variable.hasOrInheritsDeprecated) {
      relevance = DART_RELEVANCE_LOW;
    } else {
      var type = variable.type;
      relevance = _computeOldMemberRelevance(variable);
      relevance = request.opType.returnValueSuggestionsFilter(type, relevance);
      if (relevance == null) {
        return;
      }
    }

    _add(createSuggestion(request, variable, kind: kind, relevance: relevance));
  }

  /// Add a suggestion for a type [parameter].
  void suggestTypeParameter(TypeParameterElement parameter) {
    int relevance;
    if (request.useNewRelevance) {
      relevance = Relevance.typeParameter;
    } else {
      relevance = _computeOldMemberRelevance(parameter);
    }

    _add(createSuggestion(request, parameter,
        kind: CompletionSuggestionKind.IDENTIFIER, relevance: relevance));
  }

  /// Add a suggestion to use the [uri] in an import, export, or part directive.
  void suggestUri(String uri) {
    int relevance;
    if (request.useNewRelevance) {
      relevance =
          uri == 'dart:core' ? Relevance.importDartCore : Relevance.import;
    } else {
      relevance =
          uri == 'dart:core' ? DART_RELEVANCE_LOW : DART_RELEVANCE_DEFAULT;
    }
    _add(CompletionSuggestion(CompletionSuggestionKind.IMPORT, relevance, uri,
        uri.length, 0, false, false));
  }

  /// Add the given [suggestion] if it isn't `null` and if it isn't shadowed by
  /// a previously added suggestion.
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
  int _computeOldMemberRelevance(Element member) {
    if (member.hasOrInheritsDeprecated) {
      return DART_RELEVANCE_LOW;
    } else if (member.name == _containingMemberName) {
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
    if (member is LocalVariableElement) {
      return DART_RELEVANCE_LOCAL_VARIABLE;
    }
    if (!member.name.startsWith('_') &&
        member.library == request.libraryElement) {
      // Locally declared elements sometimes have a special relevance.
      if (member is PropertyAccessorElement) {
        return DART_RELEVANCE_LOCAL_ACCESSOR;
      } else if (member is FieldElement) {
        return DART_RELEVANCE_LOCAL_FIELD;
      } else if (member is FunctionElement) {
        return DART_RELEVANCE_LOCAL_FUNCTION;
      } else if (member is MethodElement) {
        return DART_RELEVANCE_LOCAL_METHOD;
      } else if (member is ParameterElement) {
        return DART_RELEVANCE_PARAMETER;
      } else if (member is TopLevelVariableElement) {
        return DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE;
      } else if (member is TypeParameterElement) {
        return DART_RELEVANCE_TYPE_PARAMETER;
      }
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

  /// Return `true` if the given [node] has an `override` annotation.
  bool _hasOverride(AstNode node) {
    if (node is AnnotatedNode) {
      var metadata = node.metadata;
      for (var annotation in metadata) {
        if (annotation.name.name == 'override' &&
            annotation.arguments == null) {
          return true;
        }
      }
    }
    return false;
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
