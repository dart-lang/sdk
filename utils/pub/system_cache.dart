// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('system_cache');

#import('package.dart');
#import('source_registry.dart');

/**
 * The system-wide cache of installed packages.
 *
 * This cache contains all packages that are downloaded from the internet.
 * Packages that are available locally (e.g. from the SDK) don't use this cache.
 */
class SystemCache {
  /**
   * The root directory where this package cache is located.
   */
  final String rootDir;

  /**
   * Packages which are currently being asynchronously installed to the cache.
   */
  final Map<PackageId, Future<Package>> _pendingInstalls;

  /**
   * The sources from which to install packages.
   */
  final SourceRegistry sources;

  /**
   * Creates a new package cache which is backed by the given directory on the
   * user's file system.
   */
  SystemCache(this.rootDir)
  : _pendingInstalls = new Map<PackageId, Future<Package>>(),
    sources = new SourceRegistry();

  /**
   * Loads all of the package ids in the cache and returns them.
   */
  Future<List<PackageId>> listAll() {
    return listDir(rootDir).chain((paths) {
      final sources = paths.map((path) {
        final source = sources[basename(path)];
        return listDir(path).transform((subpaths) {
          // TODO(rnystrom): Once there are cached packages and this path is
          // being used, figure out how version numbers should be acquired.
          return subpaths.map((subpath) =>
            new PackageId(basename(subpath), source, Version.none));
        });
      });
      return Futures.wait(sources).transform(flatten);
    });
  }

  /**
   * Ensures that the package identified by [id] is installed to the cache,
   * loads it, and returns it.
   *
   * It is an error to try installing a package from a source with `shouldCache
   * == false` to the system cache.
   */
  Future<Package> install(PackageId id) {
    if (!id.source.shouldCache) {
      throw new IllegalArgumentException("Package $id is not cacheable.");
    }

    var pending = _pendingInstalls[id];
    if (pending != null) return pending;

    var path = join(rootDir, id.source.name, id.source.packageName(id));
    var future = exists(path).chain((exists) {
      // TODO(nweiz): better error handling
      if (exists) throw 'Package $id is already installed.';
      return ensureDir(dirname(path));
    }).chain((_) {
      return id.source.install(id, path);
    }).chain((found) {
      if (!found) {
        throw 'Package ${id.fullName} not found in source "${id.source.name}".';
      }
      return Package.load(path, sources);
    });

    always(future, () => _pendingInstalls.remove(id));
    _pendingInstalls[id] = future;
    return future;
  }
}
