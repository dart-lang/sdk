// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.transformer_id;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;

import '../io.dart';
import '../utils.dart';

/// A list of the names of all built-in transformers that pub exposes.
const _BUILT_IN_TRANSFORMERS = const ['\$dart2js'];

/// An identifier that indicates the library that contains a transformer.
///
/// It's possible that the library identified by [this] defines multiple
/// transformers. If so, they're all always loaded in the same phase.
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

  /// Whether this ID points to a built-in transformer exposed by pub.
  bool get isBuiltInTransformer => package.startsWith('\$');

  /// Parses a transformer identifier.
  ///
  /// A transformer identifier is a string of the form "package_name" or
  /// "package_name/path/to/library". It does not have a trailing extension. If
  /// it just has a package name, it expands to lib/transformer.dart if that
  /// exists, or lib/${package}.dart otherwise. Otherwise, it expands to
  /// lib/${path}.dart. In either case it's located in the given package.
  factory TransformerId.parse(String identifier) {
    if (identifier.isEmpty) {
      throw new FormatException('Invalid library identifier: "".');
    }

    var parts = split1(identifier, "/");
    if (parts.length == 1) {
      return new TransformerId(parts.single, null);
    }

    return new TransformerId(parts.first, parts.last);
  }

  TransformerId(this.package, this.path) {
    if (!package.startsWith('\$')) return;
    if (_BUILT_IN_TRANSFORMERS.contains(package)) return;
    throw new FormatException('Unsupported built-in transformer $package.');
  }

  bool operator==(other) =>
      other is TransformerId && other.package == package && other.path == path;

  int get hashCode => package.hashCode ^ path.hashCode;

  String toString() => path == null ? package : '$package/$path';

  /// Returns the asset id for the library identified by this transformer id.
  ///
  /// If `path` is null, this will determine which library to load. Unlike
  /// [getAssetId], this doesn't take generated assets into account; it's used
  /// to determine transformers' dependencies, which requires looking at files
  /// on disk.
  Future<AssetId> getAssetId(Barback barback) {
    if (path != null) {
      return new Future.value(new AssetId(package, 'lib/$path.dart'));
    }

    var transformerAsset = new AssetId(package, 'lib/transformer.dart');
    return barback.getAssetById(transformerAsset).then((_) => transformerAsset)
        .catchError((e) => new AssetId(package, 'lib/$package.dart'),
            test: (e) => e is AssetNotFoundException);
  }

  /// Returns the path to the library identified by this transformer within
  /// [packageDir], which should be the directory of [package].
  ///
  /// If `path` is null, this will determine which library to load.
  String getFullPath(String packageDir) {
    if (path != null) return p.join(packageDir, 'lib', p.fromUri('$path.dart'));

    var transformerPath = p.join(packageDir, 'lib', 'transformer.dart');
    if (fileExists(transformerPath)) return transformerPath;
    return p.join(packageDir, 'lib', '$package.dart');
  }
}
