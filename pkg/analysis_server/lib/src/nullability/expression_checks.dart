// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/nullability/transitional_api.dart';
import 'package:analyzer/src/generated/source.dart';

/// Container for information gathered during nullability migration about the
/// set of runtime checks that might need to be performed on the value of an
/// expression.
///
/// TODO(paulberry): the only check we support now is [nullCheck], which checks
/// that the expression is not null.  We need to add other checks, e.g. to check
/// that a List<int?> is actually a List<int>.
class ExpressionChecks extends PotentialModification {
  @override
  final Source source;

  /// Constraint variable whose value will be `true` if this expression requires
  /// a null check.
  final CheckExpression nullCheck;

  ExpressionChecks(this.source, this.nullCheck);

  @override
  bool get isEmpty => !nullCheck.value;

  @override
  Iterable<Modification> get modifications =>
      nullCheck.value ? [Modification(nullCheck.offset, '!')] : [];
}
