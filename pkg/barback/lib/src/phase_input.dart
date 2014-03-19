// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.phase_input;

import 'dart:async';

import 'asset_forwarder.dart';
import 'asset_node.dart';
import 'log.dart';
import 'phase.dart';
import 'stream_pool.dart';
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

  /// A stream that emits an event whenever [this] is no longer dirty.
  ///
  /// This is synchronous in order to guarantee that it will emit an event as
  /// soon as [isDirty] flips from `true` to `false`.
  Stream get onDone => _onDoneController.stream;
  final _onDoneController = new StreamController.broadcast(sync: true);

  /// A stream that emits any new assets emitted by [this].
  ///
  /// Assets are emitted synchronously to ensure that any changes are thoroughly
  /// propagated as soon as they occur.
  Stream<AssetNode> get onAsset => _onAssetPool.stream;
  final _onAssetPool = new StreamPool<AssetNode>.broadcast();

  /// Whether [this] is dirty and still has more processing to do.
  bool get isDirty => _transforms.any((transform) => transform.isDirty);

  /// A stream that emits an event whenever any transforms that use [input] as
  /// their primary input log an entry.
  Stream<LogEntry> get onLog => _onLogPool.stream;
  final _onLogPool = new StreamPool<LogEntry>.broadcast();

  PhaseInput(this._phase, AssetNode input, this._location)
      : _inputForwarder = new AssetForwarder(input) {
    input.whenRemoved(remove);
  }

  /// Removes this input.
  ///
  /// This marks all outputs of the input as removed.
  void remove() {
    _onDoneController.close();
    _onAssetPool.close();
    _onLogPool.close();
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

      transform.onDone.listen((_) {
        if (!isDirty) _onDoneController.add(null);
      }, onDone: () => _transforms.remove(transform));

      _onAssetPool.add(transform.onAsset);
      _onLogPool.add(transform.onLog);
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
