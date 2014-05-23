// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common methods used by transfomers for dealing with asset IDs.
library code_transformers.assets;

import 'dart:math' show min, max;

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:source_maps/span.dart' show Span;

/// Create an [AssetId] for a [url] seen in the [source] asset.
///
/// By default this is used to resolve relative urls that occur in HTML assets,
/// including cross-package urls of the form "packages/foo/bar.html". Dart
/// "package:" urls are not resolved unless [source] is Dart file (has a .dart
/// extension).
///
/// This function returns null if [url] can't be resolved. We log a warning
/// message in [logger] if we know the reason why resolution failed. This
/// happens, for example, when using incorrect paths to reach into another
/// package, or when [errorsOnAbsolute] is true and the url seems to be
/// absolute.
// TODO(sigmund): delete once this is part of barback (dartbug.com/12610)
AssetId uriToAssetId(AssetId source, String url, TransformLogger logger,
    Span span, {bool errorOnAbsolute: true}) {
  if (url == null || url == '') return null;
  var uri = Uri.parse(url);
  var urlBuilder = path.url;
  if (uri.host != '' || uri.scheme != '' || urlBuilder.isAbsolute(url)) {
    if (source.extension == '.dart' && uri.scheme == 'package') {
      var index = uri.path.indexOf('/');
      if (index != -1) {
        return new AssetId(uri.path.substring(0, index),
            'lib${uri.path.substring(index)}');
      }
    }

    if (errorOnAbsolute) {
      logger.warning('absolute paths not allowed: "$url"', span: span);
    }
    return null;
  }

  var targetPath = urlBuilder.normalize(
      urlBuilder.join(urlBuilder.dirname(source.path), url));
  var segments = urlBuilder.split(targetPath);
  var sourceSegments = urlBuilder.split(source.path);
  assert (sourceSegments.length > 0);
  var topFolder = sourceSegments[0];
  var entryFolder = topFolder != 'lib' && topFolder != 'asset';

  // Find the first 'packages/'  or 'assets/' segment:
  var packagesIndex = segments.indexOf('packages');
  var assetsIndex = segments.indexOf('assets');
  var index = (packagesIndex >= 0 && assetsIndex >= 0)
      ? min(packagesIndex, assetsIndex)
      : max(packagesIndex, assetsIndex);
  if (index > -1) {
    if (entryFolder) {
      // URLs of the form "packages/foo/bar" seen under entry folders (like
      // web/, test/, example/, etc) are resolved as an asset in another
      // package. 'packages' can be used anywhere, there is no need to walk up
      // where the entrypoint file was.
      // TODO(sigmund): this needs to change: Only resolve when index == 1 &&
      // topFolder == segment[0], otherwise give a warning (dartbug.com/17596).
      return _extractOtherPackageId(index, segments, logger, span);
    } else if (index == 1 && segments[0] == '..') {
      // Relative URLs of the form "../../packages/foo/bar" in an asset under
      // lib/ or asset/ are also resolved as an asset in another package, but we
      // check that the relative path goes all the way out where the packages
      // folder lives (otherwise the app would not work in Dartium). Since
      // [targetPath] has been normalized, "packages" or "assets" should be at
      // index 1.
      return _extractOtherPackageId(1, segments, logger, span);
    } else {
      var prefix = segments[index];
      var fixedSegments = [];
      fixedSegments.addAll(sourceSegments.map((_) => '..'));
      fixedSegments.addAll(segments.sublist(index));
      var fixedUrl = urlBuilder.joinAll(fixedSegments);
      logger.warning('Invalid url to reach to another package: $url. Path '
          'reaching to other packages must first reach up all the '
          'way to the $prefix folder. For example, try changing the url above '
          'to: $fixedUrl', span: span);
      return null;
    }
  }

  // Otherwise, resolve as a path in the same package.
  return new AssetId(source.package, targetPath);
}

AssetId _extractOtherPackageId(int index, List segments,
    TransformLogger logger, Span span) {
  if (index >= segments.length) return null;
  var prefix = segments[index];
  if (prefix != 'packages' && prefix != 'assets') return null;
  var folder = prefix == 'packages' ? 'lib' : 'asset';
  if (segments.length < index + 3) {
    logger.warning("incomplete $prefix/ path. It should have at least 3 "
        "segments $prefix/name/path-from-name's-$folder-dir", span: span);
    return null;
  }
  return new AssetId(segments[index + 1],
      path.url.join(folder, path.url.joinAll(segments.sublist(index + 2))));
}
