// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/completion/relevance.dart';

import 'feature_computer.dart';

/// Computes the relevance scores for completion suggestions.
class RelevanceComputer {
  /// The completion request for which suggestions are being built.
  final DartCompletionRequest request;

  /// The listener to be notified at certain points in the process of building
  /// suggestions, or `null` if no notification should occur.
  final SuggestionListener? listener;

  /// The object used to compute the values of the features used to
  /// compute relevance scores for suggestions.
  final FeatureComputer featureComputer;

  /// Return `true` if the context requires a constant expression.
  bool preferConstants = false;

  /// A flag indicating whether the [_cachedContainingMemberName] has been
  /// computed.
  bool _hasContainingMemberName = false;

  /// The name of the member containing the completion location, or `null` if
  /// either the completion location isn't within a member, the target of the
  /// completion isn't `super`, or the name of the member hasn't yet been
  /// computed. In the latter case, [_hasContainingMemberName] will be `false`.
  String? _cachedContainingMemberName;

  /// The already typed string at the completion location, maybe empty.
  /// See [DartCompletionRequest.targetPrefix].
  /// It is used to inflate the relevance of perfect matches to `1.0`.
  final String targetPrefix;
  late final String targetPrefixLower = targetPrefix.toLowerCase();

  /// A textual representation of the location at which completion was
  /// requested.
  String? completionLocation;

  RelevanceComputer(this.request, this.listener, {required this.targetPrefix})
    : featureComputer = request.featureComputer;

  /// Return the name of the member containing the completion location, or
  /// `null` if the completion location isn't within a member or if the target
  /// of the completion isn't `super`.
  String? get _containingMemberName {
    if (!_hasContainingMemberName) {
      _hasContainingMemberName = true;
      if (request.target.dotTarget is SuperExpression) {
        var containingMethod = request.target.containingNode
            .thisOrAncestorOfType<MethodDeclaration>();
        if (containingMethod != null) {
          _cachedContainingMemberName = containingMethod.name.lexeme;
        }
      }
    }
    return _cachedContainingMemberName;
  }

  /// Compute the relevance for [FieldElement] suggestion.
  int computeFieldElementRelevance(
    FieldElement element,
    double inheritanceDistance,
  ) {
    var contextType = featureComputer.contextTypeFeature(
      request.contextType,
      element.type,
    );
    var elementKind = _computeElementKind(
      element,
      distance: inheritanceDistance,
    );
    var hasDeprecated = featureComputer.hasDeprecatedFeature(element);
    var isConstant = preferConstants
        ? featureComputer.isConstantFeature(element)
        : 0.0;
    var startsWithDollar = featureComputer.startsWithDollarFeature(
      element.displayName,
    );
    var superMatches = featureComputer.superMatchesFeature(
      _containingMemberName,
      element.displayName,
    );
    return computeScore(
      contextType: contextType,
      elementKind: elementKind,
      hasDeprecated: hasDeprecated,
      isConstant: isConstant,
      startsWithDollar: startsWithDollar,
      superMatches: superMatches,
      inheritanceDistance: inheritanceDistance,
    );
  }

