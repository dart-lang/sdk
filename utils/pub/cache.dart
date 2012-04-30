// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The local cache of previously installed packages.
 */
class PackageCache {
  /**
   * The root directory where this package cache is located.
   */
  final String rootDir;

  // TODO(rnystrom): When packages are versioned, String here and elsewhere will
  // become a name/version/(source?) tuple.
  final Map<String, Package> _loadedPackages;

  /**
   * Packages which are currently being asynchronously loaded.
   */
  final Map<String, Future<Package>> _pendingPackages;

  /**
   * Creates a new package cache which is backed by the given directory on the
   * user's file system.
   */
  PackageCache(this.rootDir)
  : _loadedPackages = <Package>{},
    _pendingPackages = <Future<Package>>{};

  /**
   * Loads all of the packages in the cache and returns them.
   */
  Future<List<Package>> listAll() {
    return listDir(rootDir).chain((paths) {
      final packages = paths.map((path) => find(basename(path)));
      return Futures.wait(packages);
    });
  }

  /**
   * Loads the package named [name] from this cache, if present.
   */
  // TODO(rnystrom): What happens if the package isn't cached?
  Future<Package> find(String name) {
    // Use the previously loaded one.
    final package = _loadedPackages[name];
    if (package != null) return new Future.immediate(package);

    // If we are already in-progress loading it, re-use that one.
    final pending = _pendingPackages[name];
    if (pending != null) return pending;

    // Actually load it from the cache.
    final future = Package.load(join(rootDir, name)).transform((package) {
      _pendingPackages.remove(name);
      _loadedPackages[name] = package;
      return package;
    });

    _pendingPackages[name] = future;
    return future;
  }
}
