// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/base/syntactic_entity.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

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
      CompletionSuggestionKind? kind,
      required double inheritanceDistance}) {
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
  String? _cachedContainingMemberName;

  /// Initialize a newly created suggestion builder to build suggestions for the
  /// given [request].
  SuggestionBuilder(this.request, {this.listener});

  /// Return an object that can answer questions about Flutter code.
  Flutter get flutter => Flutter.instance;

  /// Return an iterable that can be used to access the completion suggestions
  /// that have been built.
  Iterable<CompletionSuggestion> get suggestions => _suggestionMap.values;

  /// Return the name of the member containing the completion location, or
  /// `null` if the completion location isn't within a member or if the target
  /// of the completion isn't `super`.
  String? get _containingMemberName {
    if (!_hasContainingMemberName) {
      _hasContainingMemberName = true;
      if (request.dotTarget is SuperExpression) {
        var containingMethod = request.target.containingNode
            .thisOrAncestorOfType<MethodDeclaration>();
        if (containingMethod != null) {
          _cachedContainingMemberName = containingMethod.name.name;
        }
      }
    }
    return _cachedContainingMemberName;
  }

  bool get _isNonNullableByDefault =>
      request.libraryElement?.isNonNullableByDefault ?? false;

  /// Add a suggestion for an [accessor] declared within a class or extension.
  /// If the accessor is being invoked with a target of `super`, then the
  /// [containingMemberName] should be the name of the member containing the
  /// invocation. The [inheritanceDistance] is the value of the inheritance
  /// distance feature computed for the accessor or `-1.0` if the accessor is a
  /// static accessor.
  void suggestAccessor(PropertyAccessorElement accessor,
      {required double inheritanceDistance}) {
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
      var type = _getPropertyAccessorType(accessor);
      var featureComputer = request.featureComputer;
      var contextType =
          featureComputer.contextTypeFeature(request.contextType, type);
      var elementKind =
          _computeElementKind(accessor, distance: inheritanceDistance);
      var hasDeprecated = featureComputer.hasDeprecatedFeature(accessor);
      var isConstant = request.inConstantContext
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
        startsWithDollar: startsWithDollar,
        superMatches: superMatches,
        inheritanceDistance: inheritanceDistance,
      );
      _add(_createSuggestion(accessor, relevance: relevance));
    }
  }

  /// Add a suggestion for a catch [parameter].
  void suggestCatchParameter(LocalVariableElement parameter) {
    var variableType = parameter.type;
    var contextType = request.featureComputer
        .contextTypeFeature(request.contextType, variableType);
    var elementKind = _computeElementKind(parameter);
    var isConstant = request.inConstantContext
        ? request.featureComputer.isConstantFeature(parameter)
        : 0.0;
    var relevance = _computeRelevance(
      contextType: contextType,
      elementKind: elementKind,
      isConstant: isConstant,
    );
    _add(_createSuggestion(parameter,
        elementKind: protocol.ElementKind.PARAMETER, relevance: relevance));
  }

  /// Add a suggestion for a [classElement]. If a [kind] is provided it will
  /// be used as the kind for the suggestion. If the class can only be
  /// referenced using a prefix, then the [prefix] should be provided.
  void suggestClass(ClassElement classElement,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String? prefix}) {
    var relevance = _computeTopLevelRelevance(classElement,
        elementType: _instantiateClassElement(classElement));
    _add(_createSuggestion(classElement,
        kind: kind, prefix: prefix, relevance: relevance));
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
      return CompletionSuggestion(
        CompletionSuggestionKind.INVOCATION,
        Relevance.closure,
        completion,
        selectionOffset,
        0,
        false,
        false,
        displayText: displayText,
      );
    }

    _add(createSuggestion(
      completion: blockBuffer.toString(),
      displayText: '$parametersString {}',
      selectionOffset: blockSelectionOffset,
    ));
    _add(createSuggestion(
      completion: expressionBuffer.toString(),
      displayText: '$parametersString =>',
      selectionOffset: expressionSelectionOffset,
    ));
  }

  /// Add a suggestion for a [constructor]. If a [kind] is provided it will be
  /// used as the kind for the suggestion. The flag [hasClassName] should be
  /// `true` if the completion is occurring after the name of the class and a
  /// period, and hence should not include the name of the class. If the class
  /// can only be referenced using a prefix, and the class name is to be
  /// included in the completion, then the [prefix] should be provided.
  void suggestConstructor(ConstructorElement constructor,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      bool hasClassName = false,
      String? prefix}) {
    // If the class name is already in the text, then we don't support
    // prepending a prefix.
    assert(!hasClassName || prefix == null);
    var enclosingClass = constructor.enclosingElement;
    var className = enclosingClass.name;
    if (className.isEmpty) {
      return;
    }

    var completion = constructor.displayName;
    if (!hasClassName && className.isNotEmpty) {
      if (completion.isEmpty) {
        completion = className;
      } else {
        completion = '$className.$completion';
      }
    }
    if (completion.isEmpty) {
      return;
    }

    var returnType = _instantiateClassElement(enclosingClass);
    var relevance =
        _computeTopLevelRelevance(constructor, elementType: returnType);
    _add(_createSuggestion(constructor,
        completion: completion,
        kind: kind,
        prefix: prefix,
        relevance: relevance));
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
    } else if (element is PropertyAccessorElement &&
        element.enclosingElement is CompilationUnitElement) {
      suggestTopLevelPropertyAccessor(element, kind: kind);
    } else if (element is TypeAliasElement) {
      suggestTypeAlias(element, kind: kind);
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
    _add(_createSuggestion(constant,
        completion: completion, prefix: prefix, relevance: relevance));
  }

  /// Add a suggestion for an [extension]. If a [kind] is provided it will be
  /// used as the kind for the suggestion. If the extension can only be
  /// referenced using a prefix, then the [prefix] should be provided.
  void suggestExtension(ExtensionElement extension,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String? prefix}) {
    var relevance = _computeTopLevelRelevance(extension,
        elementType: extension.extendedType);
    _add(_createSuggestion(extension,
        kind: kind, prefix: prefix, relevance: relevance));
  }

  /// Add a suggestion for a [field]. If the field is being referenced with a
  /// target of `super`, then the [containingMemberName] should be the name of
  /// the member containing the reference. The [inheritanceDistance] is the
  /// value of the inheritance distance feature computed for the field (or
  /// `-1.0` if the field is a static field).
  void suggestField(FieldElement field, {required double inheritanceDistance}) {
    var featureComputer = request.featureComputer;
    var contextType =
        featureComputer.contextTypeFeature(request.contextType, field.type);
    var elementKind = _computeElementKind(field, distance: inheritanceDistance);
    var hasDeprecated = featureComputer.hasDeprecatedFeature(field);
    var isConstant = request.inConstantContext
        ? featureComputer.isConstantFeature(field)
        : 0.0;
    var startsWithDollar = featureComputer.startsWithDollarFeature(field.name);
    var superMatches =
        featureComputer.superMatchesFeature(_containingMemberName, field.name);
    var relevance = _computeRelevance(
      contextType: contextType,
      elementKind: elementKind,
      hasDeprecated: hasDeprecated,
      isConstant: isConstant,
      startsWithDollar: startsWithDollar,
      superMatches: superMatches,
      inheritanceDistance: inheritanceDistance,
    );
    _add(_createSuggestion(field, relevance: relevance));
  }

  /// Add a suggestion to reference a [field] in a field formal parameter.
  void suggestFieldFormalParameter(FieldElement field) {
    // TODO(brianwilkerson) Add a parameter (`bool includePrefix`) indicating
    //  whether to include the `this.` prefix in the completion.
    _add(_createSuggestion(field, relevance: Relevance.fieldFormalParameter));
  }

  /// Add a suggestion for the `call` method defined on functions.
  void suggestFunctionCall() {
    const callString = 'call';
    final element = protocol.Element(
        protocol.ElementKind.METHOD, callString, protocol.Element.makeFlags(),
        location: null,
        typeParameters: null,
        parameters: '()',
        returnType: 'void');
    _add(CompletionSuggestion(
      CompletionSuggestionKind.INVOCATION,
      Relevance.callFunction,
      callString,
      callString.length,
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
    ));
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
    _add(CompletionSuggestion(CompletionSuggestionKind.KEYWORD, relevance,
        keyword, offset ?? keyword.length, 0, false, false));
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
          request.source, protocol.ElementKind.LABEL, label.label,
          returnType: NO_RETURN_TYPE);
      _add(suggestion);
    }
  }

  /// Add a suggestion for the `loadLibrary` [function] associated with a
  /// prefix.
  void suggestLoadLibraryFunction(FunctionElement function) {
    // TODO(brianwilkerson) This might want to use the context type rather than
    //  a fixed value.
    var relevance = Relevance.loadLibrary;
    _add(_createSuggestion(function, relevance: relevance));
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
    var isConstant = request.inConstantContext
        ? request.featureComputer.isConstantFeature(variable)
        : 0.0;
    var relevance = _computeRelevance(
      contextType: contextType,
      elementKind: elementKind,
      isConstant: isConstant,
      localVariableDistance: localVariableDistance,
    );
    _add(_createSuggestion(variable, relevance: relevance));
  }

  /// Add a suggestion for a [method]. If the method is being invoked with a
  /// target of `super`, then the [containingMemberName] should be the name of
  /// the member containing the invocation. If a [kind] is provided it will be
  /// used as the kind for the suggestion. The [inheritanceDistance] is the
  /// value of the inheritance distance feature computed for the method.
  void suggestMethod(MethodElement method,
      {CompletionSuggestionKind? kind, required double inheritanceDistance}) {
    // TODO(brianwilkerson) Refactor callers so that we're passing in the type
    //  of the target (assuming we don't already have that type available via
    //  the [request]) and compute the [inheritanceDistance] in this method.
    var featureComputer = request.featureComputer;
    var contextType = featureComputer.contextTypeFeature(
        request.contextType, method.returnType);
    var elementKind =
        _computeElementKind(method, distance: inheritanceDistance);
    var hasDeprecated = featureComputer.hasDeprecatedFeature(method);
    var isConstant = request.inConstantContext
        ? featureComputer.isConstantFeature(method)
        : 0.0;
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
      startsWithDollar: startsWithDollar,
      superMatches: superMatches,
      inheritanceDistance: inheritanceDistance,
    );

    var suggestion =
        _createSuggestion(method, kind: kind, relevance: relevance);
    if (suggestion != null) {
      var enclosingElement = method.enclosingElement;
      if (method.name == 'setState' &&
          enclosingElement is ClassElement &&
          flutter.isExactState(enclosingElement)) {
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
    _add(CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER, 500, name,
        name.length, 0, false, false));
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
    if (element is ConstructorElement) {
      if (Flutter.instance.isWidget(element.enclosingElement)) {
        // Don't bother with nullability. It won't affect default list values.
        var defaultValue =
            getDefaultStringParameterValue(parameter, withNullability: false);
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

    var suggestion = CompletionSuggestion(
        CompletionSuggestionKind.NAMED_ARGUMENT,
        relevance,
        completion,
        selectionOffset,
        0,
        false,
        false,
        parameterName: name,
        parameterType: type,
        replacementLength: replacementLength);
    if (parameter is FieldFormalParameterElement) {
      _setDocumentation(suggestion, parameter);
      suggestion.element =
          convertElement(parameter, withNullability: _isNonNullableByDefault);
    }
    _add(suggestion);
  }

  /// Add a suggestion to replace the [targetId] with an override of the given
  /// [element]. If [invokeSuper] is `true`, then the override will contain an
  /// invocation of an overridden member.
  Future<void> suggestOverride(SimpleIdentifier targetId,
      ExecutableElement element, bool invokeSuper) async {
    var displayTextBuffer = StringBuffer();
    var builder = ChangeBuilder(session: request.result.session);
    await builder.addDartFileEdit(request.result.path, (builder) {
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
    var suggestion = CompletionSuggestion(
        CompletionSuggestionKind.OVERRIDE,
        Relevance.override,
        completion,
        selectionRange.offset - offsetDelta,
        selectionRange.length,
        element.hasDeprecated,
        false,
        displayText: displayText);
    suggestion.element = protocol.convertElement(element,
        withNullability: _isNonNullableByDefault);
    _add(suggestion);
  }

  /// Add a suggestion for a [parameter].
  void suggestParameter(ParameterElement parameter) {
    var variableType = parameter.type;
    // TODO(brianwilkerson) Use the distance to the declaring function as
    //  another feature.
    var contextType = request.featureComputer
        .contextTypeFeature(request.contextType, variableType);
    var elementKind = _computeElementKind(parameter);
    var isConstant = request.inConstantContext
        ? request.featureComputer.isConstantFeature(parameter)
        : 0.0;
    var relevance = _computeRelevance(
      contextType: contextType,
      elementKind: elementKind,
      isConstant: isConstant,
    );
    _add(_createSuggestion(parameter, relevance: relevance));
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
    _add(_createSuggestion(library,
        completion: prefix,
        kind: CompletionSuggestionKind.IDENTIFIER,
        relevance: relevance));
  }

  /// Add a suggestion for a top-level [function]. If a [kind] is provided it
  /// will be used as the kind for the suggestion. If the function can only be
  /// referenced using a prefix, then the [prefix] should be provided.
  void suggestTopLevelFunction(FunctionElement function,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String? prefix}) {
    var relevance =
        _computeTopLevelRelevance(function, elementType: function.returnType);
    _add(_createSuggestion(function,
        kind: kind, prefix: prefix, relevance: relevance));
  }

  /// Add a suggestion for a top-level property [accessor]. If a [kind] is
  /// provided it will be used as the kind for the suggestion. If the accessor
  /// can only be referenced using a prefix, then the [prefix] should be
  /// provided.
  void suggestTopLevelPropertyAccessor(PropertyAccessorElement accessor,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String? prefix}) {
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
          suggestTopLevelVariable(variable, kind: kind);
        }
      }
    } else {
      var type = _getPropertyAccessorType(accessor);
      var featureComputer = request.featureComputer;
      var contextType =
          featureComputer.contextTypeFeature(request.contextType, type);
      var elementKind = _computeElementKind(accessor);
      var hasDeprecated = featureComputer.hasDeprecatedFeature(accessor);
      var isConstant = request.inConstantContext
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
        startsWithDollar: startsWithDollar,
        superMatches: superMatches,
      );
      _add(_createSuggestion(accessor, prefix: prefix, relevance: relevance));
    }
  }

  /// Add a suggestion for a top-level [variable]. If a [kind] is provided it
  /// will be used as the kind for the suggestion. If the variable can only be
  /// referenced using a prefix, then the [prefix] should be provided.
  void suggestTopLevelVariable(TopLevelVariableElement variable,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String? prefix}) {
    assert(variable.enclosingElement is CompilationUnitElement);
    var relevance =
        _computeTopLevelRelevance(variable, elementType: variable.type);
    _add(_createSuggestion(variable,
        kind: kind, prefix: prefix, relevance: relevance));
  }

  /// Add a suggestion for a [typeAlias]. If a [kind] is provided it
  /// will be used as the kind for the suggestion. If the alias can only be
  /// referenced using a prefix, then the [prefix] should be provided.
  void suggestTypeAlias(TypeAliasElement typeAlias,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String? prefix}) {
    var relevance = _computeTopLevelRelevance(typeAlias,
        elementType: _instantiateTypeAlias(typeAlias));
    _add(_createSuggestion(typeAlias,
        kind: kind, prefix: prefix, relevance: relevance));
  }

  /// Add a suggestion for a type [parameter].
  void suggestTypeParameter(TypeParameterElement parameter) {
    var elementKind = _computeElementKind(parameter);
    var isConstant = request.inConstantContext
        ? request.featureComputer.isConstantFeature(parameter)
        : 0.0;
    var relevance = _computeRelevance(
      elementKind: elementKind,
      isConstant: isConstant,
    );
    _add(_createSuggestion(parameter,
        kind: CompletionSuggestionKind.IDENTIFIER, relevance: relevance));
  }

  /// Add a suggestion to use the [uri] in an import, export, or part directive.
  void suggestUri(String uri) {
    var relevance =
        uri == 'dart:core' ? Relevance.importDartCore : Relevance.import;
    _add(CompletionSuggestion(CompletionSuggestionKind.IMPORT, relevance, uri,
        uri.length, 0, false, false));
  }

  /// Add the given [suggestion] if it isn't `null` and if it isn't shadowed by
  /// a previously added suggestion.
  void _add(protocol.CompletionSuggestion? suggestion) {
    if (suggestion != null) {
      var key = suggestion.completion;
      if (suggestion.element?.kind == protocol.ElementKind.CONSTRUCTOR) {
        key = '$key()';
      }
      listener?.builtSuggestion(suggestion);
      if (laterReplacesEarlier) {
        _suggestionMap[key] = suggestion;
      } else {
        _suggestionMap.putIfAbsent(key, () => suggestion);
      }
    }
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
    var isConstant = request.inConstantContext
        ? featureComputer.isConstantFeature(element)
        : 0.0;
    return _computeRelevance(
      contextType: contextType,
      elementKind: elementKind,
      hasDeprecated: hasDeprecated,
      isConstant: isConstant,
    );
  }

  /// Return a suggestion based on the [element], or `null` if a suggestion is
  /// not appropriate for the element. If the completion should be something
  /// different than the name of the element, then the [completion] should be
  /// supplied. If an [elementKind] is provided, then it will be used rather
  /// than the kind normally used for the element. If a [prefix] is provided,
  /// then the element name (or completion) will be prefixed. The [relevance] is
  /// the relevance of the suggestion.
  CompletionSuggestion? _createSuggestion(Element element,
      {String? completion,
      protocol.ElementKind? elementKind,
      CompletionSuggestionKind? kind,
      String? prefix,
      required int relevance}) {
    if (element is ExecutableElement && element.isOperator) {
      // Do not include operators in suggestions
      return null;
    }
    completion ??= element.displayName;
    if (completion.isEmpty) {
      return null;
    }
    if (prefix != null && prefix.isNotEmpty) {
      completion = '$prefix.$completion';
    }
    kind ??= CompletionSuggestionKind.INVOCATION;
    var suggestion = CompletionSuggestion(kind, relevance, completion,
        completion.length, 0, element.hasOrInheritsDeprecated, false);

    _setDocumentation(suggestion, element);
    var suggestedElement = suggestion.element = protocol.convertElement(element,
        withNullability: _isNonNullableByDefault);
    if (elementKind != null) {
      suggestedElement.kind = elementKind;
    }
    var enclosingElement = element.enclosingElement;
    if (enclosingElement is ClassElement) {
      suggestion.declaringType = enclosingElement.displayName;
    }
    suggestion.returnType =
        getReturnTypeString(element, withNullability: _isNonNullableByDefault);
    if (element is ExecutableElement && element is! PropertyAccessorElement) {
      suggestion.parameterNames = element.parameters
          .map((ParameterElement parameter) => parameter.name)
          .toList();
      suggestion.parameterTypes =
          element.parameters.map((ParameterElement parameter) {
        var paramType = parameter.type;
        return paramType.getDisplayString(
            withNullability: _isNonNullableByDefault);
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

  InterfaceType _instantiateClassElement(ClassElement element) {
    var typeParameters = element.typeParameters;
    var typeArguments = const <DartType>[];
    if (typeParameters.isNotEmpty) {
      var neverType = request.libraryElement!.typeProvider.neverType;
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
      var neverType = request.libraryElement!.typeProvider.neverType;
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
    final request = this.request;
    if (request is DartCompletionRequestImpl) {
      var documentationCache = request.documentationCache;
      var data = documentationCache?.dataFor(element);
      if (data != null) {
        suggestion.docComplete = data.full;
        suggestion.docSummary = data.summary;
        return;
      }
    }
    var doc = DartUnitHoverComputer.computeDocumentation(
        request.dartdocDirectiveInfo, element,
        includeSummary: true);
    if (doc is DocumentationWithSummary) {
      suggestion.docComplete = doc.full;
      suggestion.docSummary = doc.summary;
    }
  }
}

abstract class SuggestionListener {
  /// Invoked when a suggestion has been built.
  void builtSuggestion(protocol.CompletionSuggestion suggestion);

  /// Invoked with the values of the features that were computed in the process
  /// of building a suggestion. This method is invoked prior to invoking
  /// [builtSuggestion].
  void computedFeatures(
      {double contextType,
      double elementKind,
      double hasDeprecated,
      double isConstant,
      double isNoSuchMethod,
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