  /// Compute the relevance for the given [CandidateSuggestion].
  int computeRelevance(CandidateSuggestion suggestion) {
    // See https://github.com/dart-lang/sdk/issues/61679
    // We have two checks to distinguish prefix `str` or `STR` when
    // candidates are also `str` or `STR`. We want to prefer the same case.
    if (_isExactPrefixMatch(suggestion)) {
      return maximumRelevance;
    }
    if (_isExactPrefixMatchToLower(suggestion)) {
      return maximumRelevance - 1;
    }

    var neverType = request.libraryElement.typeProvider.neverType;
    switch (suggestion) {
      case TypedSuggestionCompletionMixin():
        return switch (suggestion) {
          MethodSuggestion() => _computeMethodRelevance(
            suggestion.element,
            suggestion.inheritanceDistance(featureComputer),
            suggestion.isNotImported,
          ),
          GetterSuggestion() => _computePropertyAccessorRelevance(
            suggestion.element,
            suggestion.inheritanceDistance(featureComputer),
            suggestion.isNotImported,
          ),
          SetStateMethodSuggestion() => _computeMethodRelevance(
            suggestion.element,
            suggestion.inheritanceDistance(featureComputer),
            suggestion.isNotImported,
          ),
          // This is a placeholder that can be overridden above with the exact
          // type. Only needed because mixins can't be `sealed`.
          TypedSuggestionCompletionMixin() => computeScore(
            contextType: featureComputer.contextTypeFeature(
              request.contextType,
              suggestion.type,
            ),
          ),
        };
      case RecordFieldSuggestion():
        return computeScore(
          contextType: featureComputer.contextTypeFeature(
            request.contextType,
            suggestion.field.type,
          ),
        );
      case ClassSuggestion():
        return computeTopLevelRelevance2(
          suggestion.element,
          elementType: instantiateInstanceElement(
            suggestion.element,
            neverType,
          ),
          isNotImportedLibrary: suggestion.isNotImported,
        );
      case ClosureSuggestion():
        return Relevance.closure;
      case ConstructorSuggestion():
        return _computeConstructorRelevance(
          suggestion.element,
          neverType,
          suggestion.isNotImported,
        );
      case EnumConstantSuggestion():
        return _computeEnumConstRelevance(
          suggestion,
          suggestion.isNotImported,
          0.0,
        );
      case EnumSuggestion():
        return computeTopLevelRelevance(
          suggestion.element,
          elementType: instantiateInstanceElement(
            suggestion.element,
            neverType,
          ),
          isNotImportedLibrary: suggestion.isNotImported,
        );
      case ExtensionSuggestion():
        return computeTopLevelRelevance(
          suggestion.element,
          elementType: suggestion.element.extendedType,
          isNotImportedLibrary: suggestion.isNotImported,
        );
      case ExtensionTypeSuggestion():
        return computeTopLevelRelevance(
          suggestion.element,
          elementType: instantiateInstanceElement(
            suggestion.element,
            neverType,
          ),
          isNotImportedLibrary: suggestion.isNotImported,
        );
      case FieldSuggestion():
        var fieldElement = suggestion.element;
        if (fieldElement.isEnumConstant) {
          // TODO(brianwilkerson): We are assuming that the enum constant is
          //  imported because it appears to be the case that we never create a
          //  `FieldSuggestion` on an enum constant except when adding members
          //  of the enclosing declaration. We should enforce this assumption.
          return computeTopLevelRelevance(
            fieldElement,
            elementType: fieldElement.type,
            isNotImportedLibrary: false,
          );
        } else {
          return computeFieldElementRelevance(
            fieldElement,
            suggestion.inheritanceDistance(featureComputer),
          );
        }
      case FormalParameterSuggestion():
        return _computeFormalParameterRelevance(suggestion);
      case FunctionCall():
        return Relevance.callFunction;
      case IdentifierSuggestion():
        return 500;
      case ImportPrefixSuggestion():
        return computeScore(
          elementKind: _computeElementKind(suggestion.libraryElement),
        );
      case KeywordSuggestion():
        return _computeKeywordRelevance(suggestion);
      case LabelSuggestion():
        return Relevance.label;
      case LoadLibraryFunctionSuggestion():
        return Relevance.loadLibrary;
      case LocalFunctionSuggestion():
        return computeTopLevelRelevance(
          suggestion.element,
          elementType: suggestion.element.returnType,
          isNotImportedLibrary: suggestion.isNotImported,
        );
      case LocalVariableSuggestion():
        return _computeLocalVariableRelevance(suggestion);
      case MixinSuggestion():
        return computeTopLevelRelevance(
          suggestion.element,
          elementType: instantiateInstanceElement(
            suggestion.element,
            neverType,
          ),
          isNotImportedLibrary: suggestion.isNotImported,
        );
      case NamedArgumentSuggestion():
        var parameter = suggestion.parameter;
        if (parameter.isRequiredNamed || parameter.metadata.hasRequired) {
          return Relevance.requiredNamedArgument;
        } else {
          return Relevance.namedArgument;
        }
      case NameSuggestion():
        return 500;
      case OverrideSuggestion():
        return Relevance.override;
      case SetterSuggestion():
        return _computePropertyAccessorRelevance(
          suggestion.element,
          suggestion.inheritanceDistance(featureComputer),
          suggestion.isNotImported,
        );
      case RecordLiteralNamedFieldSuggestion():
        return Relevance.requiredNamedArgument;
      case StaticFieldSuggestion():
        return _computeStaticFieldRelevance(
          suggestion.element,
          0.0,
          suggestion.isNotImported,
        );
      case SuperParameterSuggestion():
        return Relevance.superFormalParameter;
      case TopLevelFunctionSuggestion():
        var function = suggestion.element;
        return computeTopLevelRelevance(
          function,
          elementType: function.returnType,
          isNotImportedLibrary: suggestion.isNotImported,
        );
      case TopLevelGetterSuggestion():
        return _computeTopLevelPropertyAccessorRelevance(
          suggestion.element,
          suggestion.isNotImported,
        );
      case TopLevelSetterSuggestion():
        return _computeTopLevelPropertyAccessorRelevance(
          suggestion.element,
          suggestion.isNotImported,
        );
      case TopLevelVariableSuggestion():
        var variable = suggestion.element;
        return computeTopLevelRelevance(
          variable,
          elementType: variable.type,
          isNotImportedLibrary: suggestion.isNotImported,
        );
      case TypeAliasSuggestion():
        var typeAlias = suggestion.element;
        return computeTopLevelRelevance(
          typeAlias,
          elementType: _instantiateTypeAlias(typeAlias),
          isNotImportedLibrary: suggestion.isNotImported,
        );
      case TypeParameterSuggestion():
        return _computeTypeParameterRelevance(suggestion.element);
      case UriSuggestion():
        return suggestion.uriStr == 'dart:core'
            ? Relevance.importDartCore
            : Relevance.import;
    }
  }

