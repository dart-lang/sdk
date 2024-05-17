// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/linter.dart';

/// Shared registry of lint rule timers.
final lintRuleTimers = LintRuleTimers();

/// Manages lint timing.
class LintRuleTimers {
  /// Dictionary mapping lints (by name) to timers.
  final Map<String, Stopwatch> timers = <String, Stopwatch>{};

  /// Get a timer associated with the given lint rule (or create one if none
  /// exists).
  Stopwatch getTimer(LintRule linter) =>
      timers.putIfAbsent(linter.name, () => Stopwatch());
}
