// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/nullability/unit_propagation.dart';

/// Container for information gathered during nullability migration about the
/// set of runtime checks that might need to be performed on the value of an
/// expression.
///
/// TODO(paulberry): the only check we support now is [notNull], which checks
/// that the expression is not null.  We need to add other checks, e.g. to check
/// that a List<int?> is actually a List<int>.
class ExpressionChecks {
  /// Constraint variable whose value will be `true` if this expression requires
  /// a null check.
  final ConstraintVariable notNull;

  ExpressionChecks(this.notNull);
}