  /// Compute the relevance based on the given feature values and pass those
  /// feature values to the listener if there is one.
  int computeScore({
    double contextType = 0.0,
    double elementKind = 0.0,
    double hasDeprecated = 0.0,
    double isConstant = 0.0,
    double isNoSuchMethod = 0.0,
    double isNotImported = 0.0,
    double keyword = 0.0,
    double startsWithDollar = 0.0,
    double superMatches = 0.0,
    // Dependent features
    double inheritanceDistance = 0.0,
    double localVariableDistance = 0.0,
  }) {
    var score = weightedAverage(
      contextType: contextType,
      elementKind: elementKind,
      hasDeprecated: hasDeprecated,
      isConstant: isConstant,
      isNoSuchMethod: isNoSuchMethod,
      isNotImported: isNotImported,
      keyword: keyword,
      startsWithDollar: startsWithDollar,
      superMatches: superMatches,
      localVariableDistance: localVariableDistance,
    );
    var relevance = toRelevance(score);
    listener?.computedFeatures(
      contextType: contextType,
      elementKind: elementKind,
      hasDeprecated: hasDeprecated,
      isConstant: isConstant,
      isNoSuchMethod: isNoSuchMethod,
      isNotImported: isNotImported,
      keyword: keyword,
      startsWithDollar: startsWithDollar,
      superMatches: superMatches,
      // Dependent features
      inheritanceDistance: inheritanceDistance,
      localVariableDistance: localVariableDistance,
    );
    return relevance;
  }

  /// Return the relevance score for a top-level [element].
  int computeTopLevelRelevance(
    Element element, {
    required DartType elementType,
    required bool isNotImportedLibrary,
  }) {
    // TODO(brianwilkerson): The old relevance computation used a signal based
    //  on whether the element being suggested was from the same library in
    //  which completion is being performed. Explore whether that's a useful
    //  signal.
    var contextType = featureComputer.contextTypeFeature(
      request.contextType,
      elementType,
    );
    var elementKind = _computeElementKind(element);
    var hasDeprecated = featureComputer.hasDeprecatedFeature(element);
    var isConstant = preferConstants
        ? featureComputer.isConstantFeature(element)
        : 0.0;
    return computeScore(
      contextType: contextType,
      elementKind: elementKind,
      hasDeprecated: hasDeprecated,
      isConstant: isConstant,
      isNotImported: featureComputer.isNotImportedFeature(isNotImportedLibrary),
    );
  }

