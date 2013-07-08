// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset_graph;

import 'dart:async';
import 'dart:collection';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_provider.dart';
import 'asset_set.dart';
import 'errors.dart';
import 'change_batch.dart';
import 'phase.dart';
import 'transformer.dart';

/// The main build dependency manager.
///
/// For any given input file, it can tell which output files are affected by
/// it, and vice versa.
class AssetGraph {
  final AssetProvider _provider;

  final _phases = <Phase>[];

  Stream<BuildResult> get results => _resultsController.stream;
  final _resultsController = new StreamController<BuildResult>.broadcast();

  /// A future that completes when the currently running build process finishes.
  ///
  /// If no build it in progress, is `null`.
  Future _processDone;

  ChangeBatch _sourceChanges;

  /// Creates a new [AssetGraph].
  ///
  /// It loads source assets using [provider] and then uses [transformerPhases]
  /// to generate output files from them.
  //TODO(rnystrom): Better way of specifying transformers and their ordering.
  AssetGraph(this._provider,
      Iterable<Iterable<Transformer>> transformerPhases) {
    // Flatten the phases to a list so we can traverse backwards to wire up
    // each phase to its next.
    var phases = transformerPhases.toList();

    // Each phase writes its outputs as inputs to the next phase after it.
    // Add a phase at the end for the final outputs of the last phase.
    phases.add([]);

    Phase nextPhase = null;
    for (var transformers in phases.reversed) {
      nextPhase = new Phase(this, _phases.length, transformers.toList(),
          nextPhase);
      _phases.insert(0, nextPhase);
    }
  }

  /// Gets the asset identified by [id].
  ///
  /// If [id] is for a generated or transformed asset, this will wait until
  /// it has been created and return it. If the asset cannot be found, throws
  /// [AssetNotFoundException].
  Future<Asset> getAssetById(AssetId id) {
    // TODO(rnystrom): Waiting for the entire build to complete is unnecessary
    // in some cases. Should optimize:
    // * [id] may be generated before the compilation is finished. We should
    //   be able to quickly check whether there are any more in-place
    //   transformations that can be run on it. If not, we can return it early.
    // * If everything is compiled, something that didn't output [id] is
    //   dirtied, and then [id] is requested, we can return it immediately,
    //   since anything overwriting it at that point is an error.
    // * If [id] has never been generated and all active transformers provide
    //   metadata about the file names of assets it can emit, we can prove that
    //   none of them can emit [id] and fail early.
    return _waitForProcess().then((_) {
      // Each phase's inputs are the outputs of the previous phase. Find the
      // last phase that contains the asset. Since the last phase has no
      // transformers, this will find the latest output for that id.

      // TODO(rnystrom): Currently does not omit assets that are actually used
      // as inputs for transformers. This means you can request and get an
      // asset that should be "consumed" because it's used to generate the
      // real asset you care about. Need to figure out how we want to handle
      // that and what use cases there are related to it.
      for (var i = _phases.length - 1; i >= 0; i--) {
        var node = _phases[i].inputs[id];
        if (node != null) {
          // By the time we get here, the asset should have been built.
          assert(node.asset != null);
          return node.asset;
        }
      }

      // Couldn't find it.
      throw new AssetNotFoundException(id);
    });
  }

  /// Adds [sources] to the graph's known set of source assets.
  ///
  /// Begins applying any transforms that can consume any of the sources. If a
  /// given source is already known, it is considered modified and all
  /// transforms that use it will be re-applied.
  void updateSources(Iterable<AssetId> sources) {
    if (_sourceChanges == null) _sourceChanges = new ChangeBatch();
    _sourceChanges.update(sources);

    _waitForProcess();
  }

  /// Removes [removed] from the graph's known set of source assets.
  void removeSources(Iterable<AssetId> removed) {
    if (_sourceChanges == null) _sourceChanges = new ChangeBatch();
    _sourceChanges.remove(removed);

    _waitForProcess();
  }

  /// Reports a process result with the given error then throws it.
  void reportError(error) {
    _resultsController.add(new BuildResult(error));
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
    return _processDone = _process().then((_) {
      // Report the build completion.
      // TODO(rnystrom): Put some useful data in here.
      _resultsController.add(new BuildResult());
    }).catchError((error) {
      // If we get here, it's an unexpected error. Runtime errors like missing
      // assets should be handled earlier. Errors from transformers or other
      // external code that barback calls into should be caught at that API
      // boundary.
      //
      // On the off chance we get here, pipe the error to the results stream
      // as an error. That will let applications handle it without it appearing
      // in the same path as "normal" errors that get reported.
      _resultsController.addError(error);
    }).whenComplete(() {
      _processDone = null;
    });
  }

  /// Starts the background processing.
  ///
  /// Returns a future that completes when all assets have been processed.
  Future _process() {
    return _processSourceChanges().then((_) {
      // Find the first phase that has work to do and do it.
      var future;
      for (var phase in _phases) {
        future = phase.process();
        if (future != null) break;
      }

      // If all phases are done and no new updates have come in, we're done.
      if (future == null) {
        // If changes have come in, start over.
        if (_sourceChanges != null) return _process();

        // Otherwise, everything is done.
        return;
      }

      // Process that phase and then loop onto the next.
      return future.then((_) => _process());
    });
  }

  /// Processes the current batch of changes to source assets.
  Future _processSourceChanges() {
    // Always pump the event loop. This ensures a bunch of synchronous source
    // changes are processed in a single batch even when the first one starts
    // the build process.
    return new Future(() {
      if (_sourceChanges == null) return null;

      // Take the current batch to ensure it doesn't get added to while we're
      // processing it.
      var changes = _sourceChanges;
      _sourceChanges = null;

      var updated = new AssetSet();
      var futures = [];
      for (var id in changes.updated) {
        // TODO(rnystrom): Catch all errors from provider and route to results.
        futures.add(_provider.getAsset(id).then((asset) {
          updated.add(asset);
        }).catchError((error) {
          if (error is AssetNotFoundException) {
            // Handle missing asset errors like regular missing assets.
            reportError(error);
          } else {
            // It's an unexpected error, so rethrow it.
            throw error;
          }
        }));
      }

      return Future.wait(futures).then((_) {
        _phases.first.updateInputs(updated, changes.removed);
      });
    });
  }
}

/// Used to report build results back from the asynchronous build process
/// running in the background.
class BuildResult {
  /// The error that occurred, or `null` if the result is not an error.
  final error;

  /// `true` if this result is for a successful build.
  bool get succeeded => error == null;

  BuildResult([this.error]);
}
