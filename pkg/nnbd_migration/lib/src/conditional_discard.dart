// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/nullability_node.dart';

/// Container for information gathered during nullability migration about a
/// conditional check that might need to be discarded.
///
/// This information will be associated with an Expression in the input program
/// whose boolean value influences control flow (e.g. the condition of an `if`
/// statement).
///
/// TODO(paulberry): simplify this once PotentialModification is no longer
/// needed.
class ConditionalDiscard {
  /// Nullability node that will be `nullable` if the code path that results
  /// from the condition evaluating to `true` will be reachable after
  /// nullability migration, and therefore should be kept.
  ///
  /// `null` if the code path should be kept regardless of the outcome of
  /// migration.
  final NullabilityNode trueGuard;

  /// Nullability node that will be `nullable` if the code path that results
  /// from the condition evaluating to `false` will be reachable after
  /// nullability migration, and therefore should be kept.
  ///
  /// `null` if the code path should be kept regardless of the outcome of
  /// migration.
  final NullabilityNode falseGuard;

  /// Indicates whether the condition is pure (free from side effects).
  ///
  /// For example, a condition like `x == null` is pure (assuming `x` is a local
  /// variable or static variable), because evaluating it has no user-visible
  /// effect other than returning a boolean value.
  ///
  /// If [pureCondition] is `false`, and either [trueGuard] or [falseGuard] is
  /// `false`, that it is safe to delete the condition expression as well as the
  /// dead code branch (e.g. it means that `if (x == null) f(); else g();` could
  /// be changed to simply `g();`).
  final bool pureCondition;

  ConditionalDiscard(this.trueGuard, this.falseGuard, this.pureCondition);

  /// Indicates whether the code path that results from the condition evaluating
  /// to `false` is reachable after migration.
  bool get keepFalse => falseGuard == null || falseGuard.isNullable;

  /// Indicates whether the code path that results from the condition evaluating
  /// to `true` is reachable after migration.
  bool get keepTrue => trueGuard == null || trueGuard.isNullable;

  FixReasonInfo get reason => !keepTrue ? trueGuard : falseGuard;
}
