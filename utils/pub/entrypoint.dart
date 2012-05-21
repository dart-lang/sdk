// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Pub operates over a directed graph of dependencies that starts at a root
 * "entrypoint" package. This is typically the package where the current
 * working directory is located. An entrypoint knows the [root] package it is
 * associated with and is responsible for managing the "packages" directory
 * for it.
 *
 * That directory contains symlinks to all packages used by an app. These links
 * point either to the [SystemCache] or to some other location on the local
 * filesystem.
 *
 * While entrypoints are typically applications, a pure library package may end
 * up being used as an entrypoint. Also, a single package may be used as an
 * entrypoint in one context but not in another. For example, a package that
 * contains a reusable library may not be the entrypoint when used by an app,
 * but may be the entrypoint when you're running its tests.
 */
class Entrypoint {
  /**
   * The root package this entrypoint is associated with.
   */
  final Package root;

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

  Entrypoint(this.root, this.cache)
  : _loadedPackages  = new Map<PackageId, Package>(),
    _pendingInstalls = new Map<PackageId, Future<Package>>();

  /**
   * The path to this "packages" directory.
   */
  // TODO(rnystrom): Make this path configurable.
  String get path() => join(root.dir, 'packages');

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
          throw 'Package ${id.name} not found in source "${id.source.name}".';
        });
      }
    }).chain((_) => Package.load(packageDir, cache.sources));

    future.then((pkg) => _loadedPackages[id] = pkg);
    always(future, () => _pendingInstalls.remove(id));
    _pendingInstalls[id] = future;

    return future;
  }

  /**
   * Installs all dependencies of the [root] package to its "packages"
   * directory. Returns a [Future] that completes when all dependencies are
   * installed.
   */
  Future installDependencies() {
    var seen = new Set<PackageId>();

    Future helper(List<PackageRef> packages) {
      return Futures.wait(packages.map((ref) {
        return resolve(ref).chain((id) {
          if (seen.contains(id)) return new Future.immediate(null);
          seen.add(id);

          return install(id).chain((package) {
            return helper(package.dependencies);
          });
        });
      }));
    }

    return helper(root.dependencies);
  }

  /**
   * Given [ref], which ambiguously identifies a dependent package, selects an
   * appropriate precise package to use when this is the entrypoint. In other
   * words, given a loose refence like "foo >= 2.0", figures out what concrete
   * package we should use starting from this entrypoint.
   */
  Future<PackageId> resolve(PackageRef ref) {
    // TODO(rnystrom): This should use the lockfile to select the right version
    // once that's implemented. If the lockfile doesn't exist, it should
    // generate it. In the meantime, here's a dumb implementation:
    return new Future.immediate(
        new PackageId(ref.source, Version.none, ref.description));
  }
}
