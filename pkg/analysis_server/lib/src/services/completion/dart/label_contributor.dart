// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart'
    show DartCompletionRequestImpl;
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/src/utilities/visitors/local_declaration_visitor.dart'
    show LocalDeclarationVisitor;

/// A contributor that produces suggestions based on the labels that are in
/// scope. More concretely, this class produces completions in `break` and
/// `continue` statements.
class LabelContributor extends DartCompletionContributor {
  @override
  Future<void> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    var optype = (request as DartCompletionRequestImpl).opType;

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
    if (!optype.isPrefixed) {
      if (optype.includeStatementLabelSuggestions ||
          optype.includeCaseLabelSuggestions) {
        _LabelVisitor(request, builder, optype.includeStatementLabelSuggestions,
                optype.includeCaseLabelSuggestions)
            .visit(request.target.containingNode);
      }
    }
  }
}

/// A visitor for collecting suggestions for break and continue labels.
class _LabelVisitor extends LocalDeclarationVisitor {
  final DartCompletionRequest request;

  final SuggestionBuilder builder;

  /// A flag indicating whether statement labels should be included as
  /// suggestions.
  final bool includeStatementLabels;

  /// A flag indicating whether case labels should be included as suggestions.
  final bool includeCaseLabels;

  _LabelVisitor(this.request, this.builder, this.includeStatementLabels,
      this.includeCaseLabels)
      : super(request.offset);

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    if (isCaseLabel ? includeCaseLabels : includeStatementLabels) {
      builder.suggestLabel(label);
    }
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
}
