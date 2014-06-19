// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback;

import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;

import 'version.dart';

/// The currently supported versions of the Barback package that this version of
/// pub works with.
///
/// Pub implicitly constrains barback to these versions.
///
/// Barback is in a unique position. Pub imports it, so a copy of Barback is
/// physically included in the SDK. Packages also depend on Barback (from
/// pub.dartlang.org) when they implement their own transformers. Pub's plug-in
/// API dynamically loads transformers into their own isolate.
///
/// This includes a Dart file (`asset/dart/transformer_isolate.dart`) which
/// imports "package:barback/barback.dart". This file is included in the SDK,
/// but that import is resolved using the application’s version of Barback. That
/// means pub must tightly control which version of Barback the application is
/// using so that it's one that pub supports.
///
/// Whenever a new minor or patch version of barback is published, this *must*
/// be incremented to synchronize with that. See the barback [compatibility
/// documentation][compat] for details on the relationship between this
/// constraint and barback's version.
///
/// [compat]: https://gist.github.com/nex3/10942218
final supportedVersions = new VersionConstraint.parse(">=0.13.0 <0.14.2");

/// Converts [id] to a "package:" URI.
///
/// This will throw an [ArgumentError] if [id] doesn't represent a library in
/// `lib/`.
Uri idToPackageUri(AssetId id) {
  if (!id.path.startsWith('lib/')) {
    throw new ArgumentError("Asset id $id doesn't identify a library.");
  }

  return new Uri(scheme: 'package',
      path: p.url.join(id.package, id.path.replaceFirst('lib/', '')));
}

/// Converts [uri] into an [AssetId] if its path is within "packages".
///
/// If the URL contains a special directory, but lacks a following package name,
/// throws a [FormatException].
///
/// If the URI doesn't contain one of those special directories, returns null.
AssetId packagesUrlToId(Uri url) {
  var parts = p.url.split(url.path);

  // Strip the leading "/" from the URL.
  if (parts.isNotEmpty && parts.first == "/") parts = parts.skip(1).toList();

  if (parts.isEmpty) return null;

  // Check for "packages" in the URL.
  // TODO(rnystrom): If we rewrite "package:" imports to relative imports that
  // point to a canonical "packages" directory, we can limit "packages" to the
  // root of the URL as well. See: #16649.
  var index = parts.indexOf("packages");
  if (index == -1) return null;

  // There should be a package name after "packages".
  if (parts.length <= index + 1) {
    throw new FormatException(
        'Invalid URL path "${url.path}". Expected package name '
        'after "packages".');
  }

  var package = parts[index + 1];
  var assetPath = p.url.join("lib", p.url.joinAll(parts.skip(index + 2)));
  return new AssetId(package, assetPath);
}
