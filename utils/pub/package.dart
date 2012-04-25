// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A named, versioned, unit of code and resource reuse.
 */
class Package implements Hashable {
  /**
   * Loads the package whose root directory is [packageDir].
   */
  static Future<Package> load(String packageDir) {
    final pubspecPath = join(packageDir, 'pubspec');

    return _parsePubspec(pubspecPath).transform((dependencies) {
      return new Package._(packageDir, dependencies);
    });
  }

  /**
   * The path to the directory containing the package.
   */
  final String dir;

  /**
   * The name of the package.
   */
  final String name;

  /**
   * The names of the packages that this package depends on. This is what is
   * specified in the pubspec when this package depends on another.
   */
  // TODO(rnystrom): When packages are versioned and sourced, this will likely
  // be something more than just a string.
  final Collection<String> dependencies;

  /**
   * Constructs a package. This should not be called directly. Instead, acquire
   * packages from [load()].
   */
  Package._(String dir, this.dependencies)
  : dir = dir,
    name = basename(dir);

  /**
   * Reads and returns all of the packages this package immediately depends on.
   */
  Future<Collection<Package>> loadDependencies() {
    return Futures.wait(dependencies.map((name) => cache.find(name)));
  }

  /**
   * Walks the entire dependency graph starting at this package and returns a
   * [Set] of all of the packages dependend on by this one, directly or
   * indirectly. This package is included in the result set.
   */
  Future<Set<Package>> traverseDependencies() {
    final completer = new Completer<Set<Package>>();
    final packages = new Set<Package>();

    var pendingAsyncCalls = 0;

    walkPackage(Package package) {
      // Skip packages we've already traversed.
      if (packages.contains(package)) return;

      // Add the package.
      packages.add(package);

      // Recurse into its dependencies.
      pendingAsyncCalls++;
      package.loadDependencies().then((dependencies) {
        dependencies.forEach(walkPackage);
        pendingAsyncCalls--;
        if (pendingAsyncCalls == 0) completer.complete(packages);
      });
    }

    walkPackage(this);

    return completer.future;
  }

  /**
   * Generates a hashcode for the package.
   */
  // TODO(rnystrom): Do something more sophisticated here once we care about
  // versioning and different package sources.
  int hashCode() => name.hashCode();

  /**
   * Returns a debug string for the package.
   */
  String toString() => '$name ($dir)';

  /**
   * Parses the pubspec at the given path and returns the list of package
   * dependencies it exposes.
   */
  static Future<List<String>> _parsePubspec(String path) {
    final completer = new Completer<List<String>>();

    // TODO(rnystrom): Handle the directory not existing.
    // TODO(rnystrom): Error-handling.
    final readFuture = readTextFile(path);
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
