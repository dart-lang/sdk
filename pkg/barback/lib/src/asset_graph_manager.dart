// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset_graph_manager;

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

import 'asset.dart';
import 'asset_provider.dart';
import 'asset_graph.dart';
import 'asset_id.dart';
import 'errors.dart';
import 'utils.dart';

// TODO(nweiz): come up with better names for this and AssetGraph.

/// The asset manager for an entire application.
///
/// This tracks each package's [AssetGraph] and routes asset requests between
/// them.
class AssetGraphManager {
  /// The provider that exposes asset and package information.
  final AssetProvider provider;

  /// The [AssetGraph] for each package.
  final _graphs = <String, AssetGraph>{};

  /// The current [BuildResult] for each package's [AssetGraph].
  ///
  /// The result for a given package will be `null` if that [AssetGraph] is
  /// actively building.
  final _graphResults = <String, BuildResult>{};

  /// A stream that emits a [BuildResult] each time the build is completed,
  /// whether or not it succeeded.
  ///
  /// This will emit a result only once every package's [AssetGraph] has
  /// finished building.
  ///
  /// If an unexpected error in barback itself occurs, it will be emitted
  /// through this stream's error channel.
  Stream<BuildResult> get results => _resultsController.stream;
  final _resultsController = new StreamController<BuildResult>.broadcast();

  /// A stream that emits any errors from the asset graph or the transformers.
  ///
  /// This emits errors as they're detected. If an error occurs in one part of
  /// the asset graph, unrelated parts will continue building.
  ///
  /// This will not emit programming errors from barback itself. Those will be
  /// emitted through the [results] stream's error channel.
  Stream get errors => _errors;
  Stream _errors;

  /// Creates a new [AssetGraphManager] that will transform assets in all
  /// packages made available by [provider].
  AssetGraphManager(this.provider) {
    for (var package in provider.packages) {
      var graph = new AssetGraph(this, package,
          provider.getTransformers(package));
      // The initial result for each graph is "success" since the graph doesn't
      // start building until some source in that graph is updated.
      _graphResults[package] = new BuildResult.success();
      _graphs[package] = graph;

      graph.results.listen((result) {
        _graphResults[graph.package] = result;
        // If any graph hasn't yet finished, the overall build isn't finished
        // either.
        if (_graphResults.values.any((result) => result == null)) return;

        // Include all build errors for all graphs. If no graphs have errors,
        // the result will automatically be considered a success.
        _resultsController.add(new BuildResult(flatten(
            _graphResults.values.map((result) => result.errors))));
      }, onError: _resultsController.addError);
    }

    _errors = mergeStreams(_graphs.values.map((graph) => graph.errors));
  }

  /// Gets the asset identified by [id].
  ///
  /// If [id] is for a generated or transformed asset, this will wait until
  /// it has been created and return it. If the asset cannot be found, throws
  /// [AssetNotFoundException].
  Future<Asset> getAssetById(AssetId id) {
    var graph = _graphs[id.package];
    if (graph != null) return graph.getAssetById(id);
    return new Future.error(
        new AssetNotFoundException(id),
        new Trace.current().vmTrace);
  }

  /// Adds [sources] to the graph's known set of source assets.
  ///
  /// Begins applying any transforms that can consume any of the sources. If a
  /// given source is already known, it is considered modified and all
  /// transforms that use it will be re-applied.
  void updateSources(Iterable<AssetId> sources) {
    groupBy(sources, (id) => id.package).forEach((package, ids) {
      var graph = _graphs[package];
      if (graph == null) throw new ArgumentError("Unknown package $package.");
      _graphResults[package] = null;
      graph.updateSources(ids);
    });
  }

  /// Removes [removed] from the graph's known set of source assets.
  void removeSources(Iterable<AssetId> sources) {
    groupBy(sources, (id) => id.package).forEach((package, ids) {
      var graph = _graphs[package];
      if (graph == null) throw new ArgumentError("Unknown package $package.");
      _graphResults[package] = null;
      graph.removeSources(ids);
    });
  }
}
