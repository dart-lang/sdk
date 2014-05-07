// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.graph.node_streams;

import 'dart:async';

import '../asset/asset_node.dart';
import '../log.dart';
import '../utils/stream_pool.dart';
import 'node_status.dart';

/// A collection of streams that are common to nodes in barback's package graph.
class NodeStreams {
  /// A stream that emits an event every time the node's status changes.
  ///
  /// This will emit the new status. It's guaranteed to emit an event only when
  /// the status changes from the previous value. To ensure this, callers should
  /// emit status changes using [changeStatus]. The initial status is assumed to
  /// be [NodeStatus.RUNNING].
  Stream<NodeStatus> get onStatusChange => _onStatusChangeController.stream;
  final _onStatusChangeController =
      new StreamController<NodeStatus>.broadcast(sync: true);

  /// A stream that emits any new assets produced by the node.
  ///
  /// Assets are emitted synchronously to ensure that any changes are thoroughly
  /// propagated as soon as they occur.
  Stream<AssetNode> get onAsset => onAssetPool.stream;
  final onAssetPool = new StreamPool<AssetNode>.broadcast();
  final onAssetController =
      new StreamController<AssetNode>.broadcast(sync: true);

  /// A stream that emits an event whenever any the node logs an entry.
  Stream<LogEntry> get onLog => onLogPool.stream;
  final onLogPool = new StreamPool<LogEntry>.broadcast();
  final onLogController = new StreamController<LogEntry>.broadcast(sync: true);

  var _previousStatus = NodeStatus.RUNNING;

  /// Whether [this] has been closed.
  bool get isClosed => onAssetController.isClosed;

  NodeStreams() {
    onAssetPool.add(onAssetController.stream);
    onLogPool.add(onLogController.stream);
  }

  /// Emits a status change notification via [onStatusChange].
  ///
  /// This guarantees that a change notification won't be emitted if the status
  /// didn't actually change.
  void changeStatus(NodeStatus status) {
    if (_previousStatus != status) _onStatusChangeController.add(status);
  }

  /// Closes all the streams.
  void close() {
    _onStatusChangeController.close();
    onAssetController.close();
    onAssetPool.close();
    onLogController.close();
    onLogPool.close();
  }
}
