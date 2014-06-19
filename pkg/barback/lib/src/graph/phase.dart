// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.graph.phase;

import 'dart:async';

import '../asset/asset_id.dart';
import '../asset/asset_node.dart';
import '../asset/asset_node_set.dart';
import '../errors.dart';
import '../log.dart';
import '../transformer/aggregate_transformer.dart';
import '../transformer/transformer.dart';
import '../transformer/transformer_group.dart';
import '../utils.dart';
import '../utils/multiset.dart';
import 'asset_cascade.dart';
import 'group_runner.dart';
import 'node_status.dart';
import 'node_streams.dart';
import 'phase_forwarder.dart';
import 'phase_output.dart';
import 'transformer_classifier.dart';

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

  /// The groups for this phase.
  final _groups = new Map<TransformerGroup, GroupRunner>();

  /// The inputs for this phase.
  ///
  /// For the first phase, these will be the source assets. For all other
  /// phases, they will be the outputs from the previous phase.
  final _inputs = new AssetNodeSet();

  /// The transformer classifiers for this phase.
  ///
  /// The keys can be either [Transformer]s or [AggregateTransformer]s.
  final _classifiers = new Map<dynamic, TransformerClassifier>();

  /// The forwarders for this phase.
  final _forwarders = new Map<AssetId, PhaseForwarder>();

  /// The outputs for this phase.
  final _outputs = new Map<AssetId, PhaseOutput>();

  /// The set of all [AssetNode.origin] properties of the input assets for this
  /// phase.
  ///
  /// This is used to determine which assets have been passed unmodified through
  /// [_classifiers] or [_groups]. It's possible that a given asset was consumed
  /// by a group and not an individual transformer, and so shouldn't be
  /// forwarded through the phase as a whole.
  ///
  /// In order to detect whether an output has been forwarded through a group or
  /// a classifier, we must be able to distinguish it from other outputs with
  /// the same id. To do so, we check if its origin is in [_inputOrigins]. If
  /// so, it's been forwarded unmodified.
  final _inputOrigins = new Multiset<AssetNode>();

  /// The streams exposed by this phase.
  final _streams = new NodeStreams();
  Stream<NodeStatus> get onStatusChange => _streams.onStatusChange;
  Stream<AssetNode> get onAsset => _streams.onAsset;
  Stream<LogEntry> get onLog => _streams.onLog;

  /// How far along [this] is in processing its assets.
  NodeStatus get status {
    // Before any transformers are added, the phase should be dirty if and only
    // if any input is dirty.
    if (_classifiers.isEmpty && _groups.isEmpty && previous == null) {
      return _inputs.any((input) => input.state.isDirty) ?
          NodeStatus.RUNNING : NodeStatus.IDLE;
    }

    var classifierStatus = NodeStatus.dirtiest(
        _classifiers.values.map((classifier) => classifier.status));
    var groupStatus = NodeStatus.dirtiest(
        _groups.values.map((group) => group.status));
    return (previous == null ? NodeStatus.IDLE : previous.status)
        .dirtier(classifierStatus)
        .dirtier(groupStatus);
  }

  /// The previous phase in the cascade, or null if this is the first phase.
  final Phase previous;

  /// The subscription to [previous]'s [onStatusChange] stream.
  StreamSubscription _previousStatusSubscription;

  /// The subscription to [previous]'s [onAsset] stream.
  StreamSubscription<AssetNode> _previousOnAssetSubscription;

  final _inputSubscriptions = new Set<StreamSubscription>();

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
      _previousStatusSubscription = previous.onStatusChange
          .listen((_) => _streams.changeStatus(status));
    }

    onStatusChange.listen((status) {
      if (status == NodeStatus.RUNNING) return;

      // All the previous phases have finished declaring or producing their
      // outputs. If anyone's still waiting for outputs, cut off the wait; we
      // won't be generating them, at least until a source asset changes.
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
    // Each group is one channel along which an asset may be forwarded, as is
    // each transformer.
    var forwarder = new PhaseForwarder(
        node, _classifiers.length, _groups.length);
    _forwarders[node.id] = forwarder;
    forwarder.onAsset.listen(_handleOutputWithoutForwarder);
    if (forwarder.output != null) {
      _handleOutputWithoutForwarder(forwarder.output);
    }

    _inputOrigins.add(node.origin);
    _inputs.add(node);
    _inputSubscriptions.add(node.onStateChange.listen((state) {
      if (state.isRemoved) {
        _inputOrigins.remove(node.origin);
        _forwarders.remove(node.id).remove();
      }
      _streams.changeStatus(status);
    }));

    for (var classifier in _classifiers.values) {
      classifier.addInput(node);
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

      // If this phase and the previous phases are fully declared or done, the
      // requested output won't be generated and we can safely return null.
      if (status != NodeStatus.RUNNING) return null;

      // Otherwise, store a completer for the asset node. If it's generated in
      // the future, we'll complete this completer.
      var completer = _pendingOutputRequests.putIfAbsent(id,
          () => new Completer.sync());
      return completer.future;
    });
  }

  /// Set this phase's transformers to [transformers].
  void updateTransformers(Iterable transformers) {
    var newTransformers = transformers
        .where((op) => op is Transformer || op is AggregateTransformer)
        .toSet();
    var oldTransformers = _classifiers.keys.toSet();
    for (var removed in oldTransformers.difference(newTransformers)) {
      _classifiers.remove(removed).remove();
    }

    for (var transformer in newTransformers.difference(oldTransformers)) {
      var classifier = new TransformerClassifier(
          this, transformer, "$_location.$_index");
      _classifiers[transformer] = classifier;
      classifier.onAsset.listen(_handleOutput);
      _streams.onLogPool.add(classifier.onLog);
      classifier.onStatusChange.listen((_) => _streams.changeStatus(status));
      for (var input in _inputs) {
        classifier.addInput(input);
      }
    }

    var newGroups = transformers.where((op) => op is TransformerGroup)
        .toSet();
    var oldGroups = _groups.keys.toSet();
    for (var removed in oldGroups.difference(newGroups)) {
      _groups.remove(removed).remove();
    }

    for (var added in newGroups.difference(oldGroups)) {
      var runner = new GroupRunner(previous, added, "$_location.$_index");
      _groups[added] = runner;
      runner.onAsset.listen(_handleOutput);
      _streams.onLogPool.add(runner.onLog);
      runner.onStatusChange.listen((_) => _streams.changeStatus(status));
    }

    for (var forwarder in _forwarders.values) {
      forwarder.updateTransformers(_classifiers.length, _groups.length);
    }

    _streams.changeStatus(status);
  }

  /// Force all [LazyTransformer]s' transforms in this phase to begin producing
  /// concrete assets.
  void forceAllTransforms() {
    for (var classifier in _classifiers.values) {
      classifier.forceAllTransforms();
    }

    for (var group in _groups.values) {
      group.forceAllTransforms();
    }
  }

  /// Add a new phase after this one.
  ///
  /// The new phase will have a location annotation describing its place in the
  /// package graph. By default, this annotation will describe it as being
  /// directly after [this]. If [location] is passed, though, it's described as
  /// being the first phase in that location.
  Phase addPhase([String location]) {
    var index = 0;
    if (location == null) {
      location = _location;
      index = _index + 1;
    }

    var next = new Phase._(cascade, location, index, this);
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
    for (var classifier in _classifiers.values.toList()) {
      classifier.remove();
    }
    for (var group in _groups.values) {
      group.remove();
    }
    _streams.close();
    for (var subscription in _inputSubscriptions) {
      subscription.cancel();
    }
    if (_previousStatusSubscription != null) {
      _previousStatusSubscription.cancel();
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
    _streams.onAssetController.add(asset);
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
