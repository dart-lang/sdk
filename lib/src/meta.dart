// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Linter metadata annotations.
library linter_meta;

/// Used to annotate a lint rule `r` whose semantics are incompatible with
/// a given list of rules `r1`...`rn`.
///
/// For example, the incompatibility between `prefer_local_finals` and
/// `unnecessary_final` could be captured in the `PreferFinalLocals` class
/// declaration like this:
///
///     @IncompatibleWith(['unnecessary_final'])
///     class PreferFinalLocals extends LintRule implements NodeLintRule {
///         ...
///     }
///
/// For consistency of documentation, incompatibility should be declared in both
/// directions.  That is, all conflicting rules `r1`...`rn` should annotate
/// their incompatibility with `r`.  In this case, `'unnecessary_final'` would
/// look like this:
///
///     @IncompatibleWith(['prefer_local_finals'])
///     class UnnecessaryFinal extends LintRule implements NodeLintRule {
///         ...
///     }
///
class IncompatibleWith {
  /// A list of the ids of incompatible rules.
  final List<String> rules;

  /// Initialize a newly created instance to have the given [rules].
  const IncompatibleWith(this.rules);
}
