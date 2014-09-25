// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.graph.static_asset_cascade;

import 'dart:async';

import '../asset/asset_id.dart';
import '../asset/asset_node.dart';
import '../asset/asset_set.dart';
import '../errors.dart';
import '../log.dart';
import '../package_provider.dart';
import 'asset_cascade.dart';
import 'node_status.dart';
import 'package_graph.dart';

/// An asset cascade for a static package.
///
/// A static package is known to have no transformers and no changes to its
/// assets. This allows this class to lazily and efficiently provide assets to
/// the rest of the package graph.
class StaticAssetCascade implements AssetCascade {
  final String package;

  final PackageGraph graph;

  /// All sources that have been requested from the provider.
  final _sources = new Map<AssetId, Future<AssetNode>>();

  StaticAssetCascade(this.graph, this.package);

  Stream<BarbackException> get errors => _errorsController.stream;
  final _errorsController =
      new StreamController<BarbackException>.broadcast(sync: true);

  final status = NodeStatus.IDLE;

  final onLog = new StreamController<LogEntry>.broadcast().stream;
  final onStatusChange = new StreamController<LogEntry>.broadcast().stream;

  Future<AssetSet> get availableOutputs {
    var provider = graph.provider as StaticPackageProvider;
    return provider.getAllAssetIds(package).asyncMap(provider.getAsset).toList()
        .then((assets) => new AssetSet.from(assets));
  }

  Future<AssetNode> getAssetNode(AssetId id) {
    return _sources.putIfAbsent(id, () {
      return graph.provider.getAsset(id).then((asset) {
        return new AssetNodeController.available(asset).node;
      }).catchError((error, stackTrace) {
        if (error is! AssetNotFoundException) {
          reportError(new AssetLoadException(id, error, stackTrace));
        }

        // TODO(nweiz): propagate error information through asset nodes.
        return null;
      });
    });
  }

  void updateSources(Iterable<AssetId> sources) =>
      throw new UnsupportedError("Static package $package can't be explicitly "
          "provided sources.");

  void removeSources(Iterable<AssetId> sources) =>
      throw new UnsupportedError("Static package $package can't be explicitly "
          "provided sources.");

  void updateTransformers(Iterable<Iterable> transformersIterable) =>
      throw new UnsupportedError("Static package $package can't have "
          "transformers.");

  void forceAllTransforms() {}

  void reportError(BarbackException error) => _errorsController.add(error);

  String toString() => "static cascade for $package";
}
