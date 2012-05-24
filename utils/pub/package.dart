// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('package');

#import('io.dart');
#import('pubspec.dart');
#import('source.dart');
#import('source_registry.dart');
#import('version.dart');

/**
 * A named, versioned, unit of code and resource reuse.
 */
class Package {
  /**
   * Loads the package whose root directory is [packageDir].
   */
  static Future<Package> load(String packageDir, SourceRegistry sources) {
    var pubspecPath = join(packageDir, 'pubspec');

    return fileExists(pubspecPath).chain((exists) {
      if (exists) {
        return readTextFile(pubspecPath).transform((contents) {
          return new Pubspec.parse(contents, sources);
        });
      } else {
        // If there is no pubspec, we implicitly treat that as a package with
        // no dependencies.
        return new Future.immediate(new Pubspec.empty());
      }
    }).transform((pubspec) {
      return new Package._(packageDir, pubspec);
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
   * The package's version.
   */
  Version get version() => pubspec.version;

  /**
   * The parsed pubspec associated with this package.
   */
  final Pubspec pubspec;

  /**
   * The ids of the packages that this package depends on. This is what is
   * specified in the pubspec when this package depends on another.
   */
  Collection<PackageRef> get dependencies() => pubspec.dependencies;

  /**
   * Constructs a package. This should not be called directly. Instead, acquire
   * packages from [load()].
   */
  Package._(String dir, this.pubspec)
    : dir = dir,
      name = basename(dir);

  /**
   * Returns a debug string for the package.
   */
  String toString() => '$name ($dir)';
}

/**
 * An unambiguous resolved reference to a package. A package ID contains enough
 * information to correctly install the package.
 *
 * Note that it's possible for multiple distinct package IDs to point to
 * different directories that happen to contain identical packages. For example,
 * the same package may be available from multiple sources. As far as Pub is
 * concerned, those packages are different.
 */
class PackageId implements Comparable, Hashable {
  /**
   * The [Source] used to look up this package given its [description].
   */
  final Source source;

  /**
   * The package's version.
   */
  final Version version;

  /**
   * The metadata used by the package's [source] to identify and locate it. It
   * contains whatever [Source]-specific data it needs to be able to install
   * the package. For example, the description of a git sourced package might
   * by the URL "git://github.com/dart/uilib.git".
   */
  final description;

  PackageId(this.source, this.version, this.description);

  /**
   * The name of the package being identified. This will be the human-friendly
   * name like "uilib".
   */
  String get name() => source.packageName(this);

  int hashCode() => name.hashCode() ^
                    source.name.hashCode() ^
                    version.hashCode();

  bool operator ==(other) {
    if (other is! PackageId) return false;
    // TODO(rnystrom): We're assuming here the name/version/source tuple is
    // enough to uniquely identify the package and that we don't need to delve
    // into the description.
    return other.name == name &&
           other.source.name == source.name &&
           other.version == version;
  }

  String toString() => "$name $version from ${source.name}";

  int compareTo(Comparable other) {
    if (other is! PackageId) throw new IllegalArgumentException(other);

    var sourceComp = source.name.compareTo(other.source.name);
    if (sourceComp != 0) return sourceComp;

    var nameComp = name.compareTo(other.name);
    if (nameComp != 0) return nameComp;

    return version.compareTo(other.version);
  }
}

/**
 * A reference to a package. Unlike a [PackageId], a PackageRef may not
 * unambiguously refer to a single package. It may describe a range of allowed
 * packages.
 */
class PackageRef {
  /**
   * The name of the package being referenced.
   */
  final String name;

  /**
   * The [Source] used to look up the package.
   */
  final Source source;

  /**
   * The allowed package versions.
   */
  final VersionConstraint version;

  /**
   * The metadata used to identify the package being referenced. The
   * interpretation of this will vary based on the [source].
   */
  final description;

  PackageRef(this.name, this.source, this.version, this.description);

  String toString() => "$name $version from $source ($description)";
}