  /// Return the relevance score for a top-level [element].
  int computeTopLevelRelevance2(
    Element element, {
    required DartType elementType,
    required bool isNotImportedLibrary,
  }) {
    // TODO(brianwilkerson): The old relevance computation used a signal based
    //  on whether the element being suggested was from the same library in
    //  which completion is being performed. Explore whether that's a useful
    //  signal.
    var contextType = featureComputer.contextTypeFeature(
      request.contextType,
      elementType,
    );
    var elementKind = _computeElementKind2(element);
    var hasDeprecated = featureComputer.hasDeprecatedFeature(element);
    var isConstant = preferConstants
        ? featureComputer.isConstantFeature(element)
        : 0.0;
    return computeScore(
      contextType: contextType,
      elementKind: elementKind,
      hasDeprecated: hasDeprecated,
      isConstant: isConstant,
      isNotImported: featureComputer.isNotImportedFeature(isNotImportedLibrary),
    );
  }

  /// Compute the relevance for an [accessor].
  int _computeAccessorRelevance(
    DartType? type,
    Element accessor,
    bool isNotImportedLibrary, {
    double startsWithDollar = 0.0,
    double superMatches = 0.0,
    double? distance,
  }) {
    var contextType = featureComputer.contextTypeFeature(
      request.contextType,
      type,
    );
    var elementKind = _computeElementKind(accessor, distance: distance);
    var hasDeprecated = featureComputer.hasDeprecatedFeature(accessor);
    var isConstant = preferConstants
        ? featureComputer.isConstantFeature(accessor)
        : 0.0;
    return computeScore(
      contextType: contextType,
      elementKind: elementKind,
      hasDeprecated: hasDeprecated,
      isConstant: isConstant,
      isNotImported: featureComputer.isNotImportedFeature(isNotImportedLibrary),
      startsWithDollar: startsWithDollar,
      superMatches: superMatches,
    );
  }

  /// Compute the relevance for [ConstructorElement].
  int _computeConstructorRelevance(
    ConstructorElement element,
    NeverType neverType,
    bool isNotImportedLibrary,
  ) {
    var enclosingClass = element.enclosingElement;
    var returnType = instantiateInstanceElement(enclosingClass, neverType);
    return computeTopLevelRelevance(
      element,
      elementType: returnType,
      isNotImportedLibrary: isNotImportedLibrary,
    );
  }

  /// Compute the value of the _element kind_ feature for the given [element] in
  /// the completion context.
  double _computeElementKind(Element element, {double? distance}) {
    var location = completionLocation;
    var elementKind = featureComputer.elementKindFeature(
      element,
      location,
      distance: distance,
    );
    if (elementKind < 0.0) {
      if (location == null) {
        listener?.missingCompletionLocationAt(
          request.target.containingNode,
          request.target.entity!,
        );
      } else {
        listener?.missingElementKindTableFor(location);
      }
    }
    return elementKind;
  }

  /// Compute the value of the _element kind_ feature for the given [element] in
  /// the completion context.
  double _computeElementKind2(Element element, {double? distance}) {
    var location = completionLocation;
    var elementKind = featureComputer.elementKindFeature(
      element,
      location,
      distance: distance,
    );
    if (elementKind < 0.0) {
      if (location == null) {
        listener?.missingCompletionLocationAt(
          request.target.containingNode,
          request.target.entity!,
        );
      } else {
        listener?.missingElementKindTableFor(location);
      }
    }
    return elementKind;
  }

