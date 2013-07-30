// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset_cascade;

import 'dart:async';
import 'dart:collection';

import 'package:stack_trace/stack_trace.dart';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_set.dart';
import 'errors.dart';
import 'change_batch.dart';
import 'package_graph.dart';
import 'phase.dart';
import 'transformer.dart';
import 'utils.dart';

/// The asset cascade for an individual package.
///
/// This keeps track of which [Transformer]s are applied to which assets, and
/// re-runs those transformers when their dependencies change. The transformed
/// assets are accessible via [getAssetById].
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
  final PackageGraph _graph;

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
  Stream get errors => _errorsController.stream;
  final _errorsController = new StreamController.broadcast();

  /// The errors that have occurred since the current build started.
  ///
  /// This will be empty if no build is occurring.
  Queue _accumulatedErrors;

  /// A future that completes when the currently running build process finishes.
  ///
  /// If no build it in progress, is `null`.
  Future _processDone;

  ChangeBatch _sourceChanges;

  /// Creates a new [AssetCascade].
  ///
  /// It loads source assets within [package] using [provider] and then uses
  /// [transformerPhases] to generate output files from them.
  //TODO(rnystrom): Better way of specifying transformers and their ordering.
  AssetCascade(this._graph, this.package,
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
    assert(id.package == package);

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
    return (_processDone == null ? new Future.value() : _processDone).then((_) {
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
    assert(sources.every((id) => id.package == package));
    _sourceChanges.update(sources);

    _waitForProcess();
  }

  /// Removes [removed] from the graph's known set of source assets.
  void removeSources(Iterable<AssetId> removed) {
    if (_sourceChanges == null) _sourceChanges = new ChangeBatch();
    assert(removed.every((id) => id.package == package));
    _sourceChanges.remove(removed);

    _waitForProcess();
  }

  void reportError(error) {
    _accumulatedErrors.add(error);
    _errorsController.add(error);
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
    return _processDone = _process().then((_) {
      // Report the build completion.
      // TODO(rnystrom): Put some useful data in here.
      _resultsController.add(new BuildResult(_accumulatedErrors));
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
      _accumulatedErrors = null;
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
    return newFuture(() {
      if (_sourceChanges == null) return null;

      // Take the current batch to ensure it doesn't get added to while we're
      // processing it.
      var changes = _sourceChanges;
      _sourceChanges = null;

      var updated = new AssetSet();
      var futures = [];
      for (var id in changes.updated) {
        // TODO(rnystrom): Catch all errors from provider and route to results.
        futures.add(_graph.provider.getAsset(id).then((asset) {
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

/// An event indicating that the cascade has finished building all assets.
///
/// A build can end either in success or failure. If there were no errors during
/// the build, it's considered to be a success; any errors render it a failure,
/// although individual assets may still have built successfully.
class BuildResult {
  /// All errors that occurred during the build.
  final List errors;

  /// `true` if the build succeeded.
  bool get succeeded => errors.isEmpty;

  BuildResult(Iterable errors)
      : errors = errors.toList();

  /// Creates a build result indicating a successful build.
  ///
  /// This equivalent to a build result with no errors.
  BuildResult.success()
      : this([]);

  String toString() {
    if (succeeded) return "success";

    return "errors:\n" + errors.map((error) {
      var stackTrace = getAttachedStackTrace(error);
      if (stackTrace != null) stackTrace = new Trace.from(stackTrace);

      var msg = new StringBuffer();
      msg.write(prefixLines(error.toString()));
      if (stackTrace != null) {
        msg.write("\n\n");
        msg.write("Stack trace:\n");
        msg.write(prefixLines(stackTrace.toString()));
      }
      return msg.toString();
    }).join("\n\n");
  }
}
