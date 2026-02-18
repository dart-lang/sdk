// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:kernel/ast.dart' show Library, LibraryDependency;

import 'nodes.dart';
import '../../elements/entities.dart';

/// A [Constraint] is a node in a constraint graph which wraps a
/// [T] (which is either a [ImportEntity] or a [LibraryDependency]).
class Constraint<T extends Object> {
  /// The name of the [NamedNode] this [Constraint] was created to
  /// represent.
  final String name;

  /// The [CombinerType] which should be used to combine [imports]. Either
  /// [imports] will be a singleton, or [combinerType] will be non-null.
  final CombinerType? combinerType;

  /// The [T]s underlying this [Constraint].
  final Set<T> imports;

  /// Imports which load after [import].
  final Set<Constraint<T>> successors = {};

  /// Imports which load before [import].
  final Set<Constraint<T>> predecessors = {};

  /// Whether or not this [Constraint] should always apply transitions as
  /// opposed to conditionally applying transitions.
  bool get alwaysApplyTransitions {
    return combinerType == null || combinerType == CombinerType.and;
  }

  Constraint(this.name, this.imports, this.combinerType) {
    assert(
      (imports.length == 1 && combinerType == null) ||
          (imports.length > 1 && combinerType != null),
    );
  }

  @override
  String toString() {
    var predecessorNames = predecessors
        .map((constraint) => constraint.name)
        .join(', ');
    var successorNames = successors
        .map((constraint) => constraint.name)
        .join(', ');
    return 'Constraint(imports=$imports, predecessors={$predecessorNames}, '
        'successors={$successorNames})';
  }
}

/// [_WorkItem] is an private class used to compute the transitive closure of
/// transitions.
class _WorkItem<T extends Object> {
  /// The [Constraint] to process.
  final Constraint<T> child;

  /// The set of deferred imports guaranteed to be loaded after [child]
  /// transitively.
  final Set<T> transitiveChildren;

  _WorkItem(this.child, {this.transitiveChildren = const {}});
}

/// [_Builder] is converts parsed [Node] objects into transitions which
/// can be applied while splitting a program.
abstract class _Builder<T extends Object> {
  /// The [ConstraintData] object which result from parsing json constraints.
  final ConstraintData nodes;

  _Builder(this.nodes);

