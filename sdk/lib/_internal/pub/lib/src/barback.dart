// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import 'utils.dart';
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
/// This includes a string literal of Dart code ([_TRANSFORMER_ISOLATE] in
/// load_transformers.dart). That code imports "package:barback/barback.dart".
/// This string is included in the SDK, but that import is resolved using the
/// application’s version of Barback. That means it must tightly control which
/// version of Barback the application is using so that it's one that pub
/// supports.
///
/// Whenever a new non-patch version of barback is published, this *must* be
/// incremented to synchronize with that.
final supportedVersions = new VersionConstraint.parse(">=0.11.0 <0.13.0");

/// A list of the names of all built-in transformers that pub exposes.
const _BUILT_IN_TRANSFORMERS = const ['\$dart2js'];

/// An identifier for a transformer and the configuration that will be passed to
/// it.
///
/// It's possible that the library identified by [this] defines multiple
/// transformers. If so, [configuration] will be passed to all of them.
class TransformerId {
  /// The package containing the library where the transformer is defined.
  final String package;

  /// The `/`-separated path to the library that contains this transformer.
  ///
  /// This is relative to the `lib/` directory in [package], and doesn't end in
  /// `.dart`.
  ///
  /// This can be null; if so, it indicates that the transformer(s) should be
  /// loaded from `lib/transformer.dart` if that exists, and `lib/$package.dart`
  /// otherwise.
  final String path;

  /// The configuration to pass to the transformer.
  ///
  /// This will be an empty map if no configuration was provided.
  final Map configuration;

  /// Whether this ID points to a built-in transformer exposed by pub.
  bool get isBuiltInTransformer => package.startsWith('\$');

  /// Parses a transformer identifier.
  ///
  /// A transformer identifier is a string of the form "package_name" or
  /// "package_name/path/to/library". It does not have a trailing extension. If
  /// it just has a package name, it expands to lib/transformer.dart if that
  /// exists, or lib/${package}.dart otherwise. Otherwise, it expands to
  /// lib/${path}.dart. In either case it's located in the given package.
  factory TransformerId.parse(String identifier, Map configuration) {
    if (identifier.isEmpty) {
      throw new FormatException('Invalid library identifier: "".');
    }

    var parts = split1(identifier, "/");
    if (parts.length == 1) {
      return new TransformerId(parts.single, null, configuration);
    }
    return new TransformerId(parts.first, parts.last, configuration);
  }

  TransformerId(this.package, this.path, Map configuration)
      : configuration = configuration == null ? {} : configuration {
    if (!package.startsWith('\$')) return;
    if (_BUILT_IN_TRANSFORMERS.contains(package)) return;
    throw new FormatException('Unsupported built-in transformer $package.');
  }

  // TODO(nweiz): support deep equality on [configuration] as well.
  bool operator==(other) => other is TransformerId &&
      other.package == package &&
      other.path == path &&
      other.configuration == configuration;

  int get hashCode => package.hashCode ^ path.hashCode ^ configuration.hashCode;

  String toString() => path == null ? package : '$package/$path';

  /// Returns the asset id for the library identified by this transformer id.
  ///
  /// If `path` is null, this will determine which library to load.
  Future<AssetId> getAssetId(Barback barback) {
    if (path != null) {
      return new Future.value(new AssetId(package, 'lib/$path.dart'));
    }

    var transformerAsset = new AssetId(package, 'lib/transformer.dart');
    return barback.getAssetById(transformerAsset).then((_) => transformerAsset)
        .catchError((e) => new AssetId(package, 'lib/$package.dart'),
            test: (e) => e is AssetNotFoundException);
  }
}

/// Converts [id] to a "package:" URI.
///
/// This will throw an [ArgumentError] if [id] doesn't represent a library in
/// `lib/`.
Uri idToPackageUri(AssetId id) {
  if (!id.path.startsWith('lib/')) {
    throw new ArgumentError("Asset id $id doesn't identify a library.");
  }

  return new Uri(scheme: 'package', path: id.path.replaceFirst('lib/', ''));
}

/// Converts [uri] into an [AssetId] if its path is within "packages" or
/// "assets".
///
/// While "packages" can appear anywhere in the path, "assets" is only allowed
/// as the top-level directory. (This throws a [FormatException] if "assets"
/// appears anywhere else.)
///
/// If the URL contains a special directory, but lacks a following package name,
/// throws a [FormatException].
///
/// If the URI doesn't contain one of those special directories, returns null.
AssetId specialUrlToId(Uri url) {
  var parts = path.url.split(url.path);

  // Strip the leading "/" from the URL.
  if (parts.isNotEmpty && parts.first == "/") parts = parts.skip(1).toList();

  if (parts.isEmpty) return null;

  // Check for "assets" at the beginning of the URL.
  if (parts.first == "assets") {
    if (parts.length <= 1) {
      throw new FormatException(
          'Invalid URL path "${url.path}". Expected package name after '
          '"assets".');
    }

    var package = parts[1];
    var assetPath = path.url.join("asset", path.url.joinAll(parts.skip(2)));
    return new AssetId(package, assetPath);
  }

  // Check for "packages" anywhere in the URL.
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
  var assetPath = path.url.join("lib", path.url.joinAll(parts.skip(index + 2)));
  return new AssetId(package, assetPath);
}

/// Converts [id] to a "servable path" for that asset.
///
/// This is the root relative URL that could be used to request that asset from
/// pub serve. It's also the relative path that the asset will be output to by
/// pub build (except this always returns a path using URL separators).
///
/// [entrypoint] is the name of the entrypoint package.
///
/// Examples (where [entrypoint] is "myapp"):
///
///     myapp|web/index.html   -> /index.html
///     myapp|lib/lib.dart     -> /packages/myapp/lib.dart
///     foo|lib/foo.dart       -> /packages/foo/foo.dart
///     foo|asset/foo.png      -> /assets/foo/foo.png
///     myapp|test/main.dart   -> ERROR
///     foo|web/
///
/// Throws a [FormatException] if [id] is not a valid public asset.
// TODO(rnystrom): Get rid of [useWebAsRoot] once pub serve also serves out of
// the package root directory.
String idtoUrlPath(String entrypoint, AssetId id, {bool useWebAsRoot: true}) {
  var parts = path.url.split(id.path);

  if (parts.length < 2) {
    throw new FormatException(
        "Can not serve assets from top-level directory.");
  }

  // Map "asset" and "lib" to their shared directories.
  var dir = parts[0];
  var rest = parts.skip(1);

  if (dir == "asset") {
    return path.url.join("/", "assets", id.package, path.url.joinAll(rest));
  }

  if (dir == "lib") {
    return path.url.join("/", "packages", id.package, path.url.joinAll(rest));
  }

  if (useWebAsRoot) {
    if (dir != "web") {
      throw new FormatException('Cannot access assets from "$dir".');
    }

    if (id.package != entrypoint) {
      throw new FormatException(
          'Cannot access "web" directory of non-root packages.');
    }

    return path.url.join("/", path.url.joinAll(rest));
  }

  if (id.package != entrypoint) {
    throw new FormatException(
        'Can only access "lib" and "asset" directories of non-entrypoint '
    'packages.');
  }

  // Allow any path in the entrypoint package.
  return path.url.join("/", path.url.joinAll(parts));
}
