// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.transformer.asset_universe;

import 'dart:async';

import 'package:analyzer/analyzer.dart' show UriBasedDirective, parseDirectives;
import 'package:barback/barback.dart' show Asset, AssetId;

import 'asset_source.dart';
import 'uri_resolver.dart' show assetIdToUri, resolveAssetId;

/// Set of assets sources available for analysis / compilation.
class AssetUniverse {
  final _assetCache = <AssetId, AssetSource>{};

  Iterable<AssetId> get assetIds => _assetCache.keys;

  AssetSource getAssetSource(AssetId id) {
    var source = _assetCache[id];
    if (source == null) {
      throw new ArgumentError(id.toString());
    }
    return source;
  }

  /// Recursively loads the asset with [id] and all its transitive dependencies.
  Future scanSources(AssetId id, Future<Asset> getInput(AssetId id)) async {
    if (_assetCache.containsKey(id)) return;

    var asset = await getInput(id);
    var contents = await asset.readAsString();
    _assetCache[id] =
        new AssetSource(Uri.parse(assetIdToUri(id)), asset, contents);

    var deps = _getDependentAssetIds(id, contents);
    await Future.wait(deps.map((depId) => scanSources(depId, getInput)));
  }

  Iterable<AssetId> _getDependentAssetIds(AssetId id, String contents) sync* {
    var directives = parseDirectives(contents, suppressErrors: true).directives;
    for (var directive in directives) {
      if (directive is UriBasedDirective) {
        var uri = directive.uri.stringValue;
        var assetId = resolveAssetId(Uri.parse(uri), fromAssetId: id);
        if (assetId != null) yield assetId;
      }
    }
  }
}
