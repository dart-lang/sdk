// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/completion_state.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_collector.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';

/// A helper class that produces candidate suggestions for overrides of
/// inherited methods.
class OverrideHelper {
  /// The state used to compute the candidate suggestions.
  final CompletionState state;

  /// The suggestion collector to which suggestions will be added.
  final SuggestionCollector collector;

  /// The inheritance manager used to compute the set of methods that can be
  /// overridden.
  final InheritanceManager3 inheritanceManager;

  /// Initialize a newly created helper to add suggestions to the [collector].
  OverrideHelper({required this.state, required this.collector})
      : inheritanceManager = state.request.inheritanceManager;

  void computeOverridesFor({
    required InterfaceElement interfaceElement,
    required SourceRange replacementRange,
    required bool skipAt,
  }) {
    var interface = inheritanceManager.getInterface(interfaceElement);
    var interfaceMap = interface.map;
    var namesToOverride =
        _namesToOverride(interfaceElement.librarySource.uri, interface);

    // Build suggestions
    for (var name in namesToOverride) {
      var element = interfaceMap[name];
      // Gracefully degrade if the overridden element has not been resolved.
      if (element != null) {
        var invokeSuper = interface.isSuperImplemented(name);
        var matcherScore = math.max(
            math.max(state.matcher.score('override'),
                state.matcher.score('operator')),
            state.matcher.score(element.displayName));
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

  /// Return the list of names that belong to the [interface] of a class, but
  /// are not yet declared in the class.
  List<Name> _namesToOverride(Uri libraryUri, Interface interface) {
    var namesToOverride = <Name>[];
    for (var name in interface.map.keys) {
      if (name.isAccessibleFor(libraryUri)) {
        // TODO(brianwilkerson): When the user is typing the name of an
        //  inherited member, the map will contain a key matching the current
        //  prefix. If the name is the only thing typed (that is, the field
        //  declaration consists of a single identifier), and that identifier
        //  matches the name of an overridden member, then the override should
        //  still be suggested.
        if (!interface.declared.containsKey(name)) {
          namesToOverride.add(name);
        }
      }
    }
    return namesToOverride;
  }
}
