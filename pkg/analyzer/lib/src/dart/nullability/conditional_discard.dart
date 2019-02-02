// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/nullability/unit_propagation.dart';

/// Container for information gathered during nullability migration about a
/// conditional check that might need to be discarded.
///
/// This information will be associated with an Expression in the input program
/// whose boolean value influences control flow (e.g. the condition of an `if`
/// statement).
class ConditionalDiscard {
  /// Constraint variable whose value will be `true` if the code path that
  /// results from the condition evaluating to `true` will be reachable after
  /// nullability migration, and therefore should be kept.
  final ConstraintVariable keepTrue;

  /// Constraint variable whose value will be `false` if the code path that
  /// results from the condition evaluating to `false` will be reachable after
  /// nullability migration, and therefore should be kept.
  final ConstraintVariable keepFalse;

  /// Indicates whether the condition is pure (free from side effects).
  ///
  /// For example, a condition like `x == null` is pure (assuming `x` is a local
  /// variable or static variable), because evaluating it has no user-visible
  /// effect other than returning a boolean value.
  ///
  /// If [pureCondition] is `false`, and either [keepTrue] or [keepFalse] is
  /// `false`, that it is safe to delete the condition expression as well as the
  /// dead code branch (e.g. it means that `if (x == null) f(); else g();` could
  /// be changed to simply `g();`).
  final bool pureCondition;

  ConditionalDiscard(this.keepTrue, this.keepFalse, this.pureCondition);
}
