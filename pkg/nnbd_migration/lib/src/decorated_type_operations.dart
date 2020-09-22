// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edge_origin.dart';
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
  TypeClassification classifyType(DecoratedType type) {
    if (type.type.isDartCoreNull) {
      return TypeClassification.nullOrEquivalent;
    } else {
      return TypeClassification.potentiallyNullable;
    }
  }

  @override
  DecoratedType factor(DecoratedType from, DecoratedType what) {
    // TODO(scheglov): https://github.com/dart-lang/sdk/issues/41672
    return from;
  }

  @override
  bool forcePromotion(DecoratedType to, DecoratedType from,
      List<DecoratedType> promotedTypes, List<DecoratedType> newPromotedTypes) {
    assert(to != null);
    assert(from != null);
    // Do not force promotion if it appears that the element's type was just
    // demoted.
    if (promotedTypes != null &&
        (newPromotedTypes == null ||
            newPromotedTypes.length < promotedTypes.length)) {
      return false;
    }
    if (!isSubtypeOf(to, from)) {
      return false;
    }
    var fromSources = from.node.upstreamEdges;
    // Do not force promotion if [to] already points to [from].
    if (fromSources.length == 1 && fromSources.single.sourceNode == to.node) {
      return false;
    }
    return true;
  }

  @override
  bool isNever(DecoratedType type) {
    return false;
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
  // This function walks [chain1] and [chain2], creating an intersection similar
  // to that of [VariableModel.joinPromotedTypes].
  List<DecoratedType> refinePromotedTypes(List<DecoratedType> chain1,
      List<DecoratedType> chain2, List<DecoratedType> promotedTypes) {
    if (chain1 == null || chain2 == null) return promotedTypes;

    // This method can only handle very simple joins.
    if (chain1.length != chain2.length) return promotedTypes;

    // The promotion chains were intersected without any promotions being
    // dropped. There is nothing to do here.
    if (promotedTypes != null && promotedTypes.length == chain1.length) {
      return promotedTypes;
    }

    var result = <DecoratedType>[];
    int index = 0;
    while (index < chain1.length) {
      if (!isSameType(chain1[index], chain2[index])) {
        break;
      }
      result.add(chain1[index]);
      index++;
    }

    if (index != chain1.length - 1) {
      // This method can only handle the situation in which the promotion chains
      // are identical up to the last node. If we are not in such situation,
      // return the previous result.
      return promotedTypes;
    }

    DecoratedType firstType = chain1[index];
    DecoratedType secondType = chain2[index];

    var node = NullabilityNode.forGLB();
    var origin =
        // TODO(srawlins): How to get the source or astNode from within here...
        GreatestLowerBoundOrigin(null /* source */, null /* astNode */);
    _graph.connect(firstType.node, node, origin, guards: [secondType.node]);
    _graph.connect(node, firstType.node, origin);
    _graph.connect(node, secondType.node, origin);

    return result..add(firstType.withNode(node));
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
