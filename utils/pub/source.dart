// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('source');

#import('package.dart');

/**
 * A source from which to install packages.
 *
 * Each source has many packages that it looks up using [PackageId]s. The source
 * is responsible for installing these packages to the package cache.
 */
class Source {
  /**
   * The name of the source. Should be lower-case, suitable for use in a
   * filename, and unique accross all sources.
   */
  abstract String get name();

  /**
   * Whether this source's packages should be cached in Pub's global cache
   * directory.
   *
   * A source should be cached if it requires network access to retrieve
   * packages. It doesn't need to be cached if all packages are available
   * locally.
   */
  abstract bool get shouldCache();

  /**
   * Installs the package identified by [id] to [path]. Returns a [Future] that
   * completes when the installation was finished. The [Future] should resolve
   * to true if the package was found in the source and false if it wasn't. For
   * all other error conditions, it should complete with an exception.
   *
   * If [shouldCache] is true, [path] will be a path to this source's
   * subdirectory of the [PackageCache]'s cache directory. If [shouldCache] is
   * false, [path] will be a path to the application's "packages" directory.
   *
   * [path] is guaranteed not to exist, and its parent directory is guaranteed
   * to exist.
   */
  abstract Future<bool> install(PackageId id, String path);

  /**
   * When a [Pubspec] is parsed, it reads in the description for each
   * dependency. It is up to the dependency's [Source] to determine how that
   * should be interpreted. This will be called during parsing to validate that
   * the given [description] is well-formed according to this source. It should
   * return if the description is valid, or throw a [FormatException] if not.
   */
  void validateDescription(description) {}

  /**
   * Returns a human-friendly name for the package identified by [id]. This
   * method should be light-weight. It doesn't need to validate that the given
   * package exists.
   *
   * The package name should be lower-case and suitable for use in a filename.
   * It may contain forward slashes.
   */
  String packageName(PackageId id) => id.description;
}
