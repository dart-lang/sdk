// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/base/syntactic_entity.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/dart_completion_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A container with enough information to do filtering, and if necessary
/// build the [CompletionSuggestion] instance.
abstract class CompletionSuggestionBuilder {
  /// See [CompletionSuggestion.completion].
  String get completion;

  /// The key used to de-duplicate suggestions.
  String get key => completion;

  /// See [CompletionSuggestion.kind].
  CompletionSuggestionKind get kind;

  /// See [CompletionSuggestion.relevance].
  int get relevance;

  /// Return the text that should be matched against the filter.
  String get textToMatch;

  CompletionSuggestion build();
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
      {required PropertyAccessorElement accessor,
      required double inheritanceDistance}) {
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
      {required MethodElement method,
      required CompletionSuggestionKind kind,
      required double inheritanceDistance}) {
    if (method.isAccessibleIn(request.libraryElement) &&
        _shouldAddSuggestion(method) &&
        request.opType.patternLocation == null) {
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
        _completionTypesGenerated[identifier] =
            _completionTypesGenerated[identifier]! | _COMPLETION_TYPE_GETTER;
      } else {
        // Setters, fields, and methods shadow a setter.
        if ((alreadyGenerated & _COMPLETION_TYPE_SETTER) != 0) {
          return false;
        } else if (element.hasDeprecated &&
            !(element.correspondingGetter?.hasDeprecated ?? true)) {
          // A deprecated setter should not take priority over a non-deprecated
          // getter.
          return false;
        }
        _completionTypesGenerated[identifier] =
            _completionTypesGenerated[identifier]! | _COMPLETION_TYPE_SETTER;
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

  /// The listener to be notified at certain points in the process of building
  /// suggestions, or `null` if no notification should occur.
  final SuggestionListener? listener;

  /// A map from a completion identifier to a completion suggestion.
  final Map<String, CompletionSuggestionBuilder> _suggestionMap = {};

  /// The URI of the library from which suggestions are being added.
  /// This URI is not necessary the same as the URI that declares an element,
  /// because of exports.
  String? libraryUriStr;

  /// URIs that should be imported (that are not already) for all types in the
  /// completion.
  ///
  /// Includes a [URI] for [libraryUriStr] only if the items being suggested are
  /// not already imported.
  Set<Uri> requiredImports = {};

  /// This flag is set to `true` while adding suggestions for top-level
  /// elements from not-yet-imported libraries.
  bool isNotImportedLibrary = false;

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
  String? _cachedContainingMemberName;

  /// If added builders can be filtered based on the `targetPrefix`.
  final bool useFilter;

  /// The lower case `targetPrefix` possibly used to filter results before
  /// actually adding them.
  late final String targetPrefixLower;

  /// Initialize a newly created suggestion builder to build suggestions for the
  /// given [request].
  SuggestionBuilder(this.request, {this.listener, required this.useFilter}) {
    targetPrefixLower = request.targetPrefix.toLowerCase();
  }

  /// Return an object that can answer questions about Flutter code.
  Flutter get flutter => Flutter.instance;

  /// Return an iterable that can be used to access the completion suggestions
  /// that have been built.
  Iterable<CompletionSuggestionBuilder> get suggestions =>
      _suggestionMap.values;

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

  bool get _isNonNullableByDefault =>
      request.libraryElement.isNonNullableByDefault;

  /// Return `true` if the context requires a constant expression.
  bool get _preferConstants =>
      request.inConstantContext || request.opType.mustBeConst;

  /// Add a suggestion for an [accessor] declared within a class or extension.
  /// If the accessor is being invoked with a target of `super`, then the
  /// [containingMemberName] should be the name of the member containing the
  /// invocation. The [inheritanceDistance] is the value of the inheritance
  /// distance feature computed for the accessor or `-1.0` if the accessor is a
  /// static accessor.
  void suggestAccessor(
    PropertyAccessorElement accessor, {
    required double inheritanceDistance,
    bool withEnclosingName = false,
  }) {
    var enclosingPrefix = '';
    var enclosingName = _enclosingClassOrExtensionName(accessor);
    if (withEnclosingName && enclosingName != null) {
      enclosingPrefix = '$enclosingName.';
    }

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
      var completion = enclosingPrefix + accessor.displayName;
      if (_couldMatch(completion, null)) {
        var type = _getPropertyAccessorType(accessor);
        var featureComputer = request.featureComputer;
        var contextType =
            featureComputer.contextTypeFeature(request.contextType, type);
        var elementKind =
            _computeElementKind(accessor, distance: inheritanceDistance);
        var hasDeprecated = featureComputer.hasDeprecatedFeature(accessor);
        var isConstant = _preferConstants
            ? featureComputer.isConstantFeature(accessor)
            : 0.0;
        var startsWithDollar =
            featureComputer.startsWithDollarFeature(accessor.name);
        var superMatches = featureComputer.superMatchesFeature(
            _containingMemberName, accessor.name);
        var relevance = _computeRelevance(
          contextType: contextType,
          elementKind: elementKind,
          hasDeprecated: hasDeprecated,
          isConstant: isConstant,
          isNotImported: request.featureComputer
              .isNotImportedFeature(isNotImportedLibrary),
          startsWithDollar: startsWithDollar,
          superMatches: superMatches,
          inheritanceDistance: inheritanceDistance,
        );
        _addBuilder(
          _createCompletionSuggestionBuilder(
            accessor,
            completion: completion,
            kind: CompletionSuggestionKind.IDENTIFIER,
            relevance: relevance,
            isNotImported: isNotImportedLibrary,
          ),
        );
      }
    }
  }

  /// Add a suggestion for a catch [parameter].
  void suggestCatchParameter(LocalVariableElement parameter) {
    var variableType = parameter.type;
    var contextType = request.featureComputer
        .contextTypeFeature(request.contextType, variableType);
    var elementKind = _computeElementKind(parameter);
    var isConstant = _preferConstants
        ? request.featureComputer.isConstantFeature(parameter)
        : 0.0;
    var relevance = _computeRelevance(
      contextType: contextType,
      elementKind: elementKind,
      isConstant: isConstant,
    );
    _addBuilder(
      _createCompletionSuggestionBuilder(
        parameter,
        kind: CompletionSuggestionKind.IDENTIFIER,
        relevance: relevance,
        isNotImported: isNotImportedLibrary,
      ),
    );
  }

  /// Add a suggestion to insert a closure matching the given function [type].
  /// If [includeTrailingComma] is `true` then the completion text will include
  /// a trailing comma, such as when the closure is part of an argument list.
  void suggestClosure(FunctionType type, {bool includeTrailingComma = false}) {
    var indent = getRequestLineIndent(request);
    var parametersString = buildClosureParameters(type);

    var blockBuffer = StringBuffer(parametersString);
    blockBuffer.writeln(' {');
    blockBuffer.write('$indent  ');
    var blockSelectionOffset = blockBuffer.length;
    blockBuffer.writeln();
    blockBuffer.write('$indent}');

    var expressionBuffer = StringBuffer(parametersString);
    expressionBuffer.write(' => ');
    var expressionSelectionOffset = expressionBuffer.length;

    if (includeTrailingComma) {
      blockBuffer.write(',');
      expressionBuffer.write(',');
    }

    CompletionSuggestion createSuggestion({
      required String completion,
      required String displayText,
      required int selectionOffset,
    }) {
      return DartCompletionSuggestion(
        CompletionSuggestionKind.INVOCATION,
        Relevance.closure,
        completion,
        selectionOffset,
        0,
        false,
        false,
        displayText: displayText,
        elementLocation: null, // type.element is Null for FunctionType.
      );
    }

    _addSuggestion(
      createSuggestion(
        completion: blockBuffer.toString(),
        displayText: '$parametersString {}',
        selectionOffset: blockSelectionOffset,
      ),
    );
    _addSuggestion(
      createSuggestion(
        completion: expressionBuffer.toString(),
        displayText: '$parametersString =>',
        selectionOffset: expressionSelectionOffset,
      ),
    );
  }

  /// Add a suggestion for a [constructor]. If a [kind] is provided it will be
  /// used as the kind for the suggestion. The flag [hasClassName] should be
  /// `true` if the completion is occurring after the name of the class and a
  /// period, and hence should not include the name of the class. If the class
  /// can only be referenced using a prefix, and the class name is to be
  /// included in the completion, then the [prefix] should be provided.
  void suggestConstructor(
    ConstructorElement constructor, {
    CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
    bool tearOff = false,
    bool hasClassName = false,
    String? prefix,
  }) {
    // If the class name is already in the text, then we don't support
    // prepending a prefix.
    assert(!hasClassName || prefix == null);

    var enclosingClass = constructor.enclosingElement.augmented?.declaration;
    if (enclosingClass == null) {
      return;
    }

    var className = enclosingClass.name;
    if (className.isEmpty) {
      return;
    }

    var completion = constructor.name;
    if (tearOff && completion.isEmpty) {
      completion = 'new';
    }

    if (!hasClassName) {
      if (completion.isEmpty) {
        completion = className;
      } else {
        completion = '$className.$completion';
      }
    }
    if (completion.isEmpty) {
      return;
    }

    if (_couldMatch(completion, prefix)) {
      var returnType = _instantiateInstanceElement(enclosingClass);
      var relevance =
          _computeTopLevelRelevance(constructor, elementType: returnType);
      _addBuilder(
        _createCompletionSuggestionBuilder(
          constructor,
          completion: completion,
          kind: kind,
          prefix: prefix,
          relevance: relevance,
          isNotImported: isNotImportedLibrary,
        ),
      );
    }
  }

  /// Add a suggestion for a top-level [element]. If a [kind] is provided it
  /// will be used as the kind for the suggestion.
  void suggestElement(Element element,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    if (element is InterfaceElement) {
      suggestInterface(element);
    } else if (element is ConstructorElement) {
      suggestConstructor(element, kind: kind);
    } else if (element is ExtensionElement) {
      suggestExtension(element, kind: kind);
    } else if (element is FunctionElement &&
        element.enclosingElement is CompilationUnitElement) {
      suggestTopLevelFunction(element, kind: kind);
    } else if (element is PropertyAccessorElement &&
        element.enclosingElement is CompilationUnitElement) {
      suggestTopLevelPropertyAccessor(element);
    } else if (element is TypeAliasElement) {
      suggestTypeAlias(element);
    } else {
      throw ArgumentError('Cannot suggest a ${element.runtimeType}');
    }
  }

  /// Add a suggestion for an enum [constant]. If the enum can only be
  /// referenced using a prefix, then the [prefix] should be provided.
  void suggestEnumConstant(FieldElement constant, {String? prefix}) {
    var constantName = constant.name;
    var enumElement = constant.enclosingElement;
    var enumName = enumElement.name;
    var completion = '$enumName.$constantName';
    var relevance =
        _computeTopLevelRelevance(constant, elementType: constant.type);
    _addBuilder(
      _createCompletionSuggestionBuilder(
        constant,
        completion: completion,
        kind: CompletionSuggestionKind.IDENTIFIER,
        prefix: prefix,
        relevance: relevance,
        isNotImported: isNotImportedLibrary,
      ),
    );
  }

  /// Add a suggestion for an [extension]. If a [kind] is provided it will be
  /// used as the kind for the suggestion. If the extension can only be
  /// referenced using a prefix, then the [prefix] should be provided.
  void suggestExtension(ExtensionElement extension,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String? prefix}) {
    var completion = _getCompletionString(extension);
    if (completion == null) return;
    if (_couldMatch(completion, prefix)) {
      var relevance = _computeTopLevelRelevance(extension,
          elementType: extension.extendedType);
      _addBuilder(
        _createCompletionSuggestionBuilder(
          extension,
          kind: kind,
          prefix: prefix,
          relevance: relevance,
          isNotImported: isNotImportedLibrary,
        ),
      );
    }
  }

  /// Add a suggestion for a [field]. If the field is being referenced with a
  /// target of `super`, then the [containingMemberName] should be the name of
  /// the member containing the reference. The [inheritanceDistance] is the
  /// value of the inheritance distance feature computed for the field (or
  /// `-1.0` if the field is a static field).
  void suggestField(FieldElement field, {required double inheritanceDistance}) {
    var completion = _getCompletionString(field);
    if (completion == null) return;
    if (_couldMatch(completion, null)) {
      var featureComputer = request.featureComputer;
      var contextType =
          featureComputer.contextTypeFeature(request.contextType, field.type);
      var elementKind =
          _computeElementKind(field, distance: inheritanceDistance);
      var hasDeprecated = featureComputer.hasDeprecatedFeature(field);
      var isConstant =
          _preferConstants ? featureComputer.isConstantFeature(field) : 0.0;
      var startsWithDollar =
          featureComputer.startsWithDollarFeature(field.name);
      var superMatches = featureComputer.superMatchesFeature(
          _containingMemberName, field.name);
      var relevance = _computeRelevance(
        contextType: contextType,
        elementKind: elementKind,
        hasDeprecated: hasDeprecated,
        isConstant: isConstant,
        startsWithDollar: startsWithDollar,
        superMatches: superMatches,
        inheritanceDistance: inheritanceDistance,
      );
      _addBuilder(
        _createCompletionSuggestionBuilder(
          field,
          kind: CompletionSuggestionKind.IDENTIFIER,
          relevance: relevance,
          isNotImported: isNotImportedLibrary,
        ),
      );
    }
  }

  /// Add a suggestion to reference a [field] in a field formal parameter.
  void suggestFieldFormalParameter(FieldElement field) {
    // TODO(brianwilkerson) Add a parameter (`bool includePrefix`) indicating
    //  whether to include the `this.` prefix in the completion.
    _addBuilder(
      _createCompletionSuggestionBuilder(
        field,
        kind: CompletionSuggestionKind.IDENTIFIER,
        relevance: Relevance.fieldFormalParameter,
        isNotImported: isNotImportedLibrary,
      ),
    );
  }

  /// Add a suggestion for the `call` method defined on functions.
  void suggestFunctionCall() {
    final element = protocol.Element(protocol.ElementKind.METHOD,
        FunctionElement.CALL_METHOD_NAME, protocol.Element.makeFlags(),
        location: null,
        typeParameters: null,
        parameters: '()',
        returnType: 'void');
    _addSuggestion(
      CompletionSuggestion(
        CompletionSuggestionKind.INVOCATION,
        Relevance.callFunction,
        FunctionElement.CALL_METHOD_NAME,
        FunctionElement.CALL_METHOD_NAME.length,
        0,
        false,
        false,
        displayText: 'call()',
        element: element,
        returnType: 'void',
        parameterNames: [],
        parameterTypes: [],
        requiredParameterCount: 0,
        hasNamedParameters: false,
      ),
    );
  }

  /// Add a suggestion for an [element]. If the class can only be
  /// referenced using a prefix, then the [prefix] should be provided.
  void suggestInterface(InterfaceElement element, {String? prefix}) {
    var completion = _getCompletionString(element);
    if (completion == null) return;
    if (_couldMatch(completion, prefix)) {
      var relevance = _computeTopLevelRelevance(element,
          elementType: _instantiateInstanceElement(element));
      _addBuilder(
        _createCompletionSuggestionBuilder(
          element,
          kind: CompletionSuggestionKind.IDENTIFIER,
          prefix: prefix,
          relevance: relevance,
          isNotImported: isNotImportedLibrary,
        ),
      );
    }
  }

  /// Add a suggestion for a [keyword]. The [offset] is the offset from the
  /// beginning of the keyword where the cursor will be left.
  void suggestKeyword(String keyword, {int? offset}) {
    DartType? elementType;
    if (keyword == 'null') {
      elementType = request.featureComputer.typeProvider.nullType;
    } else if (keyword == 'false' || keyword == 'true') {
      elementType = request.featureComputer.typeProvider.boolType;
    }
    var contextType = request.featureComputer
        .contextTypeFeature(request.contextType, elementType);
    var keywordFeature = request.featureComputer
        .keywordFeature(keyword, request.opType.completionLocation);
    var relevance = _computeRelevance(
      contextType: contextType,
      keyword: keywordFeature,
    );
    _addSuggestion(CompletionSuggestion(CompletionSuggestionKind.KEYWORD,
        relevance, keyword, offset ?? keyword.length, 0, false, false));
  }

  /// Add a suggestion for a [label].
  void suggestLabel(Label label) {
    var completion = label.label.name;
    // TODO(brianwilkerson) Figure out why we're excluding labels consisting of
    //  a single underscore.
    if (completion.isNotEmpty && completion != '_') {
      var suggestion = CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER,
          Relevance.label, completion, completion.length, 0, false, false);
      suggestion.element = createLocalElement(
          request.source, protocol.ElementKind.LABEL, label.label);
      _addSuggestion(suggestion);
    }
  }

  /// Add a suggestion for the `loadLibrary` [function] associated with a
  /// prefix.
  void suggestLoadLibraryFunction(FunctionElement function) {
    // TODO(brianwilkerson) This might want to use the context type rather than
    //  a fixed value.
    var relevance = Relevance.loadLibrary;
    _addBuilder(
      _createCompletionSuggestionBuilder(
        function,
        kind: CompletionSuggestionKind.INVOCATION,
        relevance: relevance,
        isNotImported: isNotImportedLibrary,
      ),
    );
  }

  /// Add a suggestion for a local [variable].
  void suggestLocalVariable(LocalVariableElement variable) {
    var variableType = variable.type;
    var target = request.target;
    var entity = target.entity;
    var node = entity is AstNode ? entity : target.containingNode;
    var contextType = request.featureComputer
        .contextTypeFeature(request.contextType, variableType);
    var localVariableDistance =
        request.featureComputer.localVariableDistanceFeature(node, variable);
    var elementKind =
        _computeElementKind(variable, distance: localVariableDistance);
    var isConstant = _preferConstants
        ? request.featureComputer.isConstantFeature(variable)
        : 0.0;
    var relevance = _computeRelevance(
      contextType: contextType,
      elementKind: elementKind,
      isConstant: isConstant,
      localVariableDistance: localVariableDistance,
    );
    _addBuilder(
      _createCompletionSuggestionBuilder(
        variable,
        kind: CompletionSuggestionKind.IDENTIFIER,
        relevance: relevance,
        isNotImported: isNotImportedLibrary,
      ),
    );
  }

  /// Add a suggestion for a [method]. If a [kind] is provided it will be used
  /// as the kind for the suggestion. The [inheritanceDistance] is the value of
  /// the inheritance distance feature computed for the method.
  void suggestMethod(MethodElement method,
      {required CompletionSuggestionKind kind,
      required double inheritanceDistance}) {
    // TODO(brianwilkerson) Refactor callers so that we're passing in the type
    //  of the target (assuming we don't already have that type available via
    //  the [request]) and compute the [inheritanceDistance] in this method.
    var featureComputer = request.featureComputer;
    var contextType = featureComputer.contextTypeFeature(
        request.contextType, method.returnType);
    var elementKind =
        _computeElementKind(method, distance: inheritanceDistance);
    var hasDeprecated = featureComputer.hasDeprecatedFeature(method);
    var isConstant =
        _preferConstants ? featureComputer.isConstantFeature(method) : 0.0;
    var isNoSuchMethod = featureComputer.isNoSuchMethodFeature(
        _containingMemberName, method.name);
    var startsWithDollar = featureComputer.startsWithDollarFeature(method.name);
    var superMatches =
        featureComputer.superMatchesFeature(_containingMemberName, method.name);
    var relevance = _computeRelevance(
      contextType: contextType,
      elementKind: elementKind,
      hasDeprecated: hasDeprecated,
      isConstant: isConstant,
      isNoSuchMethod: isNoSuchMethod,
      isNotImported:
          request.featureComputer.isNotImportedFeature(isNotImportedLibrary),
      startsWithDollar: startsWithDollar,
      superMatches: superMatches,
      inheritanceDistance: inheritanceDistance,
    );

    var enclosingElement = method.enclosingElement;
    if (method.name == 'setState' &&
        enclosingElement is ClassElement &&
        flutter.isExactState(enclosingElement)) {
      // TODO(brianwilkerson) Make this more efficient by creating the correct
      //  suggestion in the first place.
      // Find the line indentation.
      var indent = getRequestLineIndent(request);

      // Build the completion and the selection offset.
      var buffer = StringBuffer();
      buffer.writeln('setState(() {');
      buffer.write('$indent  ');
      var selectionOffset = buffer.length;
      buffer.writeln();
      buffer.write('$indent});');

      _addSuggestion(
        DartCompletionSuggestion(
          kind,
          relevance,
          buffer.toString(),
          selectionOffset,
          0,
          false,
          false,
          // Let the user know that we are going to insert a complete statement.
          displayText: 'setState(() {});',
          elementLocation: method.location,
        ),
        textToMatchOverride: 'setState',
      );
      return;
    }

    _addBuilder(
      _createCompletionSuggestionBuilder(
        method,
        kind: kind,
        relevance: relevance,
        isNotImported: isNotImportedLibrary,
      ),
    );
  }

  /// Add a suggestion to use the [name] at a declaration site.
  void suggestName(String name) {
    // TODO(brianwilkerson) Explore whether there are any features of the name
    //  that can be used to provide better relevance scores.
    _addSuggestion(CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER,
        500, name, name.length, 0, false, false));
  }

  /// Add a suggestion to add a named argument corresponding to the [parameter].
  /// If [appendColon] is `true` then a colon will be added after the name. If
  /// [appendComma] is `true` then a comma will be included at the end of the
  /// completion text.
  void suggestNamedArgument(ParameterElement parameter,
      {required bool appendColon,
      required bool appendComma,
      int? replacementLength}) {
    var name = parameter.name;
    var type = parameter.type
        .getDisplayString(withNullability: _isNonNullableByDefault);

    var completion = name;
    if (appendColon) {
      completion += ': ';
    }
    var selectionOffset = completion.length;

    // Optionally add Flutter child widget details.
    // todo (pq): revisit this special casing; likely it can be generalized away
    var element = parameter.enclosingElement;
    // If appendColon is false, default values should never be appended.
    if (element is ConstructorElement && appendColon) {
      if (Flutter.instance
          .isWidget(element.enclosingElement.augmented?.declaration)) {
        var analysisOptions = request.analysisSession.analysisContext
            .getAnalysisOptionsForFile(
                request.resourceProvider.getFile(request.path));
        var codeStyleOptions = analysisOptions.codeStyleOptions;
        // Don't bother with nullability. It won't affect default list values.
        var defaultValue = getDefaultStringParameterValue(
            parameter, codeStyleOptions,
            withNullability: false);
        // TODO(devoncarew): Should we remove the check here? We would then
        // suggest values for param types like closures.
        if (defaultValue != null && defaultValue.text == '[]') {
          var completionLength = completion.length;
          completion += defaultValue.text;
          var cursorPosition = defaultValue.cursorPosition;
          if (cursorPosition != null) {
            selectionOffset = completionLength + cursorPosition;
          }
        }
      }
    }

    if (appendComma) {
      completion += ',';
    }

    int relevance;
    if (parameter.isRequiredNamed || parameter.hasRequired) {
      relevance = Relevance.requiredNamedArgument;
    } else {
      relevance = Relevance.namedArgument;
    }

    var suggestion = DartCompletionSuggestion(
        CompletionSuggestionKind.NAMED_ARGUMENT,
        relevance,
        completion,
        selectionOffset,
        0,
        false,
        false,
        parameterName: name,
        parameterType: type,
        replacementLength: replacementLength,
        elementLocation: parameter.location);
    if (parameter is FieldFormalParameterElement) {
      _setDocumentation(suggestion, parameter);
      suggestion.element =
          convertElement(parameter, withNullability: _isNonNullableByDefault);
    }

    _addSuggestion(suggestion);
  }

  /// Add a suggestion to add a named argument corresponding to the [field].
  /// If [appendColon] is `true` then a colon will be added after the name. If
  /// [appendComma] is `true` then a comma will be included at the end of the
  /// completion text.
  void suggestNamedRecordField(RecordTypeNamedField field,
      {required bool appendColon,
      required bool appendComma,
      int? replacementLength}) {
    final name = field.name;
    final type = field.type.getDisplayString(
      withNullability: _isNonNullableByDefault,
    );

    var completion = name;
    if (appendColon) {
      completion += ': ';
    }
    final selectionOffset = completion.length;

    if (appendComma) {
      completion += ',';
    }

    _addSuggestion(
      CompletionSuggestion(
        CompletionSuggestionKind.NAMED_ARGUMENT,
        Relevance.requiredNamedArgument,
        completion,
        selectionOffset,
        0,
        false,
        false,
        parameterName: name,
        parameterType: type,
        replacementLength: replacementLength,
      ),
    );
  }

  /// Add a suggestion to replace the [targetId] with an override of the given
  /// [element]. If [invokeSuper] is `true`, then the override will contain an
  /// invocation of an overridden member.
  Future<void> suggestOverride(
      Token targetId, ExecutableElement element, bool invokeSuper) async {
    var displayTextBuffer = StringBuffer();
    var overrideImports = <Uri>{};
    var builder = ChangeBuilder(session: request.analysisSession);
    await builder.addDartFileEdit(request.path, createEditsForImports: false,
        (builder) {
      builder.addReplacement(range.token(targetId), (builder) {
        builder.writeOverride(
          element,
          displayTextBuffer: displayTextBuffer,
          invokeSuper: invokeSuper,
        );
      });
      overrideImports.addAll(builder.requiredImports);
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
    if (request.target.containingNode.hasOverride &&
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
    var suggestion = DartCompletionSuggestion(
        CompletionSuggestionKind.OVERRIDE,
        Relevance.override,
        completion,
        selectionRange.offset - offsetDelta,
        selectionRange.length,
        element.hasDeprecated,
        false,
        displayText: displayText,
        elementLocation: element.location,
        requiredImports: overrideImports.toList());
    suggestion.element = protocol.convertElement(element,
        withNullability: _isNonNullableByDefault);
    _addSuggestion(
      suggestion,
      textToMatchOverride: _textToMatchOverride(element),
    );
  }

  /// Add a suggestion for a [parameter].
  void suggestParameter(ParameterElement parameter) {
    var variableType = parameter.type;
    // TODO(brianwilkerson) Use the distance to the declaring function as
    //  another feature.
    var contextType = request.featureComputer
        .contextTypeFeature(request.contextType, variableType);
    var elementKind = _computeElementKind(parameter);
    var isConstant = _preferConstants
        ? request.featureComputer.isConstantFeature(parameter)
        : 0.0;
    var relevance = _computeRelevance(
      contextType: contextType,
      elementKind: elementKind,
      isConstant: isConstant,
    );
    _addBuilder(
      _createCompletionSuggestionBuilder(
        parameter,
        kind: CompletionSuggestionKind.IDENTIFIER,
        relevance: relevance,
        isNotImported: isNotImportedLibrary,
      ),
    );
  }

  /// Add a suggestion for a [prefix] associated with a [library].
  void suggestPrefix(LibraryElement library, String prefix) {
    var elementKind = _computeElementKind(library);
    // TODO(brianwilkerson) If we are in a constant context it would be nice
    //  to promote prefixes for libraries that define constants, but that
    //  might be more work than it's worth.
    var relevance = _computeRelevance(
      elementKind: elementKind,
    );
    _addBuilder(
      _createCompletionSuggestionBuilder(
        library,
        completion: prefix,
        kind: CompletionSuggestionKind.IDENTIFIER,
        relevance: relevance,
        isNotImported: isNotImportedLibrary,
      ),
    );
  }

  void suggestRecordField({
    required RecordTypeField field,
    required String name,
  }) {
    final type = field.type;
    final featureComputer = request.featureComputer;
    final contextType =
        featureComputer.contextTypeFeature(request.contextType, type);
    final relevance = _computeRelevance(
      contextType: contextType,
    );

    final returnType = field.type.getDisplayString(
      withNullability: _isNonNullableByDefault,
    );

    _addSuggestion(
      CompletionSuggestion(
        CompletionSuggestionKind.IDENTIFIER,
        relevance,
        name,
        name.length,
        0,
        false,
        false,
        returnType: returnType,
      ),
    );
  }

  /// Add a suggestion for a static field declared within a class or extension.
  /// If the field is synthetic, add the corresponding getter instead.
  ///
  /// If the enclosing element can only be referenced using a prefix, then
  /// the [prefix] should be provided.
  void suggestStaticField(FieldElement element, {String? prefix}) {
    assert(element.isStatic);
    if (element.isSynthetic) {
      var getter = element.getter;
      if (getter != null) {
        suggestAccessor(
          getter,
          inheritanceDistance: 0.0,
          withEnclosingName: true,
        );
      }
    } else {
      var enclosingPrefix = '';
      var enclosingName = _enclosingClassOrExtensionName(element);
      if (enclosingName != null) {
        enclosingPrefix = '$enclosingName.';
      }
      var completion = enclosingPrefix + element.name;
      if (_couldMatch(completion, prefix)) {
        var relevance =
            _computeTopLevelRelevance(element, elementType: element.type);
        _addBuilder(
          _createCompletionSuggestionBuilder(
            element,
            completion: completion,
            kind: CompletionSuggestionKind.IDENTIFIER,
            prefix: prefix,
            relevance: relevance,
            isNotImported: isNotImportedLibrary,
          ),
        );
      }
    }
  }

  /// Add a suggestion to reference a [parameter] in a super formal parameter.
  void suggestSuperFormalParameter(ParameterElement parameter) {
    _addBuilder(
      _createCompletionSuggestionBuilder(
        parameter,
        kind: CompletionSuggestionKind.IDENTIFIER,
        relevance: Relevance.superFormalParameter,
        isNotImported: isNotImportedLibrary,
      ),
    );
  }

  /// Add a suggestion for a top-level [function]. If a [kind] is provided it
  /// will be used as the kind for the suggestion. If the function can only be
  /// referenced using a prefix, then the [prefix] should be provided.
  void suggestTopLevelFunction(FunctionElement function,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String? prefix}) {
    var completion = _getCompletionString(function);
    if (completion == null) return;
    if (_couldMatch(completion, prefix)) {
      var relevance =
          _computeTopLevelRelevance(function, elementType: function.returnType);
      _addBuilder(
        _createCompletionSuggestionBuilder(
          function,
          kind: kind,
          prefix: prefix,
          relevance: relevance,
          isNotImported: isNotImportedLibrary,
        ),
      );
    }
  }

  /// Add a suggestion for a top-level property [accessor]. If the accessor can
  /// only be referenced using a prefix, then the [prefix] should be provided.
  void suggestTopLevelPropertyAccessor(PropertyAccessorElement accessor,
      {String? prefix}) {
    assert(
        accessor.enclosingElement is CompilationUnitElement,
        'Enclosing element of ${accessor.runtimeType} is '
        '${accessor.enclosingElement.runtimeType}.');
    if (accessor.isSynthetic) {
      // Avoid visiting a field twice. All fields induce a getter, but only
      // non-final fields induce a setter, so we don't add a suggestion for a
      // synthetic setter.
      if (accessor.isGetter) {
        var variable = accessor.variable;
        if (variable is TopLevelVariableElement) {
          suggestTopLevelVariable(variable);
        }
      }
    } else {
      var completion = _getCompletionString(accessor);
      if (completion == null) return;
      if (_couldMatch(completion, prefix)) {
        var type = _getPropertyAccessorType(accessor);
        var featureComputer = request.featureComputer;
        var contextType =
            featureComputer.contextTypeFeature(request.contextType, type);
        var elementKind = _computeElementKind(accessor);
        var hasDeprecated = featureComputer.hasDeprecatedFeature(accessor);
        var isConstant = _preferConstants
            ? featureComputer.isConstantFeature(accessor)
            : 0.0;
        var startsWithDollar =
            featureComputer.startsWithDollarFeature(accessor.name);
        var superMatches = 0.0;
        var relevance = _computeRelevance(
          contextType: contextType,
          elementKind: elementKind,
          hasDeprecated: hasDeprecated,
          isConstant: isConstant,
          isNotImported: request.featureComputer
              .isNotImportedFeature(isNotImportedLibrary),
          startsWithDollar: startsWithDollar,
          superMatches: superMatches,
        );
        _addBuilder(
          _createCompletionSuggestionBuilder(
            accessor,
            kind: CompletionSuggestionKind.IDENTIFIER,
            prefix: prefix,
            relevance: relevance,
            isNotImported: isNotImportedLibrary,
          ),
        );
      }
    }
  }

  /// Add a suggestion for a top-level [variable]. If the variable can only be
  /// referenced using a prefix, then the [prefix] should be provided.
  void suggestTopLevelVariable(TopLevelVariableElement variable,
      {String? prefix}) {
    var completion = _getCompletionString(variable);
    if (completion == null) return;
    if (_couldMatch(completion, prefix)) {
      assert(variable.enclosingElement is CompilationUnitElement);
      var relevance =
          _computeTopLevelRelevance(variable, elementType: variable.type);
      _addBuilder(
        _createCompletionSuggestionBuilder(
          variable,
          kind: CompletionSuggestionKind.IDENTIFIER,
          prefix: prefix,
          relevance: relevance,
          isNotImported: isNotImportedLibrary,
        ),
      );
    }
  }

  /// Add a suggestion for a [typeAlias]. If the alias can only be referenced
  /// using a prefix, then the [prefix] should be provided.
  void suggestTypeAlias(TypeAliasElement typeAlias, {String? prefix}) {
    var completion = _getCompletionString(typeAlias);
    if (completion == null) return;
    if (_couldMatch(completion, prefix)) {
      var relevance = _computeTopLevelRelevance(typeAlias,
          elementType: _instantiateTypeAlias(typeAlias));
      _addBuilder(
        _createCompletionSuggestionBuilder(
          typeAlias,
          kind: CompletionSuggestionKind.IDENTIFIER,
          prefix: prefix,
          relevance: relevance,
          isNotImported: isNotImportedLibrary,
        ),
      );
    }
  }

  /// Add a suggestion for a type [parameter].
  void suggestTypeParameter(TypeParameterElement parameter) {
    var elementKind = _computeElementKind(parameter);
    var isConstant = _preferConstants
        ? request.featureComputer.isConstantFeature(parameter)
        : 0.0;
    var relevance = _computeRelevance(
      elementKind: elementKind,
      isConstant: isConstant,
    );
    _addBuilder(
      _createCompletionSuggestionBuilder(
        parameter,
        kind: CompletionSuggestionKind.IDENTIFIER,
        relevance: relevance,
        isNotImported: isNotImportedLibrary,
      ),
    );
  }

  /// Add a suggestion to use the [uri] in an import, export, or part directive.
  void suggestUri(String uri) {
    var relevance =
        uri == 'dart:core' ? Relevance.importDartCore : Relevance.import;
    _addSuggestion(
      CompletionSuggestion(CompletionSuggestionKind.IMPORT, relevance, uri,
          uri.length, 0, false, false),
    );
  }

  /// Add the given [suggestion] if it isn't `null` and if it isn't shadowed by
  /// a previously added suggestion.
  void _addBuilder(CompletionSuggestionBuilder? suggestion) {
    if (suggestion != null) {
      var key = suggestion.key;
      listener?.builtSuggestion(suggestion);
      if (laterReplacesEarlier || !_suggestionMap.containsKey(key)) {
        // TODO(brianwilkerson) Add some specific tests of shadowing behavior.
        if (suggestion is _CompletionSuggestionBuilderImpl) {
          // We need to special-case constructors because the order in which
          // suggestions are added has been changed by the move to
          // `InScopeCompletionPass`.
          var suggestedElement = suggestion.orgElement;
          if (suggestedElement is ConstructorElement) {
            var parentName = suggestedElement.enclosingElement.name;
            var existingSuggestion = _suggestionMap[parentName];
            if (existingSuggestion is _CompletionSuggestionBuilderImpl &&
                existingSuggestion.orgElement is! ClassElement) {
              // We return when the current suggestion is not a class because that
              // means that the current suggestion shadows the one being added.
              return;
            }
          }
        }
        // When suggesting from not-yet-imported libraries, record items
        // with a key that includes the URI so that multiple not-yet-imported
        // libraries can be included, but only if there is no imported library
        // contributing that key.
        if (isNotImportedLibrary) {
          key += '::$libraryUriStr';
          // If `!laterReplacesEarlier`, also ensure we don't already have this
          // new key.
          if (!laterReplacesEarlier && _suggestionMap.containsKey(key)) {
            return;
          }
        }
        _suggestionMap[key] = suggestion;
      }
    }
  }

  /// Add the given [suggestion] if it isn't shadowed by a previously added
  /// suggestion.
  void _addSuggestion(
    protocol.CompletionSuggestion suggestion, {
    String? textToMatchOverride,
  }) {
    _addBuilder(
      ValueCompletionSuggestionBuilder(
        suggestion,
        textToMatchOverride: textToMatchOverride,
      ),
    );
  }

  /// Compute the value of the _element kind_ feature for the given [element] in
  /// the completion context.
  double _computeElementKind(Element element, {double? distance}) {
    var location = request.opType.completionLocation;
    var elementKind = request.featureComputer
        .elementKindFeature(element, location, distance: distance);
    if (elementKind < 0.0) {
      if (location == null) {
        listener?.missingCompletionLocationAt(
            request.target.containingNode, request.target.entity!);
      } else {
        listener?.missingElementKindTableFor(location);
      }
    }
    return elementKind;
  }

  /// Compute the relevance based on the given feature values and pass those
  /// feature values to the listener if there is one.
  int _computeRelevance(
      {double contextType = 0.0,
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
      double localVariableDistance = 0.0}) {
    var score = weightedAverage(
        contextType: contextType,
        elementKind: elementKind,
        hasDeprecated: hasDeprecated,
        isConstant: isConstant,
        isNoSuchMethod: isNoSuchMethod,
        isNotImported: isNotImported,
        keyword: keyword,
        startsWithDollar: startsWithDollar,
        superMatches: superMatches);
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
  int _computeTopLevelRelevance(Element element,
      {required DartType elementType}) {
    // TODO(brianwilkerson) The old relevance computation used a signal based
    //  on whether the element being suggested was from the same library in
    //  which completion is being performed. Explore whether that's a useful
    //  signal.
    var featureComputer = request.featureComputer;
    var contextType =
        featureComputer.contextTypeFeature(request.contextType, elementType);
    var elementKind = _computeElementKind(element);
    var hasDeprecated = featureComputer.hasDeprecatedFeature(element);
    var isConstant =
        _preferConstants ? featureComputer.isConstantFeature(element) : 0.0;
    return _computeRelevance(
      contextType: contextType,
      elementKind: elementKind,
      hasDeprecated: hasDeprecated,
      isConstant: isConstant,
      isNotImported:
          request.featureComputer.isNotImportedFeature(isNotImportedLibrary),
    );
  }

  bool _couldMatch(String candidateArbitraryCase, String? prefix) {
    if (!useFilter) return true;
    var candidateLower = candidateArbitraryCase.toLowerCase();
    if (prefix != null) {
      candidateLower = '${prefix.toLowerCase()}.$candidateLower';
    }
    var i = 0;
    var j = 0;
    for (; i < candidateLower.length && j < targetPrefixLower.length; i++) {
      if (candidateLower.codeUnitAt(i) == targetPrefixLower.codeUnitAt(j)) {
        j++;
      }
    }
    return j == targetPrefixLower.length;
  }

  /// Return a [CompletionSuggestionBuilder] based on the [element], or `null`
  /// if the element cannot be suggested. If the completion should be something
  /// different than the name of the element, then the [completion] should be
  /// supplied. If an [elementKind] is provided, then it will be used rather
  /// than the kind normally used for the element. If a [prefix] is provided,
  /// then the element name (or completion) will be prefixed. The [relevance] is
  /// the relevance of the suggestion.
  CompletionSuggestionBuilder? _createCompletionSuggestionBuilder(
    Element element, {
    String? completion,
    required CompletionSuggestionKind kind,
    required int relevance,
    required bool isNotImported,
    String? prefix,
  }) {
    completion ??= _getCompletionString(element);
    if (completion == null) {
      return null;
    }

    if (prefix != null) {
      completion = '$prefix.$completion';
    }

    return _CompletionSuggestionBuilderImpl(
      orgElement: element,
      suggestionBuilder: this,
      kind: kind,
      completion: completion,
      relevance: relevance,
      libraryUriStr: libraryUriStr,
      requiredImports: requiredImports.toList(),
      isNotImported: isNotImported,
    );
  }

  /// The non-caching implementation of [_getElementCompletionData].
  _ElementCompletionData _createElementCompletionData(Element element) {
    var documentation = _getDocumentation(element);

    var suggestedElement = protocol.convertElement(
      element,
      withNullability: _isNonNullableByDefault,
    );

    var enclosingElement = element.enclosingElement;

    String? declaringType;
    if (enclosingElement is InterfaceElement) {
      declaringType = enclosingElement.displayName;
    }

    var returnType = getReturnTypeString(
      element,
      withNullability: _isNonNullableByDefault,
    );

    List<String>? parameterNames;
    List<String>? parameterTypes;
    int? requiredParameterCount;
    bool? hasNamedParameters;
    CompletionDefaultArgumentList? defaultArgumentList;
    if (element is ExecutableElement && element is! PropertyAccessorElement) {
      parameterNames = element.parameters.map((parameter) {
        return parameter.name;
      }).toList();
      parameterTypes = element.parameters.map((ParameterElement parameter) {
        return parameter.type.getDisplayString(
          withNullability: _isNonNullableByDefault,
        );
      }).toList();

      var requiredParameters = element.parameters
          .where((ParameterElement param) => param.isRequiredPositional);
      requiredParameterCount = requiredParameters.length;

      var namedParameters =
          element.parameters.where((ParameterElement param) => param.isNamed);
      hasNamedParameters = namedParameters.isNotEmpty;

      defaultArgumentList = computeCompletionDefaultArgumentList(
          element, requiredParameters, namedParameters);
    }

    return _ElementCompletionData(
      isDeprecated: element.hasOrInheritsDeprecated,
      declaringType: declaringType,
      returnType: returnType,
      parameterNames: parameterNames,
      parameterTypes: parameterTypes,
      requiredParameterCount: requiredParameterCount,
      hasNamedParameters: hasNamedParameters,
      documentation: documentation,
      defaultArgumentList: defaultArgumentList,
      element: suggestedElement,
      elementLocation: element.location,
    );
  }

  /// Return the name of the enclosing class or extension.
  ///
  /// The enclosing element must be either a class, or extension; otherwise
  /// we either fail with assertion, or return `null`.
  String? _enclosingClassOrExtensionName(Element element) {
    var enclosing = element.enclosingElement;
    if (enclosing is InterfaceElement) {
      return enclosing.name;
    } else if (enclosing is ExtensionElement) {
      return enclosing.name;
    } else {
      assert(false, 'Expected ClassElement or ExtensionElement');
      return null;
    }
  }

  String? _getCompletionString(Element element) {
    if (element is ExecutableElement && element.isOperator) {
      return null;
    }

    return element.displayName;
  }

  /// If the [element] has a documentation comment, return it.
  _ElementDocumentation? _getDocumentation(Element element) {
    var doc = DartUnitHoverComputer.computeDocumentation(
      request.dartdocDirectiveInfo,
      element,
      includeSummary: true,
    );
    if (doc is DocumentationWithSummary) {
      return _ElementDocumentation(
        full: doc.full,
        summary: doc.summary,
      );
    }
    if (doc is Documentation) {
      return _ElementDocumentation(
        full: doc.full,
        summary: null,
      );
    }
    return null;
  }

  /// Return the type associated with the [accessor], maybe `null` if an
  /// invalid setter with no parameters at all.
  DartType? _getPropertyAccessorType(PropertyAccessorElement accessor) {
    if (accessor.isGetter) {
      return accessor.returnType;
    } else {
      var parameters = accessor.parameters;
      if (parameters.isEmpty) {
        return null;
      } else {
        return parameters[0].type;
      }
    }
  }

  InterfaceType _instantiateInstanceElement(InterfaceElement element) {
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

  DartType _instantiateTypeAlias(TypeAliasElement element) {
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

  /// If the [element] has a documentation comment, fill the [suggestion]'s
  /// documentation fields.
  void _setDocumentation(CompletionSuggestion suggestion, Element element) {
    var doc = DartUnitHoverComputer.computeDocumentation(
        request.dartdocDirectiveInfo, element,
        includeSummary: true);
    if (doc is DocumentationWithSummary) {
      suggestion.docComplete = doc.full;
      suggestion.docSummary = doc.summary;
    }
  }

  static String _textToMatchOverride(ExecutableElement element) {
    if (element.isOperator) {
      return 'operator';
    }
    return element.displayName;
  }
}

abstract class SuggestionListener {
  /// Invoked when a suggestion has been built.
  void builtSuggestion(CompletionSuggestionBuilder suggestionBuilder);

  /// Invoked with the values of the features that were computed in the process
  /// of building a suggestion. This method is invoked prior to invoking
  /// [builtSuggestion].
  void computedFeatures(
      {double contextType,
      double elementKind,
      double hasDeprecated,
      double isConstant,
      double isNoSuchMethod,
      double isNotImported,
      double keyword,
      double startsWithDollar,
      double superMatches,
      // Dependent features
      double inheritanceDistance,
      double localVariableDistance});

  /// Invoked when an element kind feature cannot be produced because there is
  /// no completion location label associated with the completion offset.
  void missingCompletionLocationAt(
      AstNode containingNode, SyntacticEntity entity);

  /// Invoked when an element kind feature cannot be produced because there is
  /// no `elementKindRelevance` table associated with the [completionLocation].
  void missingElementKindTableFor(String completionLocation);
}

/// [CompletionSuggestionBuilder] that is based on a [CompletionSuggestion].
class ValueCompletionSuggestionBuilder implements CompletionSuggestionBuilder {
  final CompletionSuggestion _suggestion;

  final String? _textToMatchOverride;

  ValueCompletionSuggestionBuilder(
    this._suggestion, {
    String? textToMatchOverride,
  }) : _textToMatchOverride = textToMatchOverride;

  @override
  String get completion => _suggestion.completion;

  @override
  String get key => completion;

  @override
  protocol.CompletionSuggestionKind get kind => _suggestion.kind;

  @override
  int get relevance => _suggestion.relevance;

  @override
  String get textToMatch => _textToMatchOverride ?? completion;

  @override
  CompletionSuggestion build() {
    return _suggestion;
  }
}

/// The implementation of [CompletionSuggestionBuilder] that is based on
/// [ElementCompletionData] and location specific information.
class _CompletionSuggestionBuilderImpl implements CompletionSuggestionBuilder {
  final Element orgElement;
  final SuggestionBuilder suggestionBuilder;

  @override
  final CompletionSuggestionKind kind;

  @override
  final int relevance;

  @override
  final String completion;
  final String? libraryUriStr;
  final List<Uri> requiredImports;
  final bool isNotImported;

  _CompletionSuggestionBuilderImpl({
    required this.orgElement,
    required this.suggestionBuilder,
    required this.kind,
    required this.completion,
    required this.relevance,
    required this.libraryUriStr,
    required this.requiredImports,
    required this.isNotImported,
  });

  /// TODO(scheglov) implement better key for not-yet-imported
  @override
  String get key {
    var key = completion;
    if (orgElement.kind == ElementKind.CONSTRUCTOR) {
      key = '$key()';
    }
    return key;
  }

  @override
  String get textToMatch => completion;

  @override
  CompletionSuggestion build() {
    final element = suggestionBuilder._createElementCompletionData(orgElement);
    return DartCompletionSuggestion(
      kind,
      relevance,
      completion,
      completion.length /*selectionOffset*/,
      0 /*selectionLength*/,
      element.isDeprecated,
      false /*isPotential*/,
      element: element.element,
      docSummary: element.documentation?.summary,
      docComplete: element.documentation?.full,
      declaringType: element.declaringType,
      returnType: element.returnType,
      requiredParameterCount: element.requiredParameterCount,
      hasNamedParameters: element.hasNamedParameters,
      parameterNames: element.parameterNames,
      parameterTypes: element.parameterTypes,
      defaultArgumentListString: element.defaultArgumentList?.text,
      defaultArgumentListTextRanges: element.defaultArgumentList?.ranges,
      libraryUri: libraryUriStr,
      isNotImported: isNotImported ? true : null,
      elementLocation: element.elementLocation,
      requiredImports: requiredImports,
    );
  }
}

/// Information about an [Element] that does not depend on the location where
/// this element is suggested. For some often used elements, such as classes,
/// it might be cached, so created only once.
class _ElementCompletionData {
  final bool isDeprecated;
  final String? declaringType;
  final String? returnType;
  final List<String>? parameterNames;
  final List<String>? parameterTypes;
  final int? requiredParameterCount;
  final bool? hasNamedParameters;
  CompletionDefaultArgumentList? defaultArgumentList;
  final _ElementDocumentation? documentation;
  final protocol.Element element;
  final ElementLocation? elementLocation;

  _ElementCompletionData({
    required this.isDeprecated,
    required this.declaringType,
    required this.returnType,
    required this.parameterNames,
    required this.parameterTypes,
    required this.requiredParameterCount,
    required this.hasNamedParameters,
    required this.defaultArgumentList,
    required this.documentation,
    required this.element,
    required this.elementLocation,
  });
}

class _ElementDocumentation {
  final String full;
  final String? summary;

  _ElementDocumentation({
    required this.full,
    required this.summary,
  });
}
