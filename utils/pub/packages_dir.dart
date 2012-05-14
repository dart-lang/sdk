// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The "packages" directory for an application or library.
 *
 * This directory contains symlinks to all packages used by an app. These links
 * point either to the [SystemCache] or to some other location on the local
 * filesystem.
 */
class PackagesDir {
  /**
   * The package containing this directory.
   */
  final Package owner;

  /**
   * The system-wide cache which caches packages that need to be fetched over
   * the network.
   */
  final SystemCache cache;

  /**
   * Packages which have already been loaded into memory.
   */
  final Map<PackageId, Package> _loadedPackages;

  /**
   * Packages which are currently being asynchronously installed to the
   * directory.
   */
  final Map<PackageId, Future<Package>> _pendingInstalls;

  PackagesDir(this.owner, this.cache)
  : _loadedPackages  = new Map<PackageId, Package>(),
    _pendingInstalls = new Map<PackageId, Future<Package>>();

  /**
   * Returns the path to the "packages" directory.
   */
  // TODO(rnystrom): Make this path configurable.
  String get path() => join(owner.dir, 'packages');

  /**
   * Ensures that the package identified by [id] is installed to the directory,
   * loads it, and returns it.
   *
   * If this completes successfully, the package is guaranteed to be importable
   * using the `package:` scheme.
   *
   * This will automatically install the package to the system-wide cache as
   * well if it requires network access to retrieve (specifically, if
   * `id.source.shouldCache` is true).
   *
   * See also [installTransitively].
   */
  Future<Package> install(PackageId id) {
    var package = _loadedPackages[id];
    if (package != null) return new Future<Package>.immediate(package);

    var pending = _pendingInstalls[id];
    if (pending != null) return new Future<Package>.immediate(package);

    var packageDir = join(path, id.name);
    var future = ensureDir(dirname(packageDir)).chain((_) {
      return exists(packageDir);
    }).chain((exists) {
      // If the package already exists in the directory, no need to re-install.
      if (exists) return new Future.immediate(null);

      if (id.source.shouldCache) {
        return cache.install(id).chain(
            (pkg) => createSymlink(pkg.dir, packageDir));
      } else {
        return id.source.install(id, packageDir).transform((found) {
          if (found) return null;
          // TODO(nweiz): More robust error-handling.
          throw 'Package ${id.fullName} not found in source '
            '"${id.source.name}".';
        });
      }
    }).chain((_) => Package.load(packageDir));

    future.then((pkg) => _loadedPackages[id] = pkg);
    always(future, () => _pendingInstalls.remove(id));
    _pendingInstalls[id] = future;

    return future;
  }

  /**
   * Installs the package identified by [id] and all its transitive
   * dependencies.
   */
  Future<Package> installTransitively(PackageId id) {
    var seen = new Set<PackageId>();
    Future<Package> helper(id) {
      if (seen.contains(id)) return new Future.immediate(null);
      seen.add(id);

      return install(id).chain((package) {
        return Futures.wait(package.dependencies.map(helper)).
          transform((_) => package);
      });
    }

    return helper(id);
  }

  /**
   * Installs all dependencies of [owner] to the "packages" directory. Returns a
   * [Future] that completes when all dependencies are installed.
   */
  Future installDependencies() {
    return Futures.wait(owner.dependencies.map(installTransitively)).
      transform((_) => null);
  }
}