  /// Builds [ProgramSplitConstraints]  which can be applied by an
  /// [ImportSetLattice] when generating [ImportSet]s.
  ProgramSplitConstraints<T> build(Iterable<T> imports) {
    // 1) Create a map of uri#prefix to [T].
    Map<Uri, Map<String, T>> importsByUriAndPrefix = {};
    for (var import in imports) {
      var libraryUri = importUriOf(import);
      var prefix = prefixNameOf(import);
      Map<String, T> uriNodes = importsByUriAndPrefix[libraryUri] ??= {};
      uriNodes[prefix] = import;
    }

    // A helper function for looking up an [T] from a
    // [ReferenceNode].
    T lookupReference(ReferenceNode node) {
      var uri = node.uri;
      if (!importsByUriAndPrefix.containsKey(uri)) {
        throw 'Uri for constraint not found $uri';
      }
      var prefix = node.prefix;
      if (!importsByUriAndPrefix[uri]!.containsKey(prefix)) {
        throw 'Prefix: $prefix not found for uri: $uri';
      }
      return importsByUriAndPrefix[uri]![prefix]!;
    }

    // 2) Create a [Constraint] for each [NamedNode]. Also,
    // index each [Constraint] by [NamedNode].
    Map<NamedNode, Constraint<T>> nodeToConstraintMap = {};
    for (var constraint in nodes.named) {
      CombinerType? combinerType;
      Set<T> imports = {};
      if (constraint is ReferenceNode) {
        imports.add(lookupReference(constraint));
      } else if (constraint is CombinerNode) {
        combinerType = constraint.type;
        for (var child in constraint.nodes) {
          imports.add(lookupReference(child));
        }
      } else {
        throw 'Unexpected Node Type $constraint';
      }

      nodeToConstraintMap[constraint] = Constraint(
        constraint.name,
        imports,
        combinerType,
      );
    }

    // 3) Build a graph of [Constraint]s by processing user constraints and
    // initializing each [Constraint]'s predecessor / successor members.
    void createEdge(NamedNode successorNode, NamedNode predecessorNode) {
      var successor = nodeToConstraintMap[successorNode]!;
      var predecessor = nodeToConstraintMap[predecessorNode]!;
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
    // transitiveTransitions, where each key is a parent deferred import and each
    // value represents the transitive set of child deferred imports which are
    // always loaded after the parent.
    Map<T, Set<T>> singletonTransitions = {};
    Map<Constraint, SetTransition<T>> setTransitions = {};
    Map<Constraint, Set<T>> processed = {};
    Queue<_WorkItem<T>> queue = Queue.from(
      nodeToConstraintMap.values.map((node) => _WorkItem(node)),
    );
    while (queue.isNotEmpty) {
      var item = queue.removeFirst();
      var constraint = item.child;
      var imports = constraint.imports;

      // Update [transitiveTransitions] with reachable transitions for this
      // [_WorkItem]
      var transitiveChildren = item.transitiveChildren;

      // We only add singletonTransitions for a given deferred import when it is
      // guaranteed to dominate another deferred import. Some nodes such as 'or'
      // nodes do not have this property.
      if (constraint.alwaysApplyTransitions) {
        for (var import in imports) {
          // We insert an implicit 'self' transition for every import.
          var transitions = singletonTransitions[import] ??= {import};
          transitions.addAll(transitiveChildren);
        }
      } else {
        assert(constraint.combinerType == CombinerType.or);
        var setTransition = setTransitions[constraint] ??= SetTransition(
          constraint.imports,
        );
        setTransition.transitions.addAll(transitiveChildren);
      }

      // Propagate constraints transitively to the parent.
      var predecessorTransitiveChildren = {...imports, ...transitiveChildren};
      for (var predecessor in constraint.predecessors) {
        // We allow cycles in the constraint graph, so we need to support
        // reprocessing constraints when we need to consider new transitive
        // children.
        if (processed.containsKey(predecessor) &&
            processed[predecessor]!.containsAll(
              predecessorTransitiveChildren,
            )) {
          continue;
        }
        (processed[predecessor] ??= {}).addAll(predecessorTransitiveChildren);
        queue.add(
          _WorkItem(
            predecessor,
            transitiveChildren: predecessorTransitiveChildren,
          ),
        );
      }
    }
    return ProgramSplitConstraints(
      singletonTransitions,
      setTransitions.values.toList(),
    );
  }

  Uri importUriOf(T import);
  String prefixNameOf(T import);
}

class Dart2JsBuilder extends _Builder<ImportEntity> {
  Dart2JsBuilder(super.nodes);

  @override
  Uri importUriOf(ImportEntity import) => import.enclosingLibraryUri;

  @override
  String prefixNameOf(ImportEntity import) => import.name!;
}

class KernelBuilder extends _Builder<LibraryDependency> {
  KernelBuilder(super.nodes);

  @override
  Uri importUriOf(LibraryDependency import) =>
      (import.parent as Library).importUri;

  @override
  String prefixNameOf(LibraryDependency import) => import.name!;
}

/// A [SetTransition] is a set of [T] transitions which can only be
/// applied when all of the [T]s in a given [source] are present in a
/// given [ImportSet].
class SetTransition<T extends Object> {
  /// The [Set<T>] which, if present in a given [ImportSet] means
  /// [transitions] should be applied.
  final Set<T> source;

  /// The [Set<T>] which is applied if [source] is present in a
  /// given [ImportSet].
  final Set<T> transitions = {};

  SetTransition(this.source);
}

/// [ProgramSplitConstraints] is a holder for transitions which should be
/// applied while splitting a program.
class ProgramSplitConstraints<T extends Object> {
  /// Transitions which apply when a singleton [T] is present.
  final Map<T, Set<T>> singletonTransitions;

  /// Transitions which apply only when a set of [T]s is present.
  final List<SetTransition<T>> setTransitions;

  ProgramSplitConstraints(this.singletonTransitions, this.setTransitions);
}
