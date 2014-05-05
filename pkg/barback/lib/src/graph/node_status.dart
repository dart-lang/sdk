// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.graph.node_status;

/// The status of a node in barback's package graph.
///
/// A node has three possible statuses: [IDLE], [MATERIALIZING], and [RUNNING].
/// These are ordered from least dirty to most dirty; the [dirtier] and
/// [dirtiest] functions make use of this ordering.
class NodeStatus {
  /// The node has finished its work and won't do anything else until external
  /// input causes it to.
  ///
  /// For deferred nodes, this may indicate that they're finished declaring
  /// their outputs and waiting to be forced.
  static const IDLE = const NodeStatus("idle");

  /// The node has declared its outputs but their concrete values are still
  /// being generated.
  ///
  /// This is only meaningful for nodes that are or contain declaring
  /// transformers. Note that a lazy transformer that's declared its outputs but
  /// isn't actively working to generate them is considered [IDLE], not
  /// [MATERIALIZING].
  static const MATERIALIZING = const NodeStatus("materializing");

  /// The node is actively working on declaring or generating its outputs.
  ///
  /// Declaring transformers are only considered dirty until they're finished
  /// declaring their outputs; past that point, they're always either
  /// [MATERIALIZING] or [IDLE]. Non-declaring transformers, by contrast, are
  /// always either [RUNNING] or [IDLE].
  static const RUNNING = const NodeStatus("running");

  final String _name;

  /// Returns the dirtiest status in [statuses].
  static NodeStatus dirtiest(Iterable<NodeStatus> statuses) =>
      statuses.fold(NodeStatus.IDLE,
          (status1, status2) => status1.dirtier(status2));

  const NodeStatus(this._name);

  String toString() => _name;

  /// Returns [this] or [other], whichever is dirtier.
  NodeStatus dirtier(NodeStatus other) {
    if (this == RUNNING || other == RUNNING) return RUNNING;
    if (this == MATERIALIZING || other == MATERIALIZING) return MATERIALIZING;
    return IDLE;
  }
}