  /// Compute the relevance for [EnumConstantSuggestion].
  int _computeEnumConstRelevance(
    EnumConstantSuggestion suggestion,
    bool isNotImportedLibrary,
    double inheritanceDistance,
  ) {
    var element = suggestion.element;
    if (suggestion.includeEnumName) {
      return computeTopLevelRelevance(
        element,
        elementType: element.type,
        isNotImportedLibrary: isNotImportedLibrary,
      );
    } else {
      return computeFieldElementRelevance(element, inheritanceDistance);
    }
  }

  /// Compute the relevance for [FormalParameterSuggestion].
  int _computeFormalParameterRelevance(FormalParameterSuggestion suggestion) {
    var element = suggestion.element;
    var variableType = element.type;
    var contextType = request.featureComputer.contextTypeFeature(
      request.contextType,
      variableType,
    );
    var localVariableDistance = featureComputer.distanceToPercent(
      suggestion.distance,
    );
    var elementKind = _computeElementKind(element);
    var isConstant = preferConstants
        ? featureComputer.isConstantFeature(element)
        : 0.0;
    return computeScore(
      contextType: contextType,
      elementKind: elementKind,
      isConstant: isConstant,
      localVariableDistance: localVariableDistance,
    );
  }

  /// Compute the relevance for [KeywordSuggestion].
  int _computeKeywordRelevance(KeywordSuggestion suggestion) {
    DartType? elementType;
    var keyword = suggestion.completion;
    if (keyword == 'null') {
      elementType = featureComputer.typeProvider.nullType;
    } else if (keyword == 'false' || keyword == 'true') {
      elementType = featureComputer.typeProvider.boolType;
    }
    var contextType = featureComputer.contextTypeFeature(
      request.contextType,
      elementType,
    );
    var keywordFeature = featureComputer.keywordFeature(
      keyword,
      completionLocation,
    );
    return computeScore(contextType: contextType, keyword: keywordFeature);
  }

  /// Compute the relevance for [LocalVariableSuggestion].
  int _computeLocalVariableRelevance(LocalVariableSuggestion suggestion) {
    var element = suggestion.element;
    var variableType = element.type;
    var contextType = request.featureComputer.contextTypeFeature(
      request.contextType,
      variableType,
    );
    var localVariableDistance = featureComputer.distanceToPercent(
      suggestion.distance,
    );
    var elementKind = _computeElementKind(
      element,
      distance: localVariableDistance,
    );
    var isConstant = preferConstants
        ? featureComputer.isConstantFeature(element)
        : 0.0;
    return computeScore(
      contextType: contextType,
      elementKind: elementKind,
      isConstant: isConstant,
      localVariableDistance: localVariableDistance,
    );
  }

  /// Compute the relevance for [MethodElement].
  int _computeMethodRelevance(
    MethodElement method,
    double inheritanceDistance,
    bool isNotImportedLibrary,
  ) {
    var contextType = featureComputer.contextTypeFeature(
      request.contextType,
      method.returnType,
    );
    var elementKind = _computeElementKind(
      method,
      distance: inheritanceDistance,
    );
    var hasDeprecated = featureComputer.hasDeprecatedFeature(method);
    var isConstant = preferConstants
        ? featureComputer.isConstantFeature(method)
        : 0.0;
    var isNoSuchMethod = featureComputer.isNoSuchMethodFeature(
      _containingMemberName,
      method.displayName,
    );
    var startsWithDollar = featureComputer.startsWithDollarFeature(
      method.displayName,
    );
    var superMatches = featureComputer.superMatchesFeature(
      _containingMemberName,
      method.displayName,
    );
    return computeScore(
      contextType: contextType,
      elementKind: elementKind,
      hasDeprecated: hasDeprecated,
      isConstant: isConstant,
      isNoSuchMethod: isNoSuchMethod,
      isNotImported: featureComputer.isNotImportedFeature(isNotImportedLibrary),
      startsWithDollar: startsWithDollar,
      superMatches: superMatches,
      inheritanceDistance: inheritanceDistance,
    );
  }

