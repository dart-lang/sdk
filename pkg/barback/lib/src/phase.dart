// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.phase;

import 'dart:async';
import 'dart:collection';

import 'asset_cascade.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'asset_set.dart';
import 'errors.dart';
import 'phase_input.dart';
import 'phase_output.dart';
import 'stream_pool.dart';
import 'transformer.dart';
import 'utils.dart';

/// One phase in the ordered series of transformations in an [AssetCascade].
///
/// Each phase can access outputs from previous phases and can in turn pass
/// outputs to later phases. Phases are processed strictly serially. All
/// transforms in a phase will be complete before moving on to the next phase.
/// Within a single phase, all transforms will be run in parallel.
///
/// Building can be interrupted between phases. For example, a source is added
/// which starts the background process. Sometime during, say, phase 2 (which
/// is running asynchronously) that source is modified. When the process queue
/// goes to advance to phase 3, it will see that modification and start the
/// waterfall from the beginning again.
class Phase {
  /// The cascade that owns this phase.
  final AssetCascade cascade;

  /// The transformers that can access [inputs].
  ///
  /// Their outputs will be available to the next phase.
  final Set<Transformer> _transformers;

  /// The inputs for this phase.
  ///
  /// For the first phase, these will be the source assets. For all other
  /// phases, they will be the outputs from the previous phase.
  final _inputs = new Map<AssetId, PhaseInput>();

  /// The outputs for this phase.
  final _outputs = new Map<AssetId, PhaseOutput>();

  /// A stream that emits an event whenever this phase becomes dirty and needs
  /// to be run.
  ///
  /// This may emit events when the phase was already dirty or while processing
  /// transforms. Events are emitted synchronously to ensure that the dirty
  /// state is thoroughly propagated as soon as any assets are changed.
  Stream get onDirty => _onDirtyPool.stream;
  final _onDirtyPool = new StreamPool.broadcast();

  /// A controller whose stream feeds into [_onDirtyPool].
  ///
  /// This is used whenever an input is added or transforms are changed.
  final _onDirtyController = new StreamController.broadcast(sync: true);

  /// The phase after this one.
  ///
  /// Outputs from this phase will be passed to it.
  Phase get next => _next;
  Phase _next;

  /// Returns all currently-available output assets for this phase.
  AssetSet get availableOutputs {
    return new AssetSet.from(_outputs.values
        .map((output) => output.output)
        .where((node) => node.state.isAvailable)
        .map((node) => node.asset));
  }

  Phase(this.cascade, Iterable<Transformer> transformers)
      : _transformers = transformers.toSet() {
    _onDirtyPool.add(_onDirtyController.stream);
  }

  /// Adds a new asset as an input for this phase.
  ///
  /// [node] doesn't have to be [AssetState.AVAILABLE]. Once it is, the phase
  /// will automatically begin determining which transforms can consume it as a
  /// primary input. The transforms themselves won't be applied until [process]
  /// is called, however.
  ///
  /// This should only be used for brand-new assets or assets that have been
  /// removed and re-created. The phase will automatically handle updated assets
  /// using the [AssetNode.onStateChange] stream.
  void addInput(AssetNode node) {
    if (_inputs.containsKey(node.id)) _inputs[node.id].remove();

    var input = new PhaseInput(this, node, _transformers);
    _inputs[node.id] = input;
    input.input.whenRemoved.then((_) => _inputs.remove(node.id));
    _onDirtyPool.add(input.onDirty);
    _onDirtyController.add(null);
  }

  /// Gets the asset node for an input [id].
  ///
  /// If an input with that ID cannot be found, returns null.
  Future<AssetNode> getInput(AssetId id) {
    return newFuture(() {
      if (id.package != cascade.package) return cascade.graph.getAssetNode(id);
      if (_inputs.containsKey(id)) return _inputs[id].input;
      return null;
    });
  }

  /// Gets the asset node for an output [id].
  ///
  /// If an output with that ID cannot be found, returns null.
  Future<AssetNode> getOutput(AssetId id) {
    return newFuture(() {
      if (id.package != cascade.package) return cascade.graph.getAssetNode(id);
      if (!_outputs.containsKey(id)) return null;
      return _outputs[id].output;
    });
  }

  /// Set this phase's transformers to [transformers].
  void updateTransformers(Iterable<Transformer> transformers) {
    _onDirtyController.add(null);
    _transformers.clear();
    _transformers.addAll(transformers);
    for (var input in _inputs.values) {
      input.updateTransformers(_transformers);
    }
  }

  /// Add a new phase after this one with [transformers].
  ///
  /// This may only be called on a phase with no phase following it.
  Phase addPhase(Iterable<Transformer> transformers) {
    assert(_next == null);
    _next = new Phase(cascade, transformers);
    for (var output in _outputs.values.toList()) {
      // Remove [output]'s listeners because now they should get the asset from
      // [_next], rather than this phase. Any transforms consuming [output] will
      // be re-run and will consume the output from the new final phase.
      output.removeListeners();

      // Removing [output]'s listeners will cause it to be removed from
      // [_outputs], so we have to put it back.
      _outputs[output.output.id] = output;
      _next.addInput(output.output);
    }
    return _next;
  }

  /// Mark this phase as removed.
  ///
  /// This will remove all the phase's outputs and all following phases.
  void remove() {
    removeFollowing();
    for (var input in _inputs.values.toList()) {
      input.remove();
    }
    _onDirtyPool.close();
  }

  /// Remove all phases after this one.
  Phase removeFollowing() {
    if (_next == null) return;
    _next.remove();
    _next = null;
  }

  /// Processes this phase.
  ///
  /// Returns a future that completes when processing is done. If there is
  /// nothing to process, returns `null`.
  Future process() {
    if (!_inputs.values.any((input) => input.isDirty)) return null;

    var outputIds = new Set<AssetId>();
    return Future.wait(_inputs.values.map((input) {
      if (!input.isDirty) return new Future.value(new Set());
      return input.process().then((outputs) {
        for (var asset in outputs) {
          outputIds.add(asset.id);
          if (_outputs.containsKey(asset.id)) {
            _outputs[asset.id].add(asset);
          } else {
            _outputs[asset.id] = new PhaseOutput(this, asset);
            _outputs[asset.id].output.whenRemoved
                .then((_) => _outputs.remove(asset.id));
            if (_next != null) _next.addInput(_outputs[asset.id].output);
          }
        }
      });
    })).then((_) {
      // Report collisions in a deterministic order.
      outputIds = outputIds.toList();
      outputIds.sort((a, b) => a.compareTo(b));
      for (var id in outputIds) {
        // It's possible the output was removed before other transforms in this
        // phase finished.
        if (!_outputs.containsKey(id)) continue;
        var exception = _outputs[id].collisionException;
        if (exception != null) cascade.reportError(exception);
      }
    });
  }
}
