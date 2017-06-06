// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart'
    show DartCompletionRequestImpl;
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol
    show ElementKind;
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';
import 'package:analyzer_plugin/src/utilities/visitors/local_declaration_visitor.dart'
    show LocalDeclarationVisitor;

/**
 * A contributor for calculating label suggestions.
 */
class LabelContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    OpType optype = (request as DartCompletionRequestImpl).opType;

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    if (!optype.isPrefixed) {
      if (optype.includeStatementLabelSuggestions ||
          optype.includeCaseLabelSuggestions) {
        new _LabelVisitor(request, optype.includeStatementLabelSuggestions,
                optype.includeCaseLabelSuggestions, suggestions)
            .visit(request.target.containingNode);
      }
    }
    return suggestions;
  }
}

/**
 * A visitor for collecting suggestions for break and continue labels.
 */
class _LabelVisitor extends LocalDeclarationVisitor {
  final DartCompletionRequest request;
  final List<CompletionSuggestion> suggestions;

  /**
   * True if statement labels should be included as suggestions.
   */
  final bool includeStatementLabels;

  /**
   * True if case labels should be included as suggestions.
   */
  final bool includeCaseLabels;

  _LabelVisitor(DartCompletionRequest request, this.includeStatementLabels,
      this.includeCaseLabels, this.suggestions)
      : request = request,
        super(request.offset);

  @override
  void declaredClass(ClassDeclaration declaration) {
    // ignored
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    // ignored
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    // ignored
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    // ignored
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    // ignored
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    if (isCaseLabel ? includeCaseLabels : includeStatementLabels) {
      CompletionSuggestion suggestion = _addSuggestion(label.label);
      if (suggestion != null) {
        suggestion.element = createLocalElement(
            request.source, protocol.ElementKind.LABEL, label.label,
            returnType: NO_RETURN_TYPE);
      }
    }
  }

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeAnnotation type) {
    // ignored
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    // ignored
  }

  @override
  void declaredParam(SimpleIdentifier name, TypeAnnotation type) {
    // ignored
  }

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {
    // ignored
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Labels are only accessible within the local function, so stop visiting
    // once we reach a function boundary.
    finished();
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Labels are only accessible within the local function, so stop visiting
    // once we reach a function boundary.
    finished();
  }

  CompletionSuggestion _addSuggestion(SimpleIdentifier id) {
    if (id != null) {
      String completion = id.name;
      if (completion != null && completion.length > 0 && completion != '_') {
        CompletionSuggestion suggestion = new CompletionSuggestion(
            CompletionSuggestionKind.IDENTIFIER,
            DART_RELEVANCE_DEFAULT,
            completion,
            completion.length,
            0,
            false,
            false);
        suggestions.add(suggestion);
        return suggestion;
      }
    }
    return null;
  }
}
