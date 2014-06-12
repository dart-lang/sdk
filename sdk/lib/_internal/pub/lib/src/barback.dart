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
  /// Any pub-specific configuration (i.e. keys starting with "$") will have
  /// been stripped out of this and handled separately. This will be an empty
  /// map if no configuration was provided.
  final Map configuration;

  /// The primary input inclusions.
  ///
  /// Each inclusion is an asset path. If this set is non-empty, than *only*
  /// matching assets are allowed as a primary input by this transformer. If
  /// `null`, all assets are included.
  ///
  /// This is processed before [excludes]. If a transformer has both includes
  /// and excludes, then the set of included assets is determined and assets
  /// are excluded from that resulting set.
  final Set<String> includes;

  /// The primary input exclusions.
  ///
  /// Any asset whose pach is in this is not allowed as a primary input by
  /// this transformer.
  ///
  /// This is processed after [includes]. If a transformer has both includes
  /// and excludes, then the set of included assets is determined and assets
  /// are excluded from that resulting set.
  final Set<String> excludes;

  /// Whether this ID points to a built-in transformer exposed by pub.
  bool get isBuiltInTransformer => package.startsWith('\$');

  /// Returns whether this id excludes certain asset ids from being processed.
  bool get hasExclusions => includes != null || excludes != null;

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

  factory TransformerId(String package, String path, Map configuration) {
    parseField(key) {
      if (!configuration.containsKey(key)) return null;
      var field = configuration.remove(key);

      if (field is String) return new Set<String>.from([field]);

      if (field is List) {
        var nonstrings = field
            .where((element) => element is! String)
            .map((element) => '"$element"');

        if (nonstrings.isNotEmpty) {
          throw new FormatException(
              '"$key" list field may only contain strings, but contained '
              '${toSentence(nonstrings)}.');
        }

        return new Set<String>.from(field);
      } else {
        throw new FormatException(
            '"$key" field must be a string or list, but was "$field".');
      }
    }

    var includes = null;
    var excludes = null;

    if (configuration == null) {
      configuration = {};
    } else {
      // Don't write to the immutable YAML map.
      configuration = new Map.from(configuration);

      // Pull out the exclusions/inclusions.
      includes = parseField("\$include");
      excludes = parseField("\$exclude");

      // All other keys starting with "$" are unexpected.
      var reservedKeys = configuration.keys
          .where((key) => key is String && key.startsWith(r'$'))
          .map((key) => '"$key"');

      if (reservedKeys.isNotEmpty) {
        throw new FormatException(
            'Unknown reserved ${pluralize('field', reservedKeys.length)} '
            '${toSentence(reservedKeys)}.');
      }
    }

    return new TransformerId._(package, path, configuration,
        includes, excludes);
  }

  TransformerId._(this.package, this.path, this.configuration,
      this.includes, this.excludes) {
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

  /// Returns whether the include/exclude rules allow the transformer to run on
  /// [pathWithinPackage].
  ///
  /// [pathWithinPackage] must be a path relative to the containing package's
  /// root directory.
  bool canTransform(String pathWithinPackage) {
    // TODO(rnystrom): Support globs in addition to paths. See #17093.
    if (excludes != null) {
      // If there are any excludes, it must not match any of them.
      if (excludes.contains(pathWithinPackage)) return false;
    }

    // If there are any includes, it must match one of them.
    return includes == null || includes.contains(pathWithinPackage);
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

  return new Uri(scheme: 'package',
      path: path.url.join(id.package, id.path.replaceFirst('lib/', '')));
}

/// Converts [uri] into an [AssetId] if its path is within "packages".
///
/// If the URL contains a special directory, but lacks a following package name,
/// throws a [FormatException].
///
/// If the URI doesn't contain one of those special directories, returns null.
AssetId packagesUrlToId(Uri url) {
  var parts = path.url.split(url.path);

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
  var assetPath = path.url.join("lib", path.url.joinAll(parts.skip(index + 2)));
  return new AssetId(package, assetPath);
}
