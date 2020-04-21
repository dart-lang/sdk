// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart'
    show DartCompletionRequestImpl;
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol
    show ElementKind;
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';
import 'package:analyzer_plugin/src/utilities/visitors/local_declaration_visitor.dart'
    show LocalDeclarationVisitor;

/// A contributor that produces suggestions based on the constructors declared
/// in the same file in which suggestions were requested.
class LocalConstructorContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    var optype = (request as DartCompletionRequestImpl).opType;

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
    var suggestions = <CompletionSuggestion>[];
    if (!optype.isPrefixed) {
      if (optype.includeConstructorSuggestions) {
        _Visitor(request, suggestions, optype)
            .visit(request.target.containingNode);
      }
    }
    return suggestions;
  }
}

/// A visitor for collecting constructor suggestions.
class _Visitor extends LocalDeclarationVisitor {
  final DartCompletionRequest request;
  final OpType optype;
  final List<CompletionSuggestion> suggestions;

  _Visitor(DartCompletionRequest request, this.suggestions, this.optype)
      : request = request,
        super(request.offset);

  @override
  void declaredClass(ClassDeclaration declaration) {
    var found = false;
    for (var member in declaration.members) {
      if (member is ConstructorDeclaration) {
        found = true;
        _addSuggestion(declaration, member);
      }
    }
    if (!found) {
      _addSuggestion(declaration, null);
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {}

  @override
  void declaredExtension(ExtensionDeclaration declaration) {}

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {}

  @override
  void declaredFunction(FunctionDeclaration declaration) {}

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {}

  @override
  void declaredGenericTypeAlias(GenericTypeAlias declaration) {}

  @override
  void declaredLabel(Label label, bool isCaseLabel) {}

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeAnnotation type) {}

  @override
  void declaredMethod(MethodDeclaration declaration) {}

  @override
  void declaredParam(SimpleIdentifier name, TypeAnnotation type) {}

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {}

  /// For the given class and constructor, add a suggestion of the form `B(...)`
  /// or `B.name(...)`. If the given constructor is `null` then add a default
  /// constructor suggestion.
  void _addSuggestion(
      ClassDeclaration classDecl, ConstructorDeclaration constructorDecl) {
    var completion = classDecl.name.name;

    var classElement = classDecl.declaredElement;
    var useNewRelevance = request.useNewRelevance;
    int relevance;
    if (useNewRelevance) {
      var contextType = request.featureComputer
          .computeContextType(request.target.containingNode);
      var contextTypeFeature = request.featureComputer
          .contextTypeFeature(contextType, classElement.thisType);
      relevance = toRelevance(contextTypeFeature, Relevance.constructor);
    } else {
      relevance = optype.returnValueSuggestionsFilter(
          _instantiateClassElement(classElement), DART_RELEVANCE_DEFAULT);
    }
    if (constructorDecl != null) {
      // Build a suggestion for explicitly declared constructor.
      var element = constructorDecl.declaredElement;
      if (element == null) {
        return;
      }
      if (classElement.isAbstract && !element.isFactory) {
        return;
      }

      var name = constructorDecl.name?.name;
      if (name != null && name.isNotEmpty) {
        completion = '$completion.$name';
      }

      var suggestion = createSuggestion(request, element,
          completion: completion,
          relevance: relevance,
          useNewRelevance: useNewRelevance);
      if (suggestion != null) {
        suggestions.add(suggestion);
      }
    } else if (!classElement.isAbstract) {
      // Build a suggestion for an implicit constructor.
      var element = createLocalElement(
          request.source, protocol.ElementKind.CONSTRUCTOR, null,
          parameters: '()');
      element.returnType = classDecl.name.name;
      var suggestion = CompletionSuggestion(CompletionSuggestionKind.INVOCATION,
          relevance, completion, completion.length, 0, false, false,
          declaringType: classDecl.name.name,
          element: element,
          parameterNames: [],
          parameterTypes: [],
          requiredParameterCount: 0,
          hasNamedParameters: false);
      suggestions.add(suggestion);
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
}
