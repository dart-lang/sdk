// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.graph.asset_cascade;

import 'dart:async';

import '../asset/asset.dart';
import '../asset/asset_id.dart';
import '../asset/asset_node.dart';
import '../asset/asset_set.dart';
import '../errors.dart';
import '../log.dart';
import '../transformer/transformer.dart';
import '../utils.dart';
import '../utils/cancelable_future.dart';
import 'node_status.dart';
import 'node_streams.dart';
import 'package_graph.dart';
import 'phase.dart';

/// The asset cascade for an individual package.
///
/// This keeps track of which [Transformer]s are applied to which assets, and
/// re-runs those transformers when their dependencies change. The transformed
/// asset nodes are accessible via [getAssetNode].
///
/// A cascade consists of one or more [Phases], each of which has one or more
/// [Transformer]s that run in parallel, potentially on the same inputs. The
/// inputs of the first phase are the source assets for this cascade's package.
/// The inputs of each successive phase are the outputs of the previous phase,
/// as well as any assets that haven't yet been transformed.
class AssetCascade {
  /// The name of the package whose assets are managed.
  final String package;

  /// The [PackageGraph] that tracks all [AssetCascade]s for all dependencies of
  /// the current app.
  final PackageGraph graph;

  /// The controllers for the [AssetNode]s that provide information about this
  /// cascade's package's source assets.
  final _sourceControllerMap = new Map<AssetId, AssetNodeController>();

  /// Futures for source assets that are currently being loaded.
  ///
  /// These futures are cancelable so that if an asset is updated after a load
  /// has been kicked off, the previous load can be ignored in favor of a new
  /// one.
  final _loadingSources = new Map<AssetId, CancelableFuture<Asset>>();

  /// The list of phases in this cascade.
  ///
  /// This will always contain at least one phase, and the first phase will
  /// never have any transformers. This ensures that every transformer can
  /// request inputs from a previous phase.
  final _phases = <Phase>[];

  /// The subscription to the [Phase.onStatusChange] stream of the last [Phase]
  /// in [_phases].
  StreamSubscription _phaseStatusSubscription;

  /// A stream that emits any errors from the cascade or the transformers.
  ///
  /// This emits errors as they're detected. If an error occurs in one part of
  /// the cascade, unrelated parts will continue building.
  Stream<BarbackException> get errors => _errorsController.stream;
  final _errorsController =
      new StreamController<BarbackException>.broadcast(sync: true);

  /// How far along [this] is in processing its assets.
  NodeStatus get status {
    // Just check the last phase, since it will check all the previous phases
    // itself.
    return _phases.last.status;
  }

  /// The streams exposed by this cascade.
  final _streams = new NodeStreams();
  Stream<LogEntry> get onLog => _streams.onLog;
  Stream<NodeStatus> get onStatusChange => _streams.onStatusChange;

  /// Returns all currently-available output assets from this cascade.
  Future<AssetSet> get availableOutputs => new Future.value(new AssetSet.from(
      _phases.last.availableOutputs.map((node) => node.asset)));

  /// Creates a new [AssetCascade].
  ///
  /// It loads source assets within [package] using [provider].
  AssetCascade(this.graph, this.package) {
    _addPhase(new Phase(this, package));
  }

  /// Gets the asset identified by [id].
  ///
  /// If [id] is for a generated or transformed asset, this will wait until it
  /// has been created and return it. This means that the returned asset will
  /// always be [AssetState.AVAILABLE].
  ///
  /// If the asset cannot be found, returns null.
  Future<AssetNode> getAssetNode(AssetId id) {
    assert(id.package == package);

    var oldLastPhase = _phases.last;
    // TODO(rnystrom): Waiting for the entire build to complete is unnecessary
    // in some cases. Should optimize:
    // * [id] may be generated before the compilation is finished. We should
    //   be able to quickly check whether there are any more in-place
    //   transformations that can be run on it. If not, we can return it early.
    // * If [id] has never been generated and all active transformers provide
    //   metadata about the file names of assets it can emit, we can prove that
    //   none of them can emit [id] and fail early.
    return oldLastPhase.getOutput(id).then((node) {
      // The last phase may have changed if [updateSources] was called after
      // requesting the output. In that case, we want the output from the new
      // last phase.
      if (_phases.last == oldLastPhase) return node;
      return getAssetNode(id);
    });
  }

