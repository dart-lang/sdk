// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback;

import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;

import 'version.dart';

/// The currently supported versions of packages that this version of pub works
/// with.
///
/// Pub implicitly constrains these packages to these versions as long as
/// barback is a dependency.
///
/// Users' transformers are loaded in an isolate that uses the entrypoint
/// package's dependency versions. However, that isolate also loads code
/// provided by pub (`asset/dart/transformer_isolate.dart` and associated
/// files). This code uses these packages as well, so these constraints exist to
/// ensure that its usage of the packages remains valid.
///
/// Most constraints here are like normal version constraints in that their
/// upper bound is the next major version of the package (or minor version for
/// pre-1.0.0 packages). If a new major version of the package is released,
/// these *must* be incremented to synchronize with that.
///
/// The constraint on barback is different. Its upper bound is the next *patch*
/// version of barback—that is, the next version with new features. This is
/// because most barback features need additional serialization code to be fully
/// supported in pub, even if they're otherwise backwards-compatible.
///
/// Whenever a new minor or patch version of barback is published, this *must*
/// be incremented to synchronize with that. See the barback [compatibility
/// documentation][compat] for details on the relationship between this
/// constraint and barback's version.
///
/// [compat]: https://gist.github.com/nex3/10942218
final pubConstraints = {
  "barback": new VersionConstraint.parse(">=0.13.0 <0.14.2"),
  "source_maps": new VersionConstraint.parse(">=0.9.0 <0.10.0"),
  "stack_trace": new VersionConstraint.parse(">=0.9.1 <2.0.0")
};

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
