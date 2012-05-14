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
   * The ids of the packages that this package depends on. This is what is
   * specified in the pubspec when this package depends on another.
   */
  final Collection<PackageId> dependencies;

  /**
   * Constructs a package. This should not be called directly. Instead, acquire
   * packages from [load()].
   */
  Package._(String dir, this.dependencies)
  : dir = dir,
    name = basename(dir);

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
  static Future<List<PackageId>> _parsePubspec(String path) {
    final completer = new Completer<List<PackageId>>();

    // TODO(rnystrom): Handle the directory not existing.
    // TODO(rnystrom): Error-handling.
    final readFuture = readTextFile(path);
    readFuture.handleException((error) {
      // If there is no pubspec, we implicitly treat that as a package with no
      // dependencies.
      // TODO(rnystrom): Distinguish file not found from other real errors.
      completer.complete(<PackageId>[]);
      return true;
    });

    readFuture.then((pubspec) {
      if (pubspec.trim() == '') {
        completer.complete(<String>[]);
        return;
      }

      var parsedPubspec = loadYaml(pubspec);
      if (parsedPubspec is! Map) {
        completer.completeException('The pubspec must be a YAML mapping.');
      }

      if (!parsedPubspec.containsKey('dependencies')) {
        completer.complete(<String>[]);
        return;
      }

      var dependencies = parsedPubspec['dependencies'];
      if (dependencies.some((e) => e is! String)) {
        completer.completeException(
            'The pubspec dependencies must be a list of package names.');
      }

      var dependencyIds =
        dependencies.map((name) => new PackageId(name, Source.defaultSource));
      completer.complete(dependencyIds);
    });

    return completer.future;
  }
}

/**
 * A unique identifier for a package. A given package id specifies a single
 * chunk of code and resources.
 *
 * Note that it's possible for multiple package ids to point to identical
 * packages. For example, the same package may be available from multiple
 * sources. As far as Pub is concerned, those packages are different.
 */
// TODO(nweiz, rnystrom): this should include version eventually
class PackageId implements Hashable, Comparable {
  /**
   * The name used by the [source] to look up the package.
   *
   * Note that this may be distinct from [name], which is the name of the
   * package itself. The [source] uses this name to locate the package and
   * returns the true package name. For example, for a Git source [fullName]
   * might be the URL "git://github.com/dart/uilib.git", while [name] would just
   * be "uilib". It would be up to the source to take the URL and extract the
   * package name.
   */
  final String fullName;

  /**
   * The [Source] used to look up the package given the [fullName].
   */
  final Source source;

  PackageId(String this.fullName, Source this.source);

  /**
   * The name of the package being imported. Not necessarily the same as
   * [fullName].
   */
  String get name() => source.packageName(this);

  int hashCode() => fullName.hashCode() ^ source.name.hashCode();

  bool operator ==(other) {
    if (other is! PackageId) return false;
    return other.fullName == fullName && other.source.name == source.name;
  }

  String toString() => "$fullName from ${source.name}";

  int compareTo(Comparable other) {
    if (other is! PackageId) throw new IllegalArgumentException(other);
    var sourceComp = this.source.name.compareTo(other.source.name);
    if (sourceComp != 0) return sourceComp;
    return this.fullName.compareTo(other.fullName);
  }
}
