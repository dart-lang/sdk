// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.node_streams;

import 'dart:async';

import 'asset_node.dart';
import 'log.dart';
import 'stream_pool.dart';

/// A collection of streams that are common to nodes in barback's package graph.
class NodeStreams {
  /// A stream that emits an event whenever the node is no longer dirty.
  ///
  /// This is synchronous in order to guarantee that it will emit an event as
  /// soon as [isDirty] flips from `true` to `false`.
  Stream get onDone => onDoneController.stream;
  final onDoneController = new StreamController.broadcast(sync: true);

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

  NodeStreams() {
    onAssetPool.add(onAssetController.stream);
    onLogPool.add(onLogController.stream);
  }

  /// Closes all the streams.
  void close() {
    onDoneController.close();
    onAssetController.close();
    onAssetPool.close();
    onLogController.close();
    onLogPool.close();
  }
}
