// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.phase;

import 'dart:async';

import 'asset_cascade.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'errors.dart';
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
  final _transformers = new Set<Transformer>();

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

  /// A stream that emits an event whenever [this] is no longer dirty.
  ///
  /// This is synchronous in order to guarantee that it will emit an event as
  /// soon as [isDirty] flips from `true` to `false`.
  Stream get onDone => _onDoneController.stream;
  final _onDoneController = new StreamController.broadcast(sync: true);

  /// A stream that emits any new assets emitted by [this].
  ///
  /// Assets are emitted synchronously to ensure that any changes are thoroughly
  /// propagated as soon as they occur. Only a phase with no [next] phase will
  /// emit assets.
  Stream<AssetNode> get onAsset => _onAssetController.stream;
  final _onAssetController =
      new StreamController<AssetNode>.broadcast(sync: true);

  /// Whether [this] is dirty and still has more processing to do.
  ///
  /// A phase is considered dirty if any of the previous phases in the same
  /// cascade are dirty, since those phases could emit an asset that this phase
  /// will then need to process.
  bool get isDirty => (previous != null && previous.isDirty) ||
      _inputs.values.any((input) => input.isDirty) ||
      _groups.values.any((group) => group.isDirty);

  /// A stream that emits an event whenever any transforms in this phase logs
  /// an entry.
  Stream<LogEntry> get onLog => _onLogPool.stream;
  final _onLogPool = new StreamPool<LogEntry>.broadcast();

  /// The previous phase in the cascade, or null if this is the first phase.
  final Phase previous;

  /// The subscription to [previous]'s [onDone] stream.
  StreamSubscription _previousOnDoneSubscription;

  /// The subscription to [previous]'s [onAsset] stream.
  StreamSubscription<AssetNode> _previousOnAssetSubscription;

  /// A map of asset ids to completers for [getInput] requests.
  ///
  /// If an asset node is requested before it's available, we put a completer in
  /// this map to wait for the asset to be generated. If it's not generated, the
  /// completer should complete to `null`.
  final _pendingOutputRequests = new Map<AssetId, Completer<AssetNode>>();

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
  Phase(AssetCascade cascade, String location)
      : this._(cascade, location, 0);

  Phase._(this.cascade, this._location, this._index, [this.previous]) {
    if (previous != null) {
      _previousOnAssetSubscription = previous.onAsset.listen(addInput);
      _previousOnDoneSubscription = previous.onDone.listen((_) {
        if (!isDirty) _onDoneController.add(null);
      });
    }

    onDone.listen((_) {
      // All the previous phases have finished building. If anyone's still
      // waiting for outputs, cut off the wait; we won't be generating them,
      // at least until a source asset changes.
      for (var completer in _pendingOutputRequests.values) {
        completer.complete(null);
      }
      _pendingOutputRequests.clear();
    });
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

    // Each group is one channel along which an asset may be forwarded, as is
    // each transformer.
    var forwarder = new PhaseForwarder(
        node, _transformers.length, _groups.length);
    _forwarders[node.id] = forwarder;
    forwarder.onAsset.listen(_handleOutputWithoutForwarder);
    if (forwarder.output != null) {
      _handleOutputWithoutForwarder(forwarder.output);
    }

    _inputOrigins.add(node.origin);
    var input = new PhaseInput(this, node, "$_location.$_index");
    _inputs[node.id] = input;
    input.input.whenRemoved(() {
      _inputOrigins.remove(node.origin);
      _inputs.remove(node.id);
      _forwarders.remove(node.id).remove();
      if (!isDirty) _onDoneController.add(null);
    });
    input.onAsset.listen(_handleOutput);
    _onLogPool.add(input.onLog);
    input.onDone.listen((_) {
      if (!isDirty) _onDoneController.add(null);
    });

    input.updateTransformers(_transformers);

    for (var group in _groups.values) {
      group.addInput(node);
    }
  }

  // TODO(nweiz): If the output is available when this is called, it's
  // theoretically possible for it to become unavailable between the call and
  // the return. If it does so, it won't trigger the rebuilding process. To
  // avoid this, we should have this and the methods it calls take explicit
  // callbacks, as in [AssetNode.whenAvailable].
  /// Gets the asset node for an output [id].
  ///
  /// If [id] is for a generated or transformed asset, this will wait until it
  /// has been created and return it. This means that the returned asset will
  /// always be [AssetState.AVAILABLE].
  /// 
  /// If the output cannot be found, returns null.
  Future<AssetNode> getOutput(AssetId id) {
    return syncFuture(() {
      if (id.package != cascade.package) return cascade.graph.getAssetNode(id);
      if (_outputs.containsKey(id)) {
        var output = _outputs[id].output;
        // If the requested output is available, we can just return it.
        if (output.state.isAvailable) return output;

        // If the requested output exists but isn't yet available, wait to see
        // if it becomes available. If it's removed before becoming available,
        // try again, since it could be generated again.
        output.force();
        return output.whenAvailable((_) {
          return output;
        }).catchError((error) {
          if (error is! AssetNotFoundException) throw error;
          return getOutput(id);
        });
      }

      // If neither this phase nor the previous phases are dirty, the requested
      // output won't be generated and we can safely return null.
      if (!isDirty) return null;

      // Otherwise, store a completer for the asset node. If it's generated in
      // the future, we'll complete this completer.
      var completer = _pendingOutputRequests.putIfAbsent(id,
          () => new Completer.sync());
      return completer.future;
    });
  }

  /// Set this phase's transformers to [transformers].
  void updateTransformers(Iterable transformers) {
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
      runner.onAsset.listen(_handleOutput);
      _onLogPool.add(runner.onLog);
      runner.onDone.listen((_) {
        if (!isDirty) _onDoneController.add(null);
      });
      for (var input in _inputs.values) {
        runner.addInput(input.input);
      }
    }

    for (var forwarder in _forwarders.values) {
      forwarder.updateTransformers(_transformers.length, _groups.length);
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

  /// Add a new phase after this one.
  ///
  /// This may only be called on a phase with no phase following it.
  Phase addPhase() {
    var next = new Phase._(cascade, _location, _index + 1, this);
    for (var output in _outputs.values.toList()) {
      // Remove [output]'s listeners because now they should get the asset from
      // [next], rather than this phase. Any transforms consuming [output] will
      // be re-run and will consume the output from the new final phase.
      output.removeListeners();
    }
    return next;
  }

  /// Mark this phase as removed.
  ///
  /// This will remove all the phase's outputs.
  void remove() {
    for (var input in _inputs.values.toList()) {
      input.remove();
    }
    for (var group in _groups.values) {
      group.remove();
    }
    _onAssetController.close();
    _onLogPool.close();
    if (_previousOnDoneSubscription != null) {
      _previousOnDoneSubscription.cancel();
    }
    if (_previousOnAssetSubscription != null) {
      _previousOnAssetSubscription.cancel();
    }
  }

  /// Add [asset] as an output of this phase.
  void _handleOutput(AssetNode asset) {
    if (_inputOrigins.contains(asset.origin)) {
      _forwarders[asset.id].addIntermediateAsset(asset);
    } else {
      _handleOutputWithoutForwarder(asset);
    }
  }

  /// Add [asset] as an output of this phase without checking if it's a
  /// forwarded asset.
  void _handleOutputWithoutForwarder(AssetNode asset) {
    if (_outputs.containsKey(asset.id)) {
      _outputs[asset.id].add(asset);
    } else {
      _outputs[asset.id] = new PhaseOutput(this, asset, "$_location.$_index");
      _outputs[asset.id].onAsset.listen(_emit,
          onDone: () => _outputs.remove(asset.id));
      _emit(_outputs[asset.id].output);
    }

    var exception = _outputs[asset.id].collisionException;
    if (exception != null) cascade.reportError(exception);
  }

  /// Emit [asset] as an output of this phase.
  ///
  /// This should be called after [_handleOutput], so that collisions are
  /// resolved.
  void _emit(AssetNode asset) {
    _onAssetController.add(asset);
    _providePendingAsset(asset);
  }

  /// Provide an asset to a pending [getOutput] call.
  void _providePendingAsset(AssetNode asset) {
    // If anyone's waiting for this asset, provide it to them.
    var request = _pendingOutputRequests.remove(asset.id);
    if (request == null) return;

    if (asset.state.isAvailable) {
      request.complete(asset);
      return;
    }

    // A lazy asset may be emitted while still dirty. If so, we wait until it's
    // either available or removed before trying again to access it.
    assert(asset.state.isDirty);
    asset.force();
    asset.whenStateChanges().then((state) {
      if (state.isRemoved) return getOutput(asset.id);
      return asset;
    }).then(request.complete).catchError(request.completeError);
  }

  String toString() => "phase $_location.$_index";
}
