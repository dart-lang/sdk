// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/transitional_api.dart';

/// Container for information gathered during nullability migration about the
/// set of runtime checks that might need to be performed on the value of an
/// expression.
///
/// TODO(paulberry): the only check we support now is [nullCheck], which checks
/// that the expression is not null.  We need to add other checks, e.g. to check
/// that a List<int?> is actually a List<int>.
class ExpressionChecks extends PotentialModification {
  /// Source offset where a trailing `!` might need to be inserted.
  final int offset;

  /// Nullability node indicating whether the expression's value is nullable.
  final NullabilityNode valueNode;

  /// Nullability node indicating whether the expression's context requires a
  /// nullable value.
  final NullabilityNode contextNode;

  /// Nullability nodes guarding execution of the expression.  If any of the
  /// nodes in this list turns out to be non-nullable, the expression is dead
  /// code and will be removed by the migration tool.
  final List<NullabilityNode> guards;

  ExpressionChecks(this.offset, this.valueNode, this.contextNode,
      Iterable<NullabilityNode> guards)
      : guards = guards.toList();

  @override
  bool get isEmpty {
    for (var guard in guards) {
      if (!guard.isNullable) return true;
    }
    return !valueNode.isNullable || contextNode.isNullable;
  }

  @override
  Iterable<SourceEdit> get modifications =>
      isEmpty ? [] : [SourceEdit(offset, 0, '!')];
}