  /// Compute the relevance for [PropertyAccessorElement].
  int _computePropertyAccessorRelevance(
    PropertyAccessorElement accessor,
    double inheritanceDistance,
    bool isNotImportedLibrary,
  ) {
    if (accessor.isSynthetic) {
      if (accessor is GetterElement) {
        var variable = accessor.variable;
        if (variable is FieldElement) {
          return computeFieldElementRelevance(variable, inheritanceDistance);
        }
      }
    } else {
      var type = _getPropertyAccessorType(accessor);
      var superMatches = featureComputer.superMatchesFeature(
        _containingMemberName,
        accessor.displayName,
      );
      var startsWithDollar = featureComputer.startsWithDollarFeature(
        accessor.displayName,
      );
      return _computeAccessorRelevance(
        type,
        accessor,
        isNotImportedLibrary,
        distance: inheritanceDistance,
        superMatches: superMatches,
        startsWithDollar: startsWithDollar,
      );
    }
    return 0;
  }

  /// Compute the relevance for a static [FieldElement].
  int _computeStaticFieldRelevance(
    FieldElement element,
    double inheritanceDistance,
    bool isNotImportedLibrary,
  ) {
    if (element.isSynthetic) {
      var getter = element.getter;
      if (getter != null) {
        var variable = getter.variable;
        if (variable is FieldElement) {
          return computeFieldElementRelevance(variable, inheritanceDistance);
        }
      }
    } else {
      return computeTopLevelRelevance(
        element,
        elementType: element.type,
        isNotImportedLibrary: isNotImportedLibrary,
      );
    }
    return 0;
  }

  /// Compute the relevance for top level [PropertyAccessorElement].
  int _computeTopLevelPropertyAccessorRelevance(
    PropertyAccessorElement accessor,
    bool isNotImportedLibrary,
  ) {
    if (accessor.isSynthetic) {
      if (accessor is GetterElement) {
        var variable = accessor.variable;
        if (variable is TopLevelVariableElement) {
          return computeTopLevelRelevance(
            variable,
            elementType: variable.type,
            isNotImportedLibrary: isNotImportedLibrary,
          );
        }
      }
    } else {
      var type = _getPropertyAccessorType(accessor);
      var startsWithDollar = featureComputer.startsWithDollarFeature(
        accessor.displayName,
      );
      return _computeAccessorRelevance(
        type,
        accessor,
        isNotImportedLibrary,
        startsWithDollar: startsWithDollar,
      );
    }
    return 0;
  }

  /// Compute the relevance for [TypeParameterElement].
  int _computeTypeParameterRelevance(TypeParameterElement parameter) {
    var elementKind = _computeElementKind(parameter);
    var isConstant = preferConstants
        ? featureComputer.isConstantFeature(parameter)
        : 0.0;
    return computeScore(elementKind: elementKind, isConstant: isConstant);
  }

  /// Return the type associated with the [accessor], maybe `null` if an
  /// invalid setter with no parameters at all.
  DartType? _getPropertyAccessorType(PropertyAccessorElement accessor) {
    if (accessor is GetterElement) {
      return accessor.returnType;
    } else {
      var parameters = accessor.formalParameters;
      if (parameters.isEmpty) {
        return null;
      } else {
        return parameters[0].type;
      }
    }
  }

  /// Return the [DartType] for an instantiated [TypeAlias].
  DartType _instantiateTypeAlias(TypeAliasElement element) {
    var typeParameters = element.typeParameters;
    var typeArguments = const <DartType>[];
    if (typeParameters.isNotEmpty) {
      var neverType = request.libraryElement.typeProvider.neverType;
      typeArguments = List.filled(typeParameters.length, neverType);
    }
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  bool _isExactPrefixMatch(CandidateSuggestion suggestion) {
    return targetPrefixLower.isNotEmpty &&
        suggestion.completion == targetPrefix;
  }

  bool _isExactPrefixMatchToLower(CandidateSuggestion suggestion) {
    return targetPrefixLower.isNotEmpty &&
        suggestion.completion.toLowerCase() == targetPrefixLower;
  }
}
