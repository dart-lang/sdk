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
  List<PackageDep> get dependencies => pubspec.dependencies;

  /// Returns the path to the README file at the root of the entrypoint, or null
  /// if no README file is found. If multiple READMEs are found, this uses the
  /// same conventions as pub.dartlang.org for choosing the primary one: the
  /// README with the fewest extensions that is lexically ordered first is
  /// chosen.
  String get readmePath {
    var readmes = listDir(dir).map(path.basename).
        where((entry) => entry.contains(_README_REGEXP));
    if (readmes.isEmpty) return null;

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

/// This is the private base class of [PackageRef], [PackageID], and
/// [PackageDep]. It contains functionality and state that those classes share
/// but is private so that from outside of this library, there is no type
/// relationship between those three types.
class _PackageName {
  _PackageName(this.name, this.source, this.description);

  /// The name of the package being identified.
  final String name;

  /// The [Source] used to look up this package given its [description]. If
  /// this is a root package, this will be `null`.
  final Source source;

  /// The metadata used by the package's [source] to identify and locate it. It
  /// contains whatever [Source]-specific data it needs to be able to install
  /// the package. For example, the description of a git sourced package might
  /// by the URL "git://github.com/dart/uilib.git".
  final description;

  /// Whether this package is the root package.
  bool get isRoot => source == null;

  /// Gets the directory where this package is or would be found in the
  /// [SystemCache].
  Future<String> get systemCacheDirectory => source.systemCacheDirectory(this);

  String toString() {
    if (isRoot) return "$name (root)";
    if (source.isDefault) return name;
    return "$name from $source";
  }

  /// Returns a [PackageRef] with this one's [name], [source], and
  /// [description].
  PackageRef toRef() => new PackageRef(name, source, description);

  /// Returns a [PackageId] for this package with the given concrete version.
  PackageId atVersion(Version version) =>
    new PackageId(name, source, version, description);

  /// Returns `true` if this package's description matches [other]'s.
  bool descriptionEquals(PackageDep other) {
    return source.descriptionsEqual(description, other.description);
  }
}

/// A reference to a [Package], but not any particular version(s) of it.
class PackageRef extends _PackageName {
  PackageRef(String name, Source source, description)
      : super(name, source, description);

  int get hashCode => name.hashCode ^ source.hashCode;

  bool operator ==(other) {
    // TODO(rnystrom): We're assuming here that we don't need to delve into the
    // description.
    return other is PackageRef &&
           other.name == name &&
           other.source == source;
  }

  /// Gets the list of ids of all versions of the package that are described by
  /// this reference.
  Future<List<PackageId>> getVersions() {
    if (isRoot) {
      throw new StateError("Cannot get versions for the root package.");
    }

    return source.getVersions(name, description).then((versions) {
      return versions.map((version) => atVersion(version)).toList();
    });
  }
}

/// A reference to a specific version of a package. A package ID contains
/// enough information to correctly install the package.
///
/// Note that it's possible for multiple distinct package IDs to point to
/// different packages that have identical contents. For example, the same
/// package may be available from multiple sources. As far as Pub is concerned,
/// those packages are different.
class PackageId extends _PackageName {
  /// The package's version.
  final Version version;

  PackageId(String name, Source source, this.version, description)
      : super(name, source, description);

  /// Creates an ID for the given root package.
  PackageId.root(Package package)
      : version = package.version,
        super(package.name, null, package.name);

  int get hashCode => name.hashCode ^ source.hashCode ^ version.hashCode;

  bool operator ==(other) {
    // TODO(rnystrom): We're assuming here that we don't need to delve into the
    // description.
    return other is PackageId &&
           other.name == name &&
           other.source == source &&
           other.version == version;
  }

  String toString() {
    if (isRoot) return "$name $version (root)";
    if (source.isDefault) return "$name $version";
    return "$name $version from $source";
  }

  /// Returns the pubspec for this package.
  Future<Pubspec> describe() => source.systemCache.describe(this);

  /// Returns a future that completes to the resolved [PackageId] for this id.
  Future<PackageId> get resolved => source.resolveId(this);
}

/// A reference to a constrained range of versions of one package.
class PackageDep extends _PackageName {
  /// The allowed package versions.
  final VersionConstraint constraint;

  PackageDep(String name, Source source, this.constraint, description)
      : super(name, source, description);

  String toString() {
    if (isRoot) return "$name $constraint (root)";
    return "$name $constraint from $source ($description)";
  }

  int get hashCode => name.hashCode ^ source.hashCode;

  bool operator ==(other) {
    // TODO(rnystrom): We're assuming here that we don't need to delve into the
    // description.
    return other is PackageDep &&
           other.name == name &&
           other.source == source &&
           other.constraint == constraint;
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
