// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/edge_origin.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/potential_modification.dart';

/// Container for information gathered during nullability migration about the
/// set of runtime checks that might need to be performed on the value of an
/// expression.
///
/// TODO(paulberry): we don't currently have any way of distinguishing checks
/// based on the nullability of the type itself (which can be checked by adding
/// a trailing `!`) from checks based on type parameters (which will have to be
/// checked using an `as` expression).
class ExpressionChecks extends PotentialModification {
  /// Source offset where a trailing `!` might need to be inserted.
  final int offset;

  /// List of all nullability edges that are related to this potential check.
  ///
  /// TODO(paulberry): update this data structure to keep track of all the ways
  /// in which edges can be related to an [ExpressionChecks], including:
  ///
  /// - An edge which, if unsatisfied, indicates that the expression needs to be
  ///   null-checked.
  /// - An edge which, if unsatisfied, indicates that a type parameter of the
  ///   expression needs to be checked for nullability (e.g. by the migration
  ///   engine inserting a test like `as List<int>?`)
  /// - An edge which, if unsatisfied, indicates that a return type of the
  ///   expression needs to be checked for nullability (e.g. by the migration
  ///   engine inserting a test like `as int Function(...)?`)
  /// - An edge which, if unsatisfied, indicates that a parameter type of the
  ///   expression needs to be checked for nullability (e.g. by the migration
  ///   engine inserting a test like `as void Function(int?)?`)
  ///
  /// ...and so on.
  final List<NullabilityEdge> edges = [];

  ExpressionChecks(this.offset);

  @override
  NullabilityFixDescription get description =>
      NullabilityFixDescription.checkExpression;

  @override
  bool get isEmpty {
    for (var edge in edges) {
      if (!edge.isSatisfied) return false;
    }
    return true;
  }

  @override
  Iterable<SourceEdit> get modifications {
    // TODO(paulberry): this assumes that the check that needs to be done is for
    // the nullability of the type itself (in which case all we need is a simple
    // null check).  Need to support checks that will have to be addressed by
    // adding an `as` expression, e.g. `as List<int>?` to verify that a list is
    // reified to contain only non-null ints.
    return isEmpty ? [] : [SourceEdit(offset, 0, '!')];
  }

  @override
  Iterable<FixReasonInfo> get reasons sync* {
    for (var edge in edges) {
      if (!edge.isSatisfied) yield edge;
    }
  }
}

/// [EdgeOrigin] object associated with [ExpressionChecks].  This is a separate
/// object so that it can safely store a pointer to an AST node.  (We don't want
/// to store pointers to AST nodes in [ExpressionChecks] objects because they
/// are persisted for the duration of the migration calculation).
class ExpressionChecksOrigin extends EdgeOrigin {
  final ExpressionChecks checks;

  ExpressionChecksOrigin(Source source, Expression node, this.checks)
      : super(source, node);

  @override
  String get description => 'data flow';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.expressionChecks;
}
