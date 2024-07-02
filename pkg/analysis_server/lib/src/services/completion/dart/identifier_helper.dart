// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/completion_state.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_collector.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analysis_server/src/utilities/extensions/string.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// A helper class that produces candidate suggestions for identifiers when the
/// completion location is in a declaration site.
class IdentifierHelper {
  /// The state used to compute the candidate suggestions.
  final CompletionState state;

  /// The suggestion collector to which suggestions will be added.
  final SuggestionCollector collector;

  /// Whether private version of names should be included.
  final bool includePrivateIdentifiers;

  /// Initialize a newly created helper to add suggestions to the [collector].
  IdentifierHelper(
      {required this.state,
      required this.collector,
      required this.includePrivateIdentifiers});

  /// Adds any suggestions for the name of the [parameter].
  void addParameterName(FormalParameter parameter) {
    if (parameter is DefaultFormalParameter) {
      parameter = parameter.parameter;
    }
    if (parameter is SimpleFormalParameter) {
      addVariable(parameter.type);
    }
  }

  /// Adds suggestions based on the [typeName].
  void addSuggestionsFromTypeName(String typeName) {
    var variableNameSuggestions = getCamelWordCombinations(typeName);
    variableNameSuggestions.remove(typeName);
    for (var varName in variableNameSuggestions) {
      _createNameSuggestion(varName);
      if (includePrivateIdentifiers) {
        _createNameSuggestion('_$varName');
      }
    }
  }

  /// Adds any suggestions for the name of a top-level declaration (class, enum,
  /// mixin, function, etc.).
  void addTopLevelName({required bool includeBody}) {
    var context = state.request.analysisSession.resourceProvider.pathContext;
    var path = state.request.path;
    var candidateName = context.basenameWithoutExtension(path).toUpperCamelCase;
    if (candidateName == null) {
      return;
    }
    for (var unit in state.libraryElement.units) {
      for (var childElement in unit.children) {
        if (childElement.name == candidateName) {
          // Don't suggest a name that's already declared in the library.
          return;
        }
      }
    }
    var matcherScore = state.matcher.score(candidateName);
    if (matcherScore != -1) {
      collector.addSuggestion(IdentifierSuggestion(
        identifier: candidateName,
        includeBody: includeBody,
        matcherScore: matcherScore,
      ));
    }
  }

  /// Adds any suggestions for a variable with the given [type].
  void addVariable(TypeAnnotation? type) {
    if (type is NamedType) {
      addSuggestionsFromTypeName(type.name2.lexeme);
    }
  }

  /// Adds a suggestion for the [name] (unless the name is `null` or empty).
  void _createNameSuggestion(String name) {
    if (name.isNotEmpty) {
      var matcherScore = state.matcher.score(name);
      if (matcherScore != -1) {
        collector.addSuggestion(IdentifierSuggestion(
          identifier: name,
          includeBody: false,
          matcherScore: matcherScore,
        ));
      }
    }
  }
}
