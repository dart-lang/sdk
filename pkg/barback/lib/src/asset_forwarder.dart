// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset_forwarder;

import 'dart:async';

import 'asset_node.dart';

/// A wrapper for an [AssetNode] that forwards events to a new node.
///
/// A forwarder is used when a class wants to forward an [AssetNode] that it
/// gets as an input, but also wants to have control over when that node is
/// marked as removed. The forwarder can be closed, thus removing its output
/// node, without the original node having been removed.
class AssetForwarder {
  /// The subscription on the input node.
  StreamSubscription _subscription;

  /// The controller for the output node.
  final AssetNodeController _controller;

  /// The node to which events are forwarded.
  AssetNode get node => _controller.node;

  AssetForwarder(AssetNode node)
      : _controller = new AssetNodeController.from(node) {
    if (node.state.isRemoved) return;

    _subscription = node.onStateChange.listen((state) {
      if (state.isAvailable) {
        _controller.setAvailable(node.asset);
      } else if (state.isDirty) {
        _controller.setDirty();
      } else {
        assert(state.isRemoved);
        close();
      }
    });
  }

  /// Closes the forwarder and marks [node] as removed.
  void close() {
    if (_controller.node.state.isRemoved) return;
    _subscription.cancel();
    _controller.setRemoved();
  }
}
