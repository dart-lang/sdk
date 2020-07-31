// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/fix_reason_target.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/edge_origin.dart';
import 'package:nnbd_migration/src/nullability_node.dart';

/// Container for information gathered during nullability migration about the
/// set of runtime checks that might need to be performed on the value of an
/// expression.
///
/// TODO(paulberry): we don't currently have any way of distinguishing checks
/// based on the nullability of the type itself (which can be checked by adding
/// a trailing `!`) from checks based on type parameters (which will have to be
/// checked using an `as` expression).
class ExpressionChecks {
  /// All nullability edges that are related to this potential check.
  final Map<FixReasonTarget, NullabilityEdge> edges = {};

  ExpressionChecks();
}

/// [EdgeOrigin] object associated with [ExpressionChecks].  This is a separate
/// object so that it can safely store a pointer to an AST node.  (We don't want
/// to store pointers to AST nodes in [ExpressionChecks] objects because they
/// are persisted for the duration of the migration calculation).
class ExpressionChecksOrigin extends EdgeOrigin {
  final ExpressionChecks checks;

  /// Whether the origin of the edge is due to the assignment of a variable
  /// from within function literal argument to the `setUp` function of the test
  /// package.
  final bool isSetupAssignment;

  ExpressionChecksOrigin(Source source, Expression node, this.checks,
      {this.isSetupAssignment = false})
      : super(source, node);

  @override
  String get description => 'data flow';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.expressionChecks;
}
