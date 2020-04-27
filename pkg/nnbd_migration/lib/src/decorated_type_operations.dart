// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/variables.dart';

/// [TypeOperations] that works with [DecoratedType]s.
class DecoratedTypeOperations
    implements TypeOperations<PromotableElement, DecoratedType> {
  final TypeSystem _typeSystem;
  final Variables _variableRepository;
  final NullabilityGraph _graph;

  DecoratedTypeOperations(
      this._typeSystem, this._variableRepository, this._graph);

  @override
  DecoratedType factor(DecoratedType from, DecoratedType what) {
    // TODO(scheglov): https://github.com/dart-lang/sdk/issues/41672
    return from;
  }

  @override
  bool isSameType(DecoratedType type1, DecoratedType type2) {
    return type1 == type2;
  }

  @override
  bool isSubtypeOf(DecoratedType leftType, DecoratedType rightType) {
    if (!_typeSystem.isSubtypeOf(leftType.type, rightType.type)) {
      // Pre-migrated types don't meet the subtype requirement.  Not a subtype.
      return false;
    } else if (rightType.node == _graph.never &&
        leftType.node != _graph.never) {
      // The "never" node will never be nullable, so not a subtype.
      return false;
    } else {
      // We don't know whether a subtype relation will hold once the graph is
      // solved.  Assume it will.
      return true;
    }
  }

  @override
  DecoratedType promoteToNonNull(DecoratedType type) {
    return type.withNode(_graph.never);
  }

  @override
  DecoratedType tryPromoteToType(DecoratedType to, DecoratedType from) {
    // TODO(paulberry): implement appropriate logic for type variable promotion.
    if (isSubtypeOf(to, from)) {
      return to;
    }

    // Allow promotion from non-null types to other types, preserving non-null.
    var keepNonNull = promoteToNonNull(to);
    if (isSubtypeOf(keepNonNull, from)) {
      return keepNonNull;
    } else {
      return null;
    }
  }

  @override
  DecoratedType variableType(PromotableElement variable) {
    return _variableRepository.decoratedElementType(variable);
  }
}
