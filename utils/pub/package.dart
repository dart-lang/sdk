// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A named, versioned, unit of code and resource reuse.
 */
class Package {
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
   * The cache where this package is contained.
   */
  final PackageCache _cache;

  /**
   * Constructs a package. This should not be called directly. Instead, acquire
   * packages from [PackageCache].
   */
  Package._(this._cache, this.name, this.dependencies);

  /**
   * Reads and returns all of the packages this package depends on.
   */
  Future<Collection<Package>> readDependencies() {
    return Futures.wait(dependencies.map((name) => _cache.find(name)));
  }
}
