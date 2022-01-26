// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'nodes.dart';

import '../../elements/entities.dart';

/// A [Constraint] is a node in a constraint graph which wraps an
/// [ImportEntity].
class Constraint {
  /// The name of the [NamedNode] this [Constraint] was created to
  /// represent.
  final String name;

  /// The [CombinerType] which should be used to combine [imports]. Either
  /// [imports] will be a singleton, or [combinerType] will be non-null.
  final CombinerType combinerType;

  /// The [ImportEntity]s underlying this [Constraint].
  final Set<ImportEntity> imports;

  /// Imports which load after [import].
  final Set<Constraint> successors = {};

  /// Imports which load before [import].
  final Set<Constraint> predecessors = {};

  /// Whether or not this [Constraint] should always apply transitions as
  /// opposed to conditionally applying transitions.
  bool get alwaysApplyTransitions {
    return combinerType == null || combinerType == CombinerType.and;
  }

  Constraint(this.name, this.imports, this.combinerType) {
    assert((this.imports.length == 1 && combinerType == null) ||
        (this.imports.length > 1 && combinerType != null));
  }

  @override
  String toString() {
    var predecessorNames =
        predecessors.map((constraint) => constraint.name).join(', ');
    var successorNames =
        successors.map((constraint) => constraint.name).join(', ');
    return 'Constraint(imports=$imports, predecessors={$predecessorNames}, '
        'successors={$successorNames})';
  }
}

/// [_WorkItem] is an private class used to compute the transitive closure of
/// transitions.
class _WorkItem {
  /// The [Constraint] to process.
  final Constraint child;

  /// The set of [ImportEntity]s guaranteed to be loaded after [child]
  /// transitively.
  final Set<ImportEntity> transitiveChildren;

  _WorkItem(this.child, {this.transitiveChildren = const {}});
}

/// [Builder] is converts parsed [Node] objects into transitions which
/// can be applied while splitting a program.
class Builder {
  /// The [ConstraintData] object which result from parsing json constraints.
  final ConstraintData nodes;

  Builder(this.nodes);

