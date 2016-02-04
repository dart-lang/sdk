// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.transformer.uri_resolver;

import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart' show Source, SourceFactory;
import 'package:barback/barback.dart' show AssetId;
import 'package:code_transformers/resolver.dart'
    show DartUriResolverProxy, DirectoryBasedDartSdkProxy;
import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:path/path.dart' as path;

import 'asset_source.dart';

typedef AssetSource AssetSourceGetter(AssetId id);

/// Builds a package URI that corresponds to [id]. This is roughly the inverse
/// function of [resolveAssetId].
///
/// Note that if [id] points to a file outside the package's `lib` folder, that
/// file must be under `web` and the returned URI will not strictly correspond
/// to classic package URIs (but it will be invertible by [resolveAssetId]).
String assetIdToUri(AssetId id) {
  var p = id.path;
  if (p.startsWith('lib/web/')) {
    throw new ArgumentError('Cannot convert $id to an unambiguous package uri');
  }
  if (p.startsWith('lib/')) {
    p = p.substring('lib/'.length);
  } else if (!p.startsWith('web/')) {
    throw new ArgumentError('Unexpected path in $id (expected {lib,web}/*');
  }
  // Note: if the file is under web/, then we leave it as it is: resolveAssetId
  // does the inverse transform.
  return 'package:${id.package}/$p';
}

/// Gets the [AssetId] that corresponds to [uri].
///
/// If [fromAssetId] is not `null` and if [uri] is a relative URI, then
/// [fromAssetId] will be used to resolve the create a relative URI. In other
/// cases, this is roughly the inverse function of [assetIdToUri].
AssetId resolveAssetId(Uri uri, {AssetId fromAssetId}) {
  if (uri.scheme == 'dart') return null;

  if (uri.scheme == 'package') {
    var segments = uri.pathSegments.toList();
    var package = segments[0];
    if (segments[1] == 'web') {
      return new AssetId(package, path.url.joinAll(segments.skip(1)));
    } else {
      segments[0] = 'lib';
      return new AssetId(package, path.url.joinAll(segments));
    }
  }

  if (uri.scheme == null || uri.scheme == '') {
    if (fromAssetId == null) {
      throw new ArgumentError('No asset to resolve relative URI from.');
    }
    return new AssetId(fromAssetId.package,
        path.normalize(path.join(path.dirname(fromAssetId.path), uri.path)));
  }

  throw new ArgumentError('Unexpected uri: $uri (uri.scheme = ${uri.scheme})');
}

class _DdcUriResolver extends DartUriResolverProxy {
  AssetSourceGetter _getAssetSource;

  _DdcUriResolver(DartSdk sdk, this._getAssetSource) : super(sdk);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    return uri.scheme == 'package'
        ? _getAssetSource(resolveAssetId(uri))
        : super.resolveAbsolute(uri, actualUri);
  }
}

String get dartSdkDirectory => cli_util.getSdkDir()?.path;

SourceFactory createSourceFactory(AssetSourceGetter getAssetSource) {
  var sdk = new DirectoryBasedDartSdkProxy(dartSdkDirectory);
  return new SourceFactory([new _DdcUriResolver(sdk, getAssetSource)]);
}
