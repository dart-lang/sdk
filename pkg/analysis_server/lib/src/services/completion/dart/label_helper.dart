// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_collector.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// A helper class that produces candidate suggestions for all of the labels
/// that are in scope at the completion location.
class LabelHelper {
  /// The suggestion collector to which suggestions will be added.
  final SuggestionCollector collector;

  /// Initialize a newly created helper to add suggestions to the [collector].
  LabelHelper({required this.collector});

  /// Add the labels that are visible at the `break` or `continue` [statement].
  void addLabels(Statement statement) {
    var includeCaseLabels = statement is ContinueStatement;
    AstNode? currentNode = statement;
    while (currentNode != null) {
      switch (currentNode) {
        case SwitchStatement():
          if (includeCaseLabels) {
            for (var member in currentNode.members) {
              _visitLabels(member.labels);
            }
          }
        case FunctionBody():
          return;
        case LabeledStatement():
          _visitLabels(currentNode.labels);
      }
      currentNode = currentNode.parent;
    }
  }

  void _visitLabels(NodeList<Label> labels) {
    for (var label in labels) {
      var suggestion = LabelSuggestion(label);
      collector.addSuggestion(suggestion);
    }
  }
}