  /// Builds [ProgramSplitConstraints]  which can be applied by an
  /// [ImportSetLattice] when generating [ImportSet]s.
  ProgramSplitConstraints build(Iterable<ImportEntity> imports) {
    // 1) Create a map of uri#prefix to [ImportEntity].
    Map<Uri, Map<String, ImportEntity>> importsByUriAndPrefix = {};
    for (var import in imports) {
      var libraryUri = import.enclosingLibraryUri;
      var prefix = import.name;
      var uriNodes = importsByUriAndPrefix[libraryUri] ??= {};
      uriNodes[prefix] = import;
    }

    // A helper function for looking up an [ImportEntity] from a
    // [ReferenceNode].
    ImportEntity _lookupReference(ReferenceNode node) {
      var uri = node.uri;
      if (!importsByUriAndPrefix.containsKey(uri)) {
        throw 'Uri for constraint not found $uri';
      }
      var prefix = node.prefix;
      if (!importsByUriAndPrefix[uri].containsKey(prefix)) {
        throw 'Prefix: $prefix not found for uri: $uri';
      }
      return importsByUriAndPrefix[uri][prefix];
    }

    // 2) Create a [Constraint] for each [NamedNode]. Also,
    // index each [Constraint] by [NamedNode].
    Map<NamedNode, Constraint> nodeToConstraintMap = {};
    for (var constraint in nodes.named) {
      CombinerType combinerType = null;
      Set<ImportEntity> imports = {};
      if (constraint is ReferenceNode) {
        imports.add(_lookupReference(constraint));
      } else if (constraint is CombinerNode) {
        combinerType = constraint.type;
        for (var child in constraint.nodes) {
          imports.add(_lookupReference(child));
        }
      } else {
        throw 'Unexpected Node Type $constraint';
      }

      nodeToConstraintMap[constraint] =
          Constraint(constraint.name, imports, combinerType);
    }

    // 3) Build a graph of [Constraint]s by processing user constraints and
    // intializing each [Constraint]'s predecessor / successor members.
    void createEdge(NamedNode successorNode, NamedNode predecessorNode) {
      var successor = nodeToConstraintMap[successorNode];
      var predecessor = nodeToConstraintMap[predecessorNode];
      successor.predecessors.add(predecessor);
      predecessor.successors.add(successor);
    }

    for (var constraint in nodes.ordered) {
      if (constraint is RelativeOrderNode) {
        createEdge(constraint.successor, constraint.predecessor);
      } else if (constraint is FuseNode) {
        // Fuse nodes are just syntactic sugar for generating cycles in the
        // ordering graph.
        for (var node1 in constraint.nodes) {
          for (var node2 in constraint.nodes) {
            if (node1 != node2) {
              createEdge(node1, node2);
            }
          }
        }
      }
    }

    // 4) Compute the transitive closure of constraints. This gives us a map of
    // transitiveTransitions, where each key is a parent [ImportEntity] and each
    // value represents the transitive set of child [ImportEntity]s which are
    // always loaded after the parent.
    Map<ImportEntity, Set<ImportEntity>> singletonTransitions = {};
    Map<Constraint, SetTransition> setTransitions = {};
    Map<Constraint, Set<ImportEntity>> processed = {};
    Queue<_WorkItem> queue = Queue.from(nodeToConstraintMap.values
        .where((node) => node.successors.isEmpty)
        .map((node) => _WorkItem(node)));
    while (queue.isNotEmpty) {
      var item = queue.removeFirst();
      var constraint = item.child;
      var imports = constraint.imports;

      // Update [transitiveTransitions] with reachable transitions for this
      // [_WorkItem]
      var transitiveChildren = item.transitiveChildren;

      // We only add singletonTransitions for a given [ImportEntity] when it is
      // guaranteed to dominate another [ImportEntity]. Some nodes such as 'or'
      // nodes do not have this property.
      if (constraint.alwaysApplyTransitions) {
        for (var import in imports) {
          // We insert an implicit 'self' transition for every import.
          var transitions = singletonTransitions[import] ??= {import};
          transitions.addAll(transitiveChildren);
        }
      } else {
        assert(constraint.combinerType == CombinerType.or);
        var setTransition =
            setTransitions[constraint] ??= SetTransition(constraint.imports);
        setTransition.transitions.addAll(transitiveChildren);
      }

      // Propagate constraints transitively to the parent.
      var predecessorTransitiveChildren = {
        ...imports,
        ...transitiveChildren,
      };
      for (var predecessor in constraint.predecessors) {
        // We allow cycles in the constraint graph, so we need to support
        // reprocessing constraints when we need to consider new transitive
        // children.
        if (processed.containsKey(predecessor) &&
            processed[predecessor].containsAll(predecessorTransitiveChildren)) {
          continue;
        }
        (processed[predecessor] ??= {}).addAll(predecessorTransitiveChildren);
        queue.add(_WorkItem(predecessor,
            transitiveChildren: predecessorTransitiveChildren));
      }
    }
    return ProgramSplitConstraints(
        singletonTransitions, setTransitions.values.toList());
  }
}

/// A [SetTransition] is a set of [ImportEntity] transitions which can only be
/// applied when all of the [ImportEntity]s in a given [source] are present in a
/// given [ImportSet].
class SetTransition {
  /// The [Set<ImportEntity>] which, if present in a given [ImportSet] means
  /// [transitions] should be applied.
  final Set<ImportEntity> source;

  /// The [Set<ImportEntity>] which is applied if [source] is present in a
  /// given [ImportSet].
  final Set<ImportEntity> transitions = {};

  SetTransition(this.source);
}

/// [ProgramSplitConstraints] is a holder for transitions which should be
/// applied while splitting a program.
class ProgramSplitConstraints {
  /// Transitions which apply when a singleton [ImportEntity] is present.
  final Map<ImportEntity, Set<ImportEntity>> singletonTransitions;

  /// Transitions which apply only when a set of [ImportEntity]s is present.
  final List<SetTransition> setTransitions;

  ProgramSplitConstraints(this.singletonTransitions, this.setTransitions);
}
