// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.cached_package;

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'barback/transformer_config.dart';
import 'io.dart';
import 'package.dart';
import 'pubspec.dart';
import 'version.dart';

/// A [Package] whose `lib` directory has been precompiled and cached.
///
/// When users of this class request path information about files that are
/// cached, this returns the cached information. It also wraps the package's
/// pubspec to report no transformers, since the transformations have all been
/// applied already.
class CachedPackage extends Package {
  /// The directory contianing the cached assets from this package.
  ///
  /// Although only `lib` is cached, this directory corresponds to the root of
  /// the package. The actual cached assets exist in `$_cacheDir/lib`.
  final String _cacheDir;

  /// Creates a new cached package wrapping [inner] with the cache at
  /// [_cacheDir].
  CachedPackage(Package inner, this._cacheDir)
      : super(new _CachedPubspec(inner.pubspec), inner.dir);

  String path(String part1, [String part2, String part3, String part4,
      String part5, String part6, String part7]) {
    if (_pathInCache(part1)) {
      return p.join(_cacheDir, part1, part2, part3, part4, part5, part6, part7);
    } else {
      return super.path(part1, part2, part3, part4, part5, part6, part7);
    }
  }

  String relative(String path) {
    if (p.isWithin(path, _cacheDir)) return p.relative(path, from: _cacheDir);
    return super.relative(path);
  }

  /// This will include the cached, transformed versions of files if [beneath]
  /// is within a cached directory, but not otherwise.
  List<String> listFiles({String beneath, recursive: true,
      bool useGitIgnore: false}) {
    if (beneath == null) {
      return super.listFiles(recursive: recursive, useGitIgnore: useGitIgnore);
    }

    if (_pathInCache(beneath)) return listDir(p.join(_cacheDir, beneath));
    return super.listFiles(beneath: beneath, recursive: recursive,
        useGitIgnore: useGitIgnore);
  }

  /// Returns whether [relativePath], a path relative to the package's root,
  /// is in a cached directory.
  bool _pathInCache(String relativePath) => p.isWithin('lib', relativePath);
}

/// A pubspec wrapper that reports no transformers.
class _CachedPubspec implements Pubspec {
  final Pubspec _inner;

  YamlMap get fields => _inner.fields;
  String get name => _inner.name;
  Version get version => _inner.version;
  List<PackageDep> get dependencies => _inner.dependencies;
  List<PackageDep> get devDependencies => _inner.devDependencies;
  List<PackageDep> get dependencyOverrides => _inner.dependencyOverrides;
  PubspecEnvironment get environment => _inner.environment;
  String get publishTo => _inner.publishTo;
  Map<String, String> get executables => _inner.executables;
  bool get isPrivate => _inner.isPrivate;
  bool get isEmpty => _inner.isEmpty;
  List<PubspecException> get allErrors => _inner.allErrors;

  List<Set<TransformerConfig>> get transformers => const [];

  _CachedPubspec(this._inner);
}
