// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.phase;

import 'dart:async';

import 'asset_cascade.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'group_runner.dart';
import 'log.dart';
import 'multiset.dart';
import 'phase_forwarder.dart';
import 'phase_input.dart';
import 'phase_output.dart';
import 'stream_pool.dart';
import 'transformer.dart';
import 'transformer_group.dart';
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

  /// A string describing the location of [this] in the transformer graph.
  final String _location;

  /// The index of [this] in its parent cascade or group.
  final int _index;

  /// The transformers that can access [inputs].
  ///
  /// Their outputs will be available to the next phase.
  final Set<Transformer> _transformers;

  /// The groups for this phase.
  final _groups = new Map<TransformerGroup, GroupRunner>();

  /// The inputs for this phase.
  ///
  /// For the first phase, these will be the source assets. For all other
  /// phases, they will be the outputs from the previous phase.
  final _inputs = new Map<AssetId, PhaseInput>();

  /// The forwarders for this phase.
  final _forwarders = new Map<AssetId, PhaseForwarder>();

  /// The outputs for this phase.
  final _outputs = new Map<AssetId, PhaseOutput>();

  /// The set of all [AssetNode.origin] properties of the input assets for this
  /// phase.
  ///
  /// This is used to determine which assets have been passed unmodified through
  /// [_inputs] or [_groups]. Each input asset has a PhaseInput in [_inputs]. If
  /// that input isn't consumed by any transformers, it will be forwarded
  /// through the PhaseInput. However, it's possible that it was consumed by a
  /// group, and so shouldn't be forwarded through the phase as a whole.
  ///
  /// In order to detect whether an output has been forwarded through a group or
  /// a PhaseInput, we must be able to distinguish it from other outputs with
  /// the same id. To do so, we check if its origin is in [_inputOrigins]. If
  /// so, it's been forwarded unmodified.
  final _inputOrigins = new Multiset<AssetNode>();

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

  /// Whether this phase is dirty and needs to be run.
  bool get isDirty => _inputs.values.any((input) => input.isDirty) ||
      _groups.values.any((group) => group.isDirty);

  /// A stream that emits an event whenever any transforms in this phase logs
  /// an entry.
  Stream<LogEntry> get onLog => _onLogPool.stream;
  final _onLogPool = new StreamPool<LogEntry>.broadcast();

  /// The phase after this one.
  ///
  /// Outputs from this phase will be passed to it.
  Phase get next => _next;
  Phase _next;

  /// Returns all currently-available output assets for this phase.
  Set<AssetNode> get availableOutputs {
    return _outputs.values
        .map((output) => output.output)
        .where((node) => node.state.isAvailable)
        .toSet();
  }

  // TODO(nweiz): Rather than passing the cascade and the phase everywhere,
  // create an interface that just exposes [getInput]. Emit errors via
  // [AssetNode]s.
  Phase(AssetCascade cascade, Iterable transformers, String location)
      : this._(cascade, transformers, location, 0);

  Phase._(this.cascade, Iterable transformers, this._location, this._index)
      : _transformers = transformers.where((op) => op is Transformer).toSet() {
    _onDirtyPool.add(_onDirtyController.stream);

    for (var group in transformers.where((op) => op is TransformerGroup)) {
      var runner = new GroupRunner(cascade, group, "$_location.$_index");
      _groups[group] = runner;
      _onDirtyPool.add(runner.onDirty);
      _onLogPool.add(runner.onLog);
    }
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

    node.force();

    // Each group is one channel along which an asset may be forwarded. Then
    // there's one additional channel for the non-grouped transformers.
    var forwarder = new PhaseForwarder(_groups.length + 1);
    _forwarders[node.id] = forwarder;
    forwarder.onForwarding.listen((asset) {
      _addOutput(asset);

      var exception = _outputs[asset.id].collisionException;
      if (exception != null) cascade.reportError(exception);
    });

    _inputOrigins.add(node.origin);
    var input = new PhaseInput(this, node, _transformers, "$_location.$_index");
    _inputs[node.id] = input;
    input.input.whenRemoved(() {
      _inputOrigins.remove(node.origin);
      _inputs.remove(node.id);
      _forwarders.remove(node.id).remove();
    });
    _onDirtyPool.add(input.onDirty);
    _onDirtyController.add(null);
    _onLogPool.add(input.onLog);

    for (var group in _groups.values) {
      group.addInput(node);
    }
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
      var output = _outputs[id].output;
      output.force();
      return output;
    });
  }

  /// Set this phase's transformers to [transformers].
  void updateTransformers(Iterable transformers) {
    _onDirtyController.add(null);

    var actualTransformers = transformers.where((op) => op is Transformer);
    _transformers.clear();
    _transformers.addAll(actualTransformers);
    for (var input in _inputs.values) {
      input.updateTransformers(actualTransformers);
    }

    var newGroups = transformers.where((op) => op is TransformerGroup)
        .toSet();
    var oldGroups = _groups.keys.toSet();
    for (var removed in oldGroups.difference(newGroups)) {
      _groups.remove(removed).remove();
    }

    for (var added in newGroups.difference(oldGroups)) {
      var runner = new GroupRunner(cascade, added, "$_location.$_index");
      _groups[added] = runner;
      _onDirtyPool.add(runner.onDirty);
      _onLogPool.add(runner.onLog);
      for (var input in _inputs.values) {
        runner.addInput(input.input);
      }
    }

    for (var forwarder in _forwarders.values) {
      forwarder.numChannels = _groups.length + 1;
    }
  }

  /// Force all [LazyTransformer]s' transforms in this phase to begin producing
  /// concrete assets.
  void forceAllTransforms() {
    for (var group in _groups.values) {
      group.forceAllTransforms();
    }

    for (var input in _inputs.values) {
      input.forceAllTransforms();
    }
  }

  /// Add a new phase after this one with [transformers].
  ///
  /// This may only be called on a phase with no phase following it.
  Phase addPhase(Iterable transformers) {
    assert(_next == null);
    _next = new Phase._(cascade, transformers, _location, _index + 1);
    for (var output in _outputs.values.toList()) {
      // Remove [output]'s listeners because now they should get the asset from
      // [_next], rather than this phase. Any transforms consuming [output] will
      // be re-run and will consume the output from the new final phase.
      output.removeListeners();
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
    for (var group in _groups.values) {
      group.remove();
    }
    _onDirtyPool.close();
    _onLogPool.close();
  }

  /// Remove all phases after this one.
  void removeFollowing() {
    if (_next == null) return;
    _next.remove();
    _next = null;
  }

  /// Processes this phase.
  ///
  /// Returns a future that completes when processing is done. If there is
  /// nothing to process, returns `null`.
  Future process() {
    if (!isDirty) return null;

    var outputIds = new Set<AssetId>();
    void _handleOutputs(Set<AssetNode> outputs) {
      for (var asset in outputs) {
        if (_inputOrigins.contains(asset.origin)) {
          _forwarders[asset.id].addIntermediateAsset(asset);
          continue;
        }

        outputIds.add(asset.id);
        _addOutput(asset);
      }
    }

    var outputFutures = [];
    outputFutures.addAll(_inputs.values.map((input) {
      if (!input.isDirty) return new Future.value(new Set());
      return input.process().then(_handleOutputs);
    }));
    outputFutures.addAll(_groups.values.map((group) {
      if (!group.isDirty) return new Future.value(new Set());
      return group.process().then(_handleOutputs);
    }));

    return Future.wait(outputFutures).then((_) {
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

  /// Add [asset] as an output of this phase.
  void _addOutput(AssetNode asset) {
    if (_outputs.containsKey(asset.id)) {
      _outputs[asset.id].add(asset);
    } else {
      _outputs[asset.id] = new PhaseOutput(this, asset, "$_location.$_index");
      _outputs[asset.id].onAsset.listen((output) {
        if (_next != null) _next.addInput(output);
      }, onDone: () => _outputs.remove(asset.id));
      if (_next != null) _next.addInput(_outputs[asset.id].output);
    }
  }

  String toString() => "phase $_location.$_index";
}
