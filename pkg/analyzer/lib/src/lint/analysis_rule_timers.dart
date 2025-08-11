// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/analysis_rule/rule_context.dart';

/// Shared registry of analysis rule timers.
final analysisRuleTimers = AnalysisRuleTimers();

/// Manages analysis rule timing.
class AnalysisRuleTimers {
  /// Dictionary mapping rules (by name) to timers.
  final Map<String, Stopwatch> timers = <String, Stopwatch>{};

  /// Get a timer associated with the given analysis rule (or create one if none
  /// exists).
  Stopwatch getTimer(AbstractAnalysisRule linter) =>
      timers.putIfAbsent(linter.name, () => Stopwatch());
}
