// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.pub_package_provider;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import 'entrypoint.dart';
import 'io.dart';

/// An implementation of barback's [PackageProvider] interface so that barback
/// can assets within pub packages.
class PubPackageProvider implements PackageProvider {
  /// The [Entrypoint] package being served.
  final Entrypoint _entrypoint;

  /// Maps the names of all of the packages in [_entrypoint]'s transitive
  /// dependency graph to the local path of the directory for that package.
  final Map<String, String> _packageDirs;

  /// Creates a new provider for [entrypoint].
  static Future<PubPackageProvider> create(Entrypoint entrypoint) {
    var packageDirs = <String, String>{};

    packageDirs[entrypoint.root.name] = entrypoint.root.dir;

    // Cache package directories up front so we can have synchronous access
    // to them.
    // TODO(rnystrom): Handle missing or out of date lockfile.
    var futures = [];
    entrypoint.loadLockFile().packages.forEach((name, package) {
      var source = entrypoint.cache.sources[package.source];
      futures.add(source.getDirectory(package).then((packageDir) {
        packageDirs[name] = packageDir;
      }));
    });

    return Future.wait(futures).then((_) {
      return new PubPackageProvider._(entrypoint, packageDirs);
    });
  }

  PubPackageProvider._(this._entrypoint, this._packageDirs);

  Iterable<String> get packages => _packageDirs.keys;

  /// Lists all of the visible files in [package].
  ///
  /// This is the recursive contents of the "asset" and "lib" directories (if
  /// present). If [package] is the entrypoint package, it also includes the
  /// contents of "web".
  List<AssetId> listAssets(String package) {
    var files = <AssetId>[];

    addFiles(String dirPath) {
      var packageDir = _packageDirs[package];
      var dir = path.join(packageDir, dirPath);
      if (!dirExists(dir)) return;
      for (var entry in listDir(dir, recursive: true)) {
        // Ignore "packages" symlinks if there.
        if (path.split(entry).contains("packages")) continue;

        // Skip directories.
        if (!fileExists(entry)) continue;

        // AssetId paths use "/" on all platforms.
        var relative = path.relative(entry, from: packageDir);
        relative = path.toUri(relative).path;
        files.add(new AssetId(package, relative));
      }
    }

    // Expose the "asset" and "lib" directories.
    addFiles("asset");
    addFiles("lib");

    // The entrypoint's "web" directory is also visible.
    if (package == _entrypoint.root.name) {
      addFiles("web");
    }

    return files;
  }

  // TODO(rnystrom): Actually support transformers.
  Iterable<Iterable<Transformer>> getTransformers(String package) => [];

  Future<Asset> getAsset(AssetId id) {
    var file = path.join(_packageDirs[id.package], id.path);
    return new Future.value(new Asset.fromPath(id, file));
  }
}
