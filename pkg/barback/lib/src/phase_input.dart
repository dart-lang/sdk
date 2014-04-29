// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.phase_input;

import 'dart:async';

import 'asset_forwarder.dart';
import 'asset_node.dart';
import 'log.dart';
import 'node_status.dart';
import 'node_streams.dart';
import 'phase.dart';
import 'transform_node.dart';
import 'transformer.dart';

/// A class for watching a single [AssetNode] and running any transforms that
/// take that node as a primary input.
class PhaseInput {
  /// The phase for which this is an input.
  final Phase _phase;

  /// A string describing the location of [this] in the transformer graph.
  final String _location;

  /// The transforms currently applicable to [input].
  ///
  /// These are the transforms that have been "wired up": they represent a
  /// repeatable transformation of a single concrete set of inputs. "dart2js" is
  /// a transformer. "dart2js on web/main.dart" is a transform.
  final _transforms = new Set<TransformNode>();

  /// A forwarder for the input [AssetNode] for this phase.
  ///
  /// This is used to mark the node as removed should the input ever be removed.
  final AssetForwarder _inputForwarder;

  /// The asset node for this input.
  AssetNode get input => _inputForwarder.node;

  /// The subscription to [input]'s [AssetNode.onStateChange] stream.
  StreamSubscription _inputSubscription;

  /// The streams exposed by this input.
  final _streams = new NodeStreams();
  Stream get onStatusChange => _streams.onStatusChange;
  Stream<AssetNode> get onAsset => _streams.onAsset;
  Stream<LogEntry> get onLog => _streams.onLog;

  /// How far along [this] is in processing its assets.
  NodeStatus get status {
    var status = input.state.isDirty && !input.deferred ?
        NodeStatus.MATERIALIZING : NodeStatus.IDLE;
    return status.dirtier(NodeStatus.dirtiest(
        _transforms.map((transform) => transform.status)));
  }

  PhaseInput(this._phase, AssetNode input, this._location)
      : _inputForwarder = new AssetForwarder(input) {
    _inputSubscription = input.onStateChange.listen((state) {
      if (state.isRemoved) {
        remove();
      } else {
        _streams.changeStatus(status);
      }
    });
  }

  /// Removes this input.
  ///
  /// This marks all outputs of the input as removed.
  void remove() {
    _streams.close();
    _inputSubscription.cancel();
    _inputForwarder.close();
  }

  /// Set this input's transformers to [transformers].
  void updateTransformers(Iterable<Transformer> newTransformersIterable) {
    var newTransformers = newTransformersIterable.toSet();
    for (var transform in _transforms.toList()) {
      if (newTransformers.remove(transform.transformer)) continue;
      transform.remove();
    }

    // The remaining [newTransformers] are those for which there are no
    // transforms in [_transforms].
    for (var transformer in newTransformers) {
      var transform = new TransformNode(
          _phase, transformer, input, _location);
      _transforms.add(transform);

      transform.onStatusChange.listen(
          (_) => _streams.changeStatus(status),
          onDone: () => _transforms.remove(transform));

      _streams.onAssetPool.add(transform.onAsset);
      _streams.onLogPool.add(transform.onLog);
    }
  }

  /// Force all [LazyTransformer]s' transforms in this input to begin producing
  /// concrete assets.
  void forceAllTransforms() {
    for (var transform in _transforms) {
      transform.force();
    }
  }

  String toString() => "phase input in $_location for $input";
}
