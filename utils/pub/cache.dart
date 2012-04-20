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
    if (package != null) {
      return new Future.immediate(package);
    }

    // If we are already in-progress loading it, re-use that one.
    final pending = _pendingPackages[name];
    if (pending != null) {
      return pending;
    }

    return _loadPackage(name);
  }

  /**
   * Start loading the package.
   */
  Future<Package> _loadPackage(String name) {
    final future = _parsePubspec(name).transform((dependencies) {
      final package = new Package._(this, name, dependencies);

      _pendingPackages.remove(name);
      _loadedPackages[name] = package;
      return package;
    });

    _pendingPackages[name] = future;
    return future;
  }

  Future<List<String>> _parsePubspec(String name) {
    final completer = new Completer<List<String>>();
    final pubspecPath = join(rootDir, name, 'pubspec');

    // TODO(rnystrom): Handle the directory not existing.
    // TODO(rnystrom): Error-handling.
    final readFuture = readTextFile(pubspecPath);
    readFuture.handleException((error) {
      // If there is no pubspec, we implicitly treat that as a package with no
      // dependencies.
      // TODO(rnystrom): Distinguish file not found from other real errors.
      completer.complete(<String>[]);
      return true;
    });

    readFuture.then((pubspec) {
      // TODO(rnystrom): Use YAML parser when ready. For now, it's just a flat
      // list of newline-separated strings.
      final dependencyNames = pubspec.split('\n').
          map((name) => name.trim()).
          filter((name) => (name != null) && (name != ''));

      completer.complete(dependencyNames);
    });

    return completer.future;
  }
}