  /// Adds [sources] to the graph's known set of source assets.
  ///
  /// Begins applying any transforms that can consume any of the sources. If a
  /// given source is already known, it is considered modified and all
  /// transforms that use it will be re-applied.
  void updateSources(Iterable<AssetId> sources) {
    for (var id in sources) {
      var controller = _sourceControllerMap[id];
      if (controller != null) {
        controller.setDirty();
      } else {
        _sourceControllerMap[id] = new AssetNodeController(id);
        _phases.first.addInput(_sourceControllerMap[id].node);
      }

      // If this source was already loading, cancel the old load, since it may
      // return out-of-date contents for the asset.
      if (_loadingSources.containsKey(id)) _loadingSources[id].cancel();

      _loadingSources[id] = new CancelableFuture<Asset>(
          syncFuture(() => graph.provider.getAsset(id)));
      _loadingSources[id].whenComplete(() {
        _loadingSources.remove(id);
      }).then((asset) {
        var controller = _sourceControllerMap[id].setAvailable(asset);
      }).catchError((error, stack) {
        reportError(new AssetLoadException(id, error, stack));

        // TODO(nweiz): propagate error information through asset nodes.
        _sourceControllerMap.remove(id).setRemoved();
      });
    }
  }

  /// Removes [removed] from the graph's known set of source assets.
  void removeSources(Iterable<AssetId> removed) {
    removed.forEach((id) {
      // If the source was being loaded, cancel that load.
      if (_loadingSources.containsKey(id)) _loadingSources.remove(id).cancel();

      var controller = _sourceControllerMap.remove(id);
      // Don't choke if an id is double-removed for some reason.
      if (controller != null) controller.setRemoved();
    });
  }

  /// Sets this cascade's transformer phases to [transformers].
  ///
  /// Elements of the inner iterable of [transformers] must be [Transformer]s,
  /// [TransformerGroup]s, or [AggregateTransformer]s.
  void updateTransformers(Iterable<Iterable> transformersIterable) {
    var transformers = transformersIterable.toList();

    // Always preserve a single phase with no transformers at the beginning of
    // the cascade so that [TransformNode]s in the first populated phase will
    // have something to request assets from.
    for (var i = 0; i < transformers.length; i++) {
      if (_phases.length > i + 1) {
        _phases[i + 1].updateTransformers(transformers[i]);
        continue;
      }

      var phase = _phases.last.addPhase();
      _addPhase(phase);
      phase.updateTransformers(transformers[i]);
    }

    for (var i = transformers.length + 1; i < _phases.length; i++) {
      _phases[i].remove();
    }
    _phases.removeRange(transformers.length + 1, _phases.length);

    _phaseStatusSubscription.cancel();
    _phaseStatusSubscription = _phases.last.onStatusChange
        .listen(_streams.changeStatus);
  }

  /// Force all [LazyTransformer]s' transforms in this cascade to begin
  /// producing concrete assets.
  void forceAllTransforms() {
    for (var phase in _phases) {
      phase.forceAllTransforms();
    }
  }

  void reportError(BarbackException error) {
    _errorsController.add(error);
  }

  /// Add [phase] to the end of [_phases] and watch its streams.
  void _addPhase(Phase phase) {
    _streams.onLogPool.add(phase.onLog);
    if (_phaseStatusSubscription != null) _phaseStatusSubscription.cancel();
    _phaseStatusSubscription =
        phase.onStatusChange.listen(_streams.changeStatus);

    _phases.add(phase);
  }

  String toString() => "cascade for $package";
}
