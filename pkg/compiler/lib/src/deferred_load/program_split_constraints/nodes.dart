// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A [Node] is an abstract base class for all [Node]s parsed from json
/// constraints.
abstract class Node {}

/// A [NamedNode] is an abstract base class for all [Node]s that have a name.
abstract class NamedNode extends Node {
  final String name;

  NamedNode(this.name);
}

/// A [ReferenceNode] is a [NamedNode] with a uri and prefix.
class ReferenceNode extends NamedNode {
  final Uri uri;
  final String prefix;

  ReferenceNode(name, this.uri, this.prefix) : super(name);

  @override
  String toString() {
    return 'ReferenceNode(name=$name, uri=$uri, prefix=$prefix)';
  }
}

/// A [CombinerType] defines how to combine multiple [ReferenceNode]s in a
/// single step.
enum CombinerType { fuse, and }

/// A [CombinerNode] is a [NamedNode] with a list of [ReferenceNode] children
/// and a [CombinerType] for combining them.
class CombinerNode extends NamedNode {
  final CombinerType type;
  final Set<ReferenceNode> nodes;

  CombinerNode(name, this.type, this.nodes) : super(name);

  @override
  String toString() {
    var nodeNames = nodes.map((node) => node.name).join(', ');
    return 'CombinerNode(name=$name, type=$type, nodes=$nodeNames)';
  }
}

/// A [RelativeOrderNode] is an unnamed [Node] which defines a relative
/// load order between two [NamedNode]s.
class RelativeOrderNode extends Node {
  final NamedNode predecessor;
  final NamedNode successor;

  RelativeOrderNode({this.predecessor, this.successor}) {
    // TODO(joshualitt) make these both required parameters.
    assert(this.predecessor != null && this.successor != null);
  }

  @override
  String toString() {
    return 'RelativeOrderNode(predecessor=${predecessor.name}, '
        'successor=${successor.name})';
  }
}

/// [ConstraintData] is a data object which contains the results of parsing json
/// program split constraints.
class ConstraintData {
  final List<NamedNode> named;
  final List<RelativeOrderNode> ordered;

  ConstraintData(this.named, this.ordered);
}
