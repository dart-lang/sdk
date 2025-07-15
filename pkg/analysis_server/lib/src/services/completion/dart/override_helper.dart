// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/completion_state.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_collector.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';

/// A helper class that produces candidate suggestions for overrides of
/// inherited methods.
class OverrideHelper {
  /// The state used to compute the candidate suggestions.
  final CompletionState state;

  /// The suggestion collector to which suggestions will be added.
  final SuggestionCollector collector;

  /// Initialize a newly created helper to add suggestions to the [collector].
  OverrideHelper({required this.state, required this.collector});

  void computeOverridesFor({
    required InterfaceElement interfaceElement,
    required SourceRange replacementRange,
    required bool skipAt,
  }) {
    var namesToOverride = _namesToOverride(interfaceElement);

    // Build suggestions.
    for (var name in namesToOverride) {
      var element = interfaceElement.interfaceMembers[name];
      // Gracefully degrade if the overridden element has not been resolved.
      if (element != null) {
        if (_hasNonVirtualAnnotation(element)) {
          continue;
        }

        var matcherScore = math.max(
          math.max(
            state.matcher.score('override'),
            state.matcher.score('operator'),
          ),
          state.matcher.score(element.displayName),
        );
        var invokeSuper =
            interfaceElement.getInheritedConcreteMember(name) != null;
        if (matcherScore != -1) {
          collector.addSuggestion(
            OverrideSuggestion(
              element: element,
              shouldInvokeSuper: invokeSuper,
              skipAt: skipAt,
              replacementRange: replacementRange,
              matcherScore: matcherScore,
            ),
          );
        }
      }
    }
  }

  /// Checks if the [element] has the `@nonVirtual` annotation.
  bool _hasNonVirtualAnnotation(ExecutableElement element) {
    if (element is GetterElement && element.isSynthetic) {
      var variable = element.variable;
      if (variable != null && variable.metadata.hasNonVirtual) {
        return true;
      }
    }
    return element.metadata.hasNonVirtual;
  }

  /// Returns the list of names that belong to [interfaceElement], but are not
  /// yet declared in the class.
  List<Name> _namesToOverride(InterfaceElement interfaceElement) {
    var namesToOverride = <Name>[];
    var libraryUri = interfaceElement.library.uri;
    var memberNames = interfaceElement.interfaceMembers.keys;
    for (var name in memberNames) {
      if (name.isAccessibleFor(libraryUri)) {
        // TODO(brianwilkerson): When the user is typing the name of an
        //  inherited member, the map will contain a key matching the current
        //  prefix. If the name is the only thing typed (that is, the field
        //  declaration consists of a single identifier), and that identifier
        //  matches the name of an overridden member, then the override should
        //  still be suggested.
        var declaredElement =
            interfaceElement.getGetter(name.name) ??
            interfaceElement.getMethod(name.name) ??
            // `getSetter` accepts names without trailing `=` characters.
            interfaceElement.getSetter(name.forGetter.name);
        if (declaredElement == null) {
          namesToOverride.add(name);
        }
      }
    }
    return namesToOverride;
  }
}
