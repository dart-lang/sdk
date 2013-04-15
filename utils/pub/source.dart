// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source;

import 'dart:async';

import 'package:pathos/path.dart' as path;

import 'io.dart';
import 'package.dart';
import 'pubspec.dart';
import 'system_cache.dart';
import 'utils.dart';
import 'version.dart';

/// A source from which to install packages.
///
/// Each source has many packages that it looks up using [PackageId]s. The
/// source is responsible for installing these packages to the package cache.
abstract class Source {
  /// The name of the source. Should be lower-case, suitable for use in a
  /// filename, and unique accross all sources.
  String get name;

  /// Whether or not this source is the default source.
  bool get isDefault => systemCache.sources.defaultSource == this;

  /// Whether this source's packages should be cached in Pub's global cache
  /// directory.
  ///
  /// A source should be cached if it requires network access to retrieve
  /// packages. It doesn't need to be cached if all packages are available
  /// locally.
  bool get shouldCache;

  /// The system cache with which this source is registered.
  SystemCache get systemCache {
    assert(_systemCache != null);
    return _systemCache;
  }

  /// The system cache variable. Set by [_bind].
  SystemCache _systemCache;

  /// The root directory of this source's cache within the system cache.
  ///
  /// This shouldn't be overridden by subclasses.
  String get systemCacheRoot => path.join(systemCache.rootDir, name);

  /// Records the system cache to which this source belongs.
  ///
  /// This should only be called once for each source, by
  /// [SystemCache.register]. It should not be overridden by base classes.
  void bind(SystemCache systemCache) {
    assert(_systemCache == null);
    this._systemCache = systemCache;
  }

  /// Get the list of all versions that exist for the package described by
  /// [description]. [name] is the expected name of the package.
  ///
  /// Note that this does *not* require the packages to be installed, which is
  /// the point. This is used during version resolution to determine which
  /// package versions are available to be installed (or already installed).
  ///
  /// By default, this assumes that each description has a single version and
  /// uses [describe] to get that version.
  Future<List<Version>> getVersions(String name, description) {
    return describe(new PackageId(name, this, Version.none, description))
      .then((pubspec) => [pubspec.version]);
  }

  /// Loads the (possibly remote) pubspec for the package version identified by
  /// [id]. This may be called for packages that have not yet been installed
  /// during the version resolution process.
  ///
  /// For cached sources, by default this uses [installToSystemCache] to get the
  /// pubspec. There is no default implementation for non-cached sources; they
  /// must implement it manually.
  Future<Pubspec> describe(PackageId id) {
    if (!shouldCache) throw "Source $name must implement describe(id).";
    return installToSystemCache(id).then((package) => package.pubspec);
  }

  /// Installs the package identified by [id] to [path]. Returns a [Future] that
  /// completes when the installation was finished. The [Future] should resolve
  /// to true if the package was found in the source and false if it wasn't. For
  /// all other error conditions, it should complete with an exception.
  ///
  /// [path] is guaranteed not to exist, and its parent directory is guaranteed
  /// to exist.
  ///
  /// Note that [path] may be deleted. If re-installing a package that has
  /// already been installed would be costly or impossible,
  /// [installToSystemCache] should be implemented instead of [install].
  ///
  /// This doesn't need to be implemented if [installToSystemCache] is
  /// implemented.
  Future<bool> install(PackageId id, String path) {
    throw "Either install or installToSystemCache must be implemented for "
        "source $name.";
  }

  /// Installs the package identified by [id] to the system cache. This is only
  /// called for sources with [shouldCache] set to true.
  ///
  /// By default, this uses [systemCacheDirectory] and [install].
  Future<Package> installToSystemCache(PackageId id) {
    var packageDir;
    return systemCacheDirectory(id).then((p) {
      packageDir = p;

      // See if it's already cached.
      if (dirExists(packageDir)) {
        if (!_isCachedPackageCorrupted(packageDir)) return true;
        // Busted, so wipe out the package and reinstall.
        deleteEntry(packageDir);
      }

      ensureDir(path.dirname(packageDir));
      return install(id, packageDir);
    }).then((found) {
      if (!found) throw 'Package $id not found.';
      return new Package.load(id.name, packageDir, systemCache.sources);
    });
  }

  /// Since pub generates symlinks that point into the system cache (in
  /// particular, targeting the "lib" directories of cached packages), it's
  /// possible to accidentally break cached packages if something traverses
  /// that symlink.
  ///
  /// This tries to determine if the cached package at [packageDir] has been
  /// corrupted. The heuristics are it is corrupted if any of the following are
  /// true:
  ///
  ///   * It has an empty "lib" directory.
  ///   * It has no pubspec.
  bool _isCachedPackageCorrupted(String packageDir) {
    if (!fileExists(path.join(packageDir, "pubspec.yaml"))) return true;

    var libDir = path.join(packageDir, "lib");
    if (dirExists(libDir)) return listDir(libDir).length == 0;

    // If we got here, it's OK.
    return false;
  }

  /// Returns the directory in the system cache that the package identified by
  /// [id] should be installed to. This should return a path to a subdirectory
  /// of [systemCacheRoot].
  ///
  /// This doesn't need to be implemented if [shouldCache] is false.
  Future<String> systemCacheDirectory(PackageId id) {
    return new Future.error(
        "systemCacheDirectory() must be implemented if shouldCache is true.");
  }

  /// When a [Pubspec] or [LockFile] is parsed, it reads in the description for
  /// each dependency. It is up to the dependency's [Source] to determine how
  /// that should be interpreted. This will be called during parsing to validate
  /// that the given [description] is well-formed according to this source, and
  /// to give the source a chance to canonicalize the description.
  ///
  /// [containingPath] is the path to the local file (pubspec or lockfile)
  /// where this description appears. It may be `null` if the description is
  /// coming from some in-memory source (such as pulling down a pubspec from
  /// pub.dartlang.org).
  ///
  /// It should return if a (possibly modified) valid description, or throw a
  /// [FormatException] if not valid.
  ///
  /// [fromLockFile] is true when the description comes from a [LockFile], to
  /// allow the source to use lockfile-specific descriptions via [resolveId].
  dynamic parseDescription(String containingPath, description,
                           {bool fromLockFile: false}) {
    return description;
  }

  /// Returns whether or not [description1] describes the same package as
  /// [description2] for this source. This method should be light-weight. It
  /// doesn't need to validate that either package exists.
  ///
  /// By default, just uses regular equality.
  bool descriptionsEqual(description1, description2) =>
    description1 == description2;

  /// For some sources, [PackageId]s can point to different chunks of code at
  /// different times. This takes such an [id] and returns a future that
  /// completes to a [PackageId] that will uniquely specify a single chunk of
  /// code forever.
  ///
  /// For example, [GitSource] might take an [id] with description
  /// `http://github.com/dart-lang/some-lib.git` and return an id with a
  /// description that includes the current commit of the Git repository.
  ///
  /// This will be called after the package identified by [id] is installed, so
  /// the source can use the installed package to determine information about
  /// the resolved id.
  ///
  /// The returned [PackageId] may have a description field that's invalid
  /// according to [parseDescription], although it must still be serializable
  /// to JSON and YAML. It must also be equal to [id] according to
  /// [descriptionsEqual].
  ///
  /// By default, this just returns [id].
  Future<PackageId> resolveId(PackageId id) => new Future.value(id);
  
  /// Returns the [Package]s that have been installed in the system cache.
  List<Package> getCachedPackages() {
    if (shouldCache) throw "Source $name must implement this.";
  }

  /// Returns the source's name.
  String toString() => name;
}
