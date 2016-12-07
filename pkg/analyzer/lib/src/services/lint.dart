// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.services.lint;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/generated/engine.dart';

/// Shared lint registry.
LintRegistry lintRegistry = new LintRegistry();

/// Return lints associated with this [context], or an empty list if there are
/// none.
List<Linter> getLints(AnalysisContext context) =>
    context.analysisOptions.lintRules;

/// Associate these [lints] with the given [context].
void setLints(AnalysisContext context, List<Linter> lints) {
  AnalysisOptionsImpl options =
      new AnalysisOptionsImpl.from(context.analysisOptions);
  options.lintRules = lints;
  context.analysisOptions = options;
}

/// Implementers contribute lint warnings via the provided error [reporter].
abstract class Linter {
  /// Used to report lint warnings.
  /// NOTE: this is set by the framework before visit begins.
  ErrorReporter reporter;

  /**
   * Return the lint code associated with this linter.
   */
  LintCode get lintCode => null;

  /// Linter name.
  String get name;

  /// Return a visitor to be passed to compilation units to perform lint
  /// analysis.
  /// Lint errors are reported via this [Linter]'s error [reporter].
  AstVisitor getVisitor();
}

/// Manages lint timing.
class LintRegistry {
  /// Dictionary mapping lints (by name) to timers.
  final Map<String, Stopwatch> timers = new HashMap<String, Stopwatch>();

  /// Get a timer associated with the given lint rule (or create one if none
  /// exists).
  Stopwatch getTimer(Linter linter) =>
      timers.putIfAbsent(linter.name, () => new Stopwatch());
}
