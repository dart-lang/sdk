// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart'
    show DartCompletionRequestImpl;
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol
    show Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';
import 'package:analyzer_plugin/src/utilities/visitors/local_declaration_visitor.dart'
    show LocalDeclarationVisitor;

/**
 * A contributor for calculating constructor suggestions
 * for declarations in the local file.
 */
class LocalConstructorContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    OpType optype = (request as DartCompletionRequestImpl).opType;

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    if (!optype.isPrefixed) {
      if (optype.includeConstructorSuggestions) {
        new _Visitor(request, suggestions, optype)
            .visit(request.target.containingNode);
      }
    }
    return suggestions;
  }
}

/**
 * A visitor for collecting constructor suggestions.
 */
class _Visitor extends LocalDeclarationVisitor {
  final DartCompletionRequest request;
  final OpType optype;
  final List<CompletionSuggestion> suggestions;

  _Visitor(DartCompletionRequest request, this.suggestions, this.optype)
      : request = request,
        super(request.offset);

  @override
  void declaredClass(ClassDeclaration declaration) {
    bool found = false;
    for (ClassMember member in declaration.members) {
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
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {}

  @override
  void declaredFunction(FunctionDeclaration declaration) {}

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {}

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

  /**
   * For the given class and constructor,
   * add a suggestion of the form B(...) or B.name(...).
   * If the given constructor is `null`
   * then add a default constructor suggestion.
   */
  void _addSuggestion(
      ClassDeclaration classDecl, ConstructorDeclaration constructorDecl) {
    String completion = classDecl.name.name;
    SimpleIdentifier elemId;

    ClassElement classElement =
        resolutionMap.elementDeclaredByClassDeclaration(classDecl);
    int relevance = optype.constructorSuggestionsFilter(
        classElement?.type, DART_RELEVANCE_DEFAULT);
    if (relevance == null) {
      return;
    }

    // Build a suggestion for explicitly declared constructor
    if (constructorDecl != null) {
      elemId = constructorDecl.name;
      ConstructorElement elem = constructorDecl.element;
      if (elemId != null) {
        String name = elemId.name;
        if (name != null && name.length > 0) {
          completion = '$completion.$name';
        }
      }
      if (elem != null) {
        CompletionSuggestion suggestion = createSuggestion(elem,
            completion: completion, relevance: relevance);
        if (suggestion != null) {
          suggestions.add(suggestion);
        }
      }
    }

    // Build a suggestion for an implicit constructor
    else {
      protocol.Element element = createLocalElement(
          request.source, protocol.ElementKind.CONSTRUCTOR, elemId,
          parameters: '()');
      element.returnType = classDecl.name.name;
      CompletionSuggestion suggestion = new CompletionSuggestion(
          CompletionSuggestionKind.INVOCATION,
          relevance,
          completion,
          completion.length,
          0,
          false,
          false,
          declaringType: classDecl.name.name,
          element: element,
          parameterNames: [],
          parameterTypes: [],
          requiredParameterCount: 0,
          hasNamedParameters: false);
      suggestions.add(suggestion);
    }
  }
}
