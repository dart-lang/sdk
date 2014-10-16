// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.source.cached;

import 'dart:async';

import 'package:path/path.dart' as path;

import '../io.dart';
import '../package.dart';
import '../pubspec.dart';
import '../source.dart';
import '../utils.dart';

/// Base class for a [Source] that installs packages into pub's [SystemCache].
///
/// A source should be cached if it requires network access to retrieve
/// packages or the package needs to be "frozen" at the point in time that it's
/// installed. (For example, Git packages are cached because installing from
/// the same repo over time may yield different commits.)
abstract class CachedSource extends Source {
  /// The root directory of this source's cache within the system cache.
  ///
  /// This shouldn't be overridden by subclasses.
  String get systemCacheRoot => path.join(systemCache.rootDir, name);

  /// If [id] is already in the system cache, just loads it from there.
  ///
  /// Otherwise, defers to the subclass.
  Future<Pubspec> doDescribe(PackageId id) {
    return getDirectory(id).then((packageDir) {
      if (fileExists(path.join(packageDir, "pubspec.yaml"))) {
        return new Pubspec.load(
            packageDir,
            systemCache.sources,
            expectedName: id.name);
      }

      return describeUncached(id);
    });
  }

  /// Loads the (possibly remote) pubspec for the package version identified by
  /// [id].
  ///
  /// This will only be called for packages that have not yet been installed in
  /// the system cache.
  Future<Pubspec> describeUncached(PackageId id);

  Future get(PackageId id, String symlink) {
    return downloadToSystemCache(id).then((pkg) {
      createPackageSymlink(id.name, pkg.dir, symlink);
    });
  }

  /// Determines if the package with [id] is already downloaded to the system
  /// cache.
  Future<bool> isInSystemCache(PackageId id) =>
      getDirectory(id).then(dirExists);

  /// Downloads the package identified by [id] to the system cache.
  Future<Package> downloadToSystemCache(PackageId id);

  /// Returns the [Package]s that have been downloaded to the system cache.
  List<Package> getCachedPackages();

  /// Reinstalls all packages that have been previously installed into the
  /// system cache by this source.
  ///
  /// Returns a [Pair] whose first element is the number of packages
  /// successfully repaired and the second is the number of failures.
  Future<Pair<int, int>> repairCachedPackages();
}
