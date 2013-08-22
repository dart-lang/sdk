// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.pub_package_provider;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import 'entrypoint.dart';

/// An implementation of barback's [PackageProvider] interface so that barback
/// can assets within pub packages.
class PubPackageProvider implements PackageProvider {
  /// Maps the names of all of the packages in [_entrypoint]'s transitive
  /// dependency graph to the local path of the directory for that package.
  final Map<String, String> _packageDirs;

  /// Creates a new provider for [entrypoint].
  static Future<PubPackageProvider> create(Entrypoint entrypoint) {
    var packageDirs = <String, String>{};

    packageDirs[entrypoint.root.name] = entrypoint.root.dir;

    // Cache package directories up front so we can have synchronous access
    // to them.
    var futures = [];
    entrypoint.loadLockFile().packages.forEach((name, package) {
      var source = entrypoint.cache.sources[package.source];
      futures.add(source.getDirectory(package).then((packageDir) {
        packageDirs[name] = packageDir;
      }));
    });

    return Future.wait(futures).then((_) {
      return new PubPackageProvider._(packageDirs);
    });
  }

  PubPackageProvider._(this._packageDirs);

  Iterable<String> get packages => _packageDirs.keys;

  /// Gets the root directory of [package].
  String getPackageDir(String package) => _packageDirs[package];

  Future<Asset> getAsset(AssetId id) {
    var file = path.join(_packageDirs[id.package], id.path);
    return new Future.value(new Asset.fromPath(id, file));
  }
}
