// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.package_graph;

import 'dart:async';

import 'asset_cascade.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'asset_set.dart';
import 'build_result.dart';
import 'errors.dart';
import 'log.dart';
import 'package_provider.dart';
import 'transformer.dart';
import 'utils.dart';

/// The collection of [AssetCascade]s for an entire application.
///
/// This tracks each package's [AssetCascade] and routes asset requests between
/// them.
class PackageGraph {
  /// The provider that exposes asset and package information.
  final PackageProvider provider;

  /// The [AssetCascade] for each package.
  final _cascades = <String, AssetCascade>{};

  /// The current [BuildResult] for each package's [AssetCascade].
  ///
  /// The result for a given package will be `null` if that [AssetCascade] is
  /// actively building.
  final _cascadeResults = <String, BuildResult>{};

  /// A stream that emits a [BuildResult] each time the build is completed,
  /// whether or not it succeeded.
  ///
  /// This will emit a result only once every package's [AssetCascade] has
  /// finished building.
  ///
  /// If an unexpected error in barback itself occurs, it will be emitted
  /// through this stream's error channel.
  Stream<BuildResult> get results => _resultsController.stream;
  final _resultsController = new StreamController<BuildResult>.broadcast();

  /// A stream that emits any errors from the graph or the transformers.
  ///
  /// This emits errors as they're detected. If an error occurs in one part of
  /// the graph, unrelated parts will continue building.
  ///
  /// This will not emit programming errors from barback itself. Those will be
  /// emitted through the [results] stream's error channel.
  Stream<BarbackException> get errors => _errors;
  Stream<BarbackException> _errors;

  /// The stream of [LogEntry] objects used to report transformer log entries.
  Stream<LogEntry> get log => _logController.stream;
  final _logController = new StreamController<LogEntry>.broadcast(sync: true);

  /// The most recent error emitted from a cascade's result stream.
  ///
  /// This is used to pipe an unexpected error from a build to the resulting
  /// [Future] returned by [getAllAssets].
  var _lastUnexpectedError;

  /// The stack trace for [_lastUnexpectedError].
  StackTrace _lastUnexpectedErrorTrace;

  /// Creates a new [PackageGraph] that will transform assets in all packages
  /// made available by [provider].
  PackageGraph(this.provider) {
    for (var package in provider.packages) {
      var cascade = new AssetCascade(this, package);
      // The initial result for each cascade is "success" since the cascade
      // doesn't start building until some source in that graph is updated.
      _cascadeResults[package] = new BuildResult.success();
      _cascades[package] = cascade;
      cascade.onDirty.listen((_) {
        _cascadeResults[package] = null;
      });

      cascade.onLog.listen((entry) {
        if (_logController.hasListener) {
          _logController.add(entry);
        } else {
          // No listeners, so just print entry.
          var buffer = new StringBuffer();
          buffer.write("[${entry.level} ${entry.transform}] ");

          if (entry.span != null) {
            buffer.write(entry.span.getLocationMessage(entry.message));
          } else {
            buffer.write(entry.message);
          }

          print(buffer);
        }
      });

      cascade.results.listen((result) {
        _cascadeResults[cascade.package] = result;
        // If any cascade hasn't yet finished, the overall build isn't finished
        // either.
        if (_cascadeResults.values.any((result) => result == null)) return;

        // Include all build errors for all cascades. If no cascades have
        // errors, the result will automatically be considered a success.
        _resultsController.add(
            new BuildResult.aggregate(_cascadeResults.values));
      }, onError: (error, stackTrace) {
        _lastUnexpectedError = error;
        _lastUnexpectedErrorTrace = stackTrace;
        _resultsController.addError(error, stackTrace);
      });
    }

    _errors = mergeStreams(_cascades.values.map((cascade) => cascade.errors),
        broadcast: true);
  }

  /// Gets the asset node identified by [id].
  ///
  /// If [id] is for a generated or transformed asset, this will wait until it
  /// has been created and return it. This means that the returned asset will
  /// always be [AssetState.AVAILABLE].
  ///
  /// If the asset cannot be found, returns null.
  Future<AssetNode> getAssetNode(AssetId id) {
    var cascade = _cascades[id.package];
    if (cascade != null) return cascade.getAssetNode(id);
    return new Future.value(null);
  }

  /// Gets all output assets.
  ///
  /// If a build is currently in progress, waits until it completes. The
  /// returned future will complete with an error if the build is not
  /// successful.
  ///
  /// Any transforms using [LazyTransformer]s will be forced to generate
  /// concrete outputs, and those outputs will be returned.
  Future<AssetSet> getAllAssets() {
    for (var cascade in _cascades.values) {
      cascade.forceAllTransforms();
    }

    if (_cascadeResults.values.contains(null)) {
      // A build is still ongoing, so wait for it to complete and try again.
      return results.first.then((_) => getAllAssets());
    }

    // If an unexpected error occurred, complete with that.
    if (_lastUnexpectedError != null) {
      var error = _lastUnexpectedError;
      _lastUnexpectedError = null;
      return new Future.error(error, _lastUnexpectedErrorTrace);
    }

    // If the build completed with an error, complete the future with it.
    var result = new BuildResult.aggregate(_cascadeResults.values);
    if (!result.succeeded) {
      return new Future.error(BarbackException.aggregate(result.errors));
    }

    // Otherwise, return all of the final output assets.
    var assets = unionAll(_cascades.values.map(
        (cascade) => cascade.availableOutputs.toSet()));

    return new Future.value(new AssetSet.from(assets));
  }

  /// Adds [sources] to the graph's known set of source assets.
  ///
  /// Begins applying any transforms that can consume any of the sources. If a
  /// given source is already known, it is considered modified and all
  /// transforms that use it will be re-applied.
  void updateSources(Iterable<AssetId> sources) {
    groupBy(sources, (id) => id.package).forEach((package, ids) {
      var cascade = _cascades[package];
      if (cascade == null) throw new ArgumentError("Unknown package $package.");
      cascade.updateSources(ids);
    });
  }

  /// Removes [removed] from the graph's known set of source assets.
  void removeSources(Iterable<AssetId> sources) {
    groupBy(sources, (id) => id.package).forEach((package, ids) {
      var cascade = _cascades[package];
      if (cascade == null) throw new ArgumentError("Unknown package $package.");
      cascade.removeSources(ids);
    });
  }

  void updateTransformers(String package,
      Iterable<Iterable<Transformer>> transformers) {
    _cascades[package].updateTransformers(transformers);
  }
}
