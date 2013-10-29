// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.barback;

import 'dart:async';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_set.dart';
import 'log.dart';
import 'build_result.dart';
import 'errors.dart';
import 'package_graph.dart';
import 'package_provider.dart';
import 'transformer.dart';

/// A general-purpose asynchronous build dependency graph manager.
///
/// It consumes source assets (including Dart files) in a set of packages,
/// runs transformations on them, and then tracks which sources have been
/// modified and which transformations need to be re-run.
///
/// To do this, you give barback a [PackageProvider] which can yield a set of
/// [Transformer]s and raw source [Asset]s. Then you tell it which input files
/// have been added or modified by calling [updateSources]. Barback will
/// automatically wire up the appropriate transformers to those inputs and
/// start running them asynchronously. If a transformer produces outputs that
/// can be consumed by other transformers, they will automatically be pipelined
/// correctly.
///
/// You can then request assets (either source or generated) by calling
/// [getAssetById]. This will wait for any necessary transformations and then
/// return the asset.
///
/// When source files have been modified or removed, tell barback by calling
/// [updateSources] and [removeSources] as appropriate. Barback will
/// automatically track which transformations are affected by those changes and
/// re-run them as needed.
///
/// Barback tries to be resilient to errors since assets are often in an
/// in-progress state. When errors occur, they will be captured and emitted on
/// the [errors] stream.
class Barback {
  /// The graph managed by this instance.
  final PackageGraph _graph;

  /// A stream that emits a [BuildResult] each time the build is completed,
  /// whether or not it succeeded.
  ///
  /// This will emit a result only once every package's [AssetCascade] has
  /// finished building.
  ///
  /// If an unexpected error in barback itself occurs, it will be emitted
  /// through this stream's error channel.
  Stream<BuildResult> get results => _graph.results;

  /// A stream that emits any errors from the graph or the transformers.
  ///
  /// This emits errors as they're detected. If an error occurs in one part of
  /// the graph, unrelated parts will continue building.
  ///
  /// This will not emit programming errors from barback itself. Those will be
  /// emitted through the [results] stream's error channel.
  Stream get errors => _graph.errors;

  /// The stream of [LogEntry] objects used to report transformer log entries.
  ///
  /// If this stream has listeners, then log entries will go to that.
  /// Otherwise, a default logger will display them.
  Stream<LogEntry> get log => _graph.log;

  Barback(PackageProvider provider)
      : _graph = new PackageGraph(provider);

  /// Gets the asset identified by [id].
  ///
  /// If [id] is for a generated or transformed asset, this will wait until
  /// it has been created and return it. If the asset cannot be found, throws
  /// [AssetNotFoundException].
  Future<Asset> getAssetById(AssetId id) {
    return _graph.getAssetNode(id).then((node) {
      if (node == null) throw new AssetNotFoundException(id);
      return node.asset;
    });
  }

  /// Adds [sources] to the graph's known set of source assets.
  ///
  /// Begins applying any transforms that can consume any of the sources. If a
  /// given source is already known, it is considered modified and all
  /// transforms that use it will be re-applied.
  void updateSources(Iterable<AssetId> sources) =>
      _graph.updateSources(sources);

  /// Removes [removed] from the graph's known set of source assets.
  void removeSources(Iterable<AssetId> removed) =>
      _graph.removeSources(removed);

  /// Gets all output assets.
  ///
  /// If a build is currently in progress, waits until it completes. The
  /// returned future will complete with a [BarbackException] if the build is
  /// not successful.
  Future<AssetSet> getAllAssets() => _graph.getAllAssets();

  /// Sets the transformer phases for [package]'s assets to [transformers].
  ///
  /// To the extent that [transformers] is similar to the previous transformer
  /// phases for [package], the existing asset graph will be preserved.
  ///
  /// Elements of the inner iterable of [transformers] must be either
  /// [Transformer]s or [TransformerGroup]s.
  void updateTransformers(String package,
          Iterable<Iterable> transformers) =>
      _graph.updateTransformers(package, transformers);
}
