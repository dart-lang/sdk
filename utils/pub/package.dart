// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library package;

import 'dart:async';

import 'package:pathos/path.dart' as path;

import 'io.dart';
import 'pubspec.dart';
import 'source.dart';
import 'source_registry.dart';
import 'version.dart';

final _README_REGEXP = new RegExp(r"^README($|\.)", caseSensitive: false);

/// A named, versioned, unit of code and resource reuse.
class Package {
  /// The path to the directory containing the package.
  final String dir;

  /// The name of the package.
  String get name {
    if (pubspec.name != null) return pubspec.name;
    if (dir != null) return path.basename(dir);
    return null;
  }

  /// The package's version.
  Version get version => pubspec.version;

  /// The parsed pubspec associated with this package.
  final Pubspec pubspec;

  /// The ids of the packages that this package depends on. This is what is
  /// specified in the pubspec when this package depends on another.
  List<PackageRef> get dependencies => pubspec.dependencies;

  /// Returns the path to the README file at the root of the entrypoint, or null
  /// if no README file is found. If multiple READMEs are found, this uses the
  /// same conventions as pub.dartlang.org for choosing the primary one: the
  /// README with the fewest extensions that is lexically ordered first is
  /// chosen.
  String get readmePath {
    var readmes = listDir(dir).map(path.basename).
        where((entry) => entry.contains(_README_REGEXP));
    if (readmes.isEmpty) return;

    return path.join(dir, readmes.reduce((readme1, readme2) {
      var extensions1 = ".".allMatches(readme1).length;
      var extensions2 = ".".allMatches(readme2).length;
      var comparison = extensions1.compareTo(extensions2);
      if (comparison == 0) comparison = readme1.compareTo(readme2);
      return (comparison <= 0) ? readme1 : readme2;
    }));
  }

  /// Loads the package whose root directory is [packageDir]. [name] is the
  /// expected name of that package (e.g. the name given in the dependency), or
  /// `null` if the package being loaded is the entrypoint package.
  Package.load(String name, String packageDir, SourceRegistry sources)
      : dir = packageDir,
        pubspec = new Pubspec.load(name, packageDir, sources);

  /// Constructs a package with the given pubspec. The package will have no
  /// directory associated with it.
  Package.inMemory(this.pubspec)
    : dir = null;

  /// Constructs a package. This should not be called directly. Instead, acquire
  /// packages from [load()].
  Package._(this.dir, this.pubspec);

  /// Returns a debug string for the package.
  String toString() => '$name $version ($dir)';
}

/// An unambiguous resolved reference to a package. A package ID contains enough
/// information to correctly install the package.
///
/// Note that it's possible for multiple distinct package IDs to point to
/// different directories that happen to contain identical packages. For
/// example, the same package may be available from multiple sources. As far as
/// Pub is concerned, those packages are different.
class PackageId implements Comparable<PackageId> {
  /// The name of the package being identified.
  final String name;

  /// The [Source] used to look up this package given its [description]. If
  /// this is a root package ID, this will be `null`.
  final Source source;

  /// The package's version.
  final Version version;

  /// The metadata used by the package's [source] to identify and locate it. It
  /// contains whatever [Source]-specific data it needs to be able to install
  /// the package. For example, the description of a git sourced package might
  /// by the URL "git://github.com/dart/uilib.git".
  final description;

  PackageId(this.name, this.source, this.version, this.description);

  /// Creates an ID for the given root package.
  PackageId.root(Package package)
      : name = package.name,
        source = null,
        version = package.version,
        description = package.name;

  /// Whether this ID identifies the root package.
  bool get isRoot => source == null;

  int get hashCode => name.hashCode ^ source.hashCode ^ version.hashCode;

  /// Gets the directory where this package is or would be found in the
  /// [SystemCache].
  Future<String> get systemCacheDirectory => source.systemCacheDirectory(this);

  bool operator ==(other) {
    if (other is! PackageId) return false;
    // TODO(rnystrom): We're assuming here the name/version/source tuple is
    // enough to uniquely identify the package and that we don't need to delve
    // into the description.
    return other.name == name &&
           other.source == source &&
           other.version == version;
  }

  String toString() {
    if (isRoot) return "$name $version (root)";
    if (source.isDefault) return "$name $version";
    return "$name $version from $source";
  }

  int compareTo(PackageId other) {
    var sourceComp = source.name.compareTo(other.source.name);
    if (sourceComp != 0) return sourceComp;

    var nameComp = name.compareTo(other.name);
    if (nameComp != 0) return nameComp;

    return version.compareTo(other.version);
  }

  /// Returns the pubspec for this package.
  Future<Pubspec> describe() => source.describe(this);

  /// Returns a future that completes to the resovled [PackageId] for this id.
  Future<PackageId> get resolved => source.resolveId(this);

  /// Returns a [PackageRef] that references this package and constrains its
  /// version to exactly match [version].
  PackageRef toRef() {
    return new PackageRef(name, source, version, description);
  }

  /// Returns `true` if this id's description matches [other]'s.
  bool descriptionEquals(PackageRef other) {
    return source.descriptionsEqual(description, other.description);
  }
}

/// A reference to a package. Unlike a [PackageId], a PackageRef may not
/// unambiguously refer to a single package. It may describe a range of allowed
/// packages.
class PackageRef {
  /// The name of the package being identified.
  final String name;

  /// The [Source] used to look up the package. If this refers to a root
  /// package, this will be `null`.
  final Source source;

  /// The allowed package versions.
  final VersionConstraint constraint;

  /// The metadata used to identify the package being referenced. The
  /// interpretation of this will vary based on the [source].
  final description;

  PackageRef(this.name, this.source, this.constraint, this.description);

  // TODO(rnystrom): Remove this if the old version solver is removed.
  /// Creates a reference to the given root package.
  PackageRef.root(Package package)
      : name = package.name,
        source = null,
        constraint = package.version,
        description = package.name;

  /// Whether this refers to the root package.
  bool get isRoot => source == null;

  String toString() {
    if (isRoot) return "$name $constraint (root)";
    return "$name $constraint from $source ($description)";
  }

  /// Returns a [PackageId] generated from this [PackageRef] with the given
  /// concrete version.
  PackageId atVersion(Version version) =>
    new PackageId(name, source, version, description);

  /// Returns `true` if this reference's description matches [other]'s.
  bool descriptionEquals(PackageRef other) {
    return source.descriptionsEqual(description, other.description);
  }
}

class PubspecNotFoundException implements Exception {
  final String name;

  PubspecNotFoundException(this.name);

  String toString() => 'Package "$name" doesn\'t have a pubspec.yaml file.';
}

class PubspecHasNoNameException implements Exception {
  final String name;

  PubspecHasNoNameException(this.name);

  String toString() => 'Package "$name"\'s pubspec.yaml file is missing the '
    'required "name" field (e.g. "name: $name").';
}

class PubspecNameMismatchException implements Exception {
  final String expectedName;
  final String actualName;

  PubspecNameMismatchException(this.expectedName, this.actualName);

  String toString() => 'The name you specified for your dependency, '
    '"$expectedName", doesn\'t match the name "$actualName" in its pubspec.';
}
