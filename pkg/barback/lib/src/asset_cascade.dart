// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset_cascade;

import 'dart:async';
import 'dart:collection';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'asset_set.dart';
import 'log.dart';
import 'build_result.dart';
import 'cancelable_future.dart';
import 'errors.dart';
import 'package_graph.dart';
import 'phase.dart';
import 'stream_pool.dart';
import 'transformer.dart';
import 'utils.dart';

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

  final _phases = <Phase>[];

  /// A stream that emits a [BuildResult] each time the build is completed,
  /// whether or not it succeeded.
  ///
  /// If an unexpected error in barback itself occurs, it will be emitted
  /// through this stream's error channel.
  Stream<BuildResult> get results => _resultsController.stream;
  final _resultsController = new StreamController<BuildResult>.broadcast();

  /// A stream that emits any errors from the cascade or the transformers.
  ///
  /// This emits errors as they're detected. If an error occurs in one part of
  /// the cascade, unrelated parts will continue building.
  ///
  /// This will not emit programming errors from barback itself. Those will be
  /// emitted through the [results] stream's error channel.
  Stream<BarbackException> get errors => _errorsController.stream;
  final _errorsController = new StreamController<BarbackException>.broadcast();

  /// A stream that emits an event whenever this cascade becomes dirty.
  ///
  /// After this stream emits an event, [results] will emit an event once the
  /// cascade is no longer dirty.
  ///
  /// This may emit events when the cascade was already dirty. Events are
  /// emitted synchronously to ensure that the dirty state is thoroughly
  /// propagated as soon as any assets are changed.
  Stream get onDirty => _onDirtyPool.stream;
  final _onDirtyPool = new StreamPool.broadcast();

  /// A controller whose stream feeds into [_onDirtyPool].
  final _onDirtyController = new StreamController.broadcast(sync: true);

  /// A stream that emits an event whenever any transforms in this cascade logs
  /// an entry.
  Stream<LogEntry> get onLog => _onLogPool.stream;
  final _onLogPool = new StreamPool<LogEntry>.broadcast();

  /// The errors that have occurred since the current build started.
  ///
  /// This will be empty if no build is occurring.
  Queue<BarbackException> _accumulatedErrors;

  /// The number of errors that have been logged since the current build
  /// started.
  int _numLogErrors;

  /// A future that completes when the currently running build process finishes.
  ///
  /// If no build it in progress, is `null`.
  Future _processDone;

  /// Whether any source assets have been updated or removed since processing
  /// last began.
  var _newChanges = false;

  /// Returns all currently-available output assets from this cascade.
  AssetSet get availableOutputs =>
    new AssetSet.from(_phases.last.availableOutputs.map((node) => node.asset));

  /// Creates a new [AssetCascade].
  ///
  /// It loads source assets within [package] using [provider].
  AssetCascade(this.graph, this.package) {
    _onDirtyPool.add(_onDirtyController.stream);
    _addPhase(new Phase(this, []));

    // Keep track of logged errors so we can know that the build failed.
    onLog.listen((entry) {
      if (entry.level == LogLevel.ERROR) {
        // TODO(nweiz): keep track of stack chain.
        _accumulatedErrors.add(
            new TransformerException(entry.transform, entry.message, null));
      }
    });
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

    // TODO(rnystrom): Waiting for the entire build to complete is unnecessary
    // in some cases. Should optimize:
    // * [id] may be generated before the compilation is finished. We should
    //   be able to quickly check whether there are any more in-place
    //   transformations that can be run on it. If not, we can return it early.
    // * If [id] has never been generated and all active transformers provide
    //   metadata about the file names of assets it can emit, we can prove that
    //   none of them can emit [id] and fail early.
    return _phases.last.getOutput(id).then((node) {
      // If the requested asset is available, we can just return it.
      if (node != null && node.state.isAvailable) return node;

      // If there's a build running, that build might generate the asset, so we
      // wait for it to complete and then try again.
      if (_processDone != null) {
        return _processDone.then((_) => getAssetNode(id));
      }

      // If the asset hasn't been built and nothing is building now, the asset
      // won't be generated, so we return null.
      return null;
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

      _loadingSources[id] =
          new CancelableFuture<Asset>(graph.provider.getAsset(id));
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
  /// Elements of the inner iterable of [transformers] must be either
  /// [Transformer]s or [TransformerGroup]s.
  void updateTransformers(Iterable<Iterable> transformersIterable) {
    var transformers = transformersIterable.toList();

    for (var i = 0; i < transformers.length; i++) {
      if (_phases.length > i) {
        _phases[i].updateTransformers(transformers[i]);
        continue;
      }

      _addPhase(_phases.last.addPhase(transformers[i]));
    }

    if (transformers.length == 0) {
      _phases.last.updateTransformers([]);
    } else if (transformers.length < _phases.length) {
      _phases[transformers.length - 1].removeFollowing();
      _phases.removeRange(transformers.length, _phases.length);
    }
  }

  void reportError(BarbackException error) {
    _accumulatedErrors.add(error);
    _errorsController.add(error);
  }

  /// Add [phase] to the end of [_phases] and watch its [onDirty] stream.
  void _addPhase(Phase phase) {
    _onDirtyPool.add(phase.onDirty);
    _onLogPool.add(phase.onLog);
    phase.onDirty.listen((_) {
      _newChanges = true;
      _waitForProcess();
    });
    _phases.add(phase);
  }

  /// Starts the build process asynchronously if there is work to be done.
  ///
  /// Returns a future that completes with the background processing is done.
  /// If there is no work to do, returns a future that completes immediately.
  /// All errors that occur during processing will be caught (and routed to the
  /// [results] stream) before they get to the returned future, so it is safe
  /// to discard it.
  Future _waitForProcess() {
    if (_processDone != null) return _processDone;

    _accumulatedErrors = new Queue();
    _numLogErrors = 0;
    return _processDone = _process().then((_) {
      // Report the build completion.
      // TODO(rnystrom): Put some useful data in here.
      _resultsController.add(
          new BuildResult(_accumulatedErrors));
    }).catchError((error, stackTrace) {
      // If we get here, it's an unexpected error. Runtime errors like missing
      // assets should be handled earlier. Errors from transformers or other
      // external code that barback calls into should be caught at that API
      // boundary.
      //
      // On the off chance we get here, pipe the error to the results stream
      // as an error. That will let applications handle it without it appearing
      // in the same path as "normal" errors that get reported.
      _resultsController.addError(error, stackTrace);
    }).whenComplete(() {
      _processDone = null;
      _accumulatedErrors = null;
    });
  }

  /// Starts the background processing.
  ///
  /// Returns a future that completes when all assets have been processed.
  Future _process() {
    _newChanges = false;
    return newFuture(() {
      // Find the first phase that has work to do and do it.
      var future;
      for (var phase in _phases) {
        future = phase.process();
        if (future != null) break;
      }

      // If all phases are done and no new updates have come in, we're done.
      if (future == null) {
        // If changes have come in, start over.
        if (_newChanges) return _process();

        // Otherwise, everything is done.
        return null;
      }

      // Process that phase and then loop onto the next.
      return future.then((_) => _process());
    });
  }
}
