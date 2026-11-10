// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/hint/sdk_constraint_extractor.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Checks if [targetVersion] is compatible with the SDK constraints of all
/// resolved [packages].
///
/// Returns a list of package names that are incompatible.
List<String> checkDependencyCompatibility({
  required Iterable<Package> packages,
  required Version targetVersion,
}) {
  var incompatible = <String>[];
  for (var package in packages) {
    var constraint = packageSdkConstraint(package.rootFolder);
    if (constraint == null) continue;

    // A dependency is incompatible only if its upper bound forbids all versions
    // at or above [targetVersion]. Dependencies that require an even higher
    // minimum SDK version remain compatible with this bump.
    if (!constraint.allowsAny(VersionRange(min: targetVersion))) {
      incompatible.add(package.name);
    }
  }
  return incompatible;
}

/// Calculates the edit to update the SDK constraint in [pubspecFile] to the
/// given [minimumVersion].
///
/// Returns `null` if the constraint cannot be found or is not in a supported
/// format.
PubspecEdit? computeEdit(File pubspecFile, Version minimumVersion) {
  var extractor = SdkConstraintExtractor(pubspecFile);
  var text = extractor.constraintText();
  var offset = extractor.constraintOffset();
  if (text == null || offset < 0) {
    return null;
  }

  String newConstraint;
  if (text == 'any' || text.startsWith('^')) {
    newConstraint = '^$minimumVersion';
  } else if (text.startsWith('>')) {
    var constraint = extractor.constraint();
    if (constraint is! VersionRange) return null;

    /// If the [constraint] allows no version at or above [minimumVersion],
    /// replace the whole constraint. e.g., `>=3.12.0 <3.13.0` allows nothing from
    /// 3.13.0 up, so raising its lower bound to 3.13.0 would make it
    /// unsatisfiable.
    if (!constraint.allowsAny(
      VersionRange(min: minimumVersion, includeMin: true),
    )) {
      newConstraint = '^$minimumVersion';
    } else {
      // Raise the lower bound and keep the upper bound, whatever whitespace
      // the original constraint was written with.
      newConstraint = VersionRange(
        min: minimumVersion,
        includeMin: true,
        max: constraint.max,
        includeMax: constraint.includeMax,
      ).toString();
    }
  } else {
    return null;
  }

  return PubspecEdit(
    offset: offset,
    originalConstraint: text,
    newConstraint: newConstraint,
    targetVersion: minimumVersion,
  );
}

/// Returns the minimum SDK version constraint defined in [pubspecFile], or
/// `null` if the constraint cannot be found or parsed.
Version? minimumSdkConstraint(File pubspecFile) {
  var extractor = SdkConstraintExtractor(pubspecFile);
  var constraint = extractor.constraint();
  if (constraint is VersionRange) {
    return constraint.min;
  } else if (constraint is Version) {
    return constraint;
  }
  return null;
}

/// Returns the SDK constraint declared by the package rooted at [packageRoot],
/// or `null` if it doesn't declare one that can be checked against.
///
/// The constraint of a null-safe package whose upper bound is `<3.0.0` is
/// re-interpreted as `<4.0.0`, matching how such a package is resolved by pub.
/// See
/// https://dart.dev/resources/dart-3-migration#dart-3-backwards-compatibility.
VersionConstraint? packageSdkConstraint(Folder packageRoot) {
  var pubspecFile = packageRoot.getFile(file_paths.pubspecYaml);
  if (!pubspecFile.exists) return null;

  var constraint = SdkConstraintExtractor(pubspecFile).constraint();
  if (constraint is! VersionRange) return constraint;

  var min = constraint.min;
  var nullSafetyVersion = Version(2, 12, 0).firstPreRelease;
  var dart3Version = Version(3, 0, 0).firstPreRelease;
  if (min != null &&
      min >= nullSafetyVersion &&
      constraint.max == dart3Version &&
      !constraint.includeMax) {
    return VersionRange(
      min: min,
      includeMin: constraint.includeMin,
      max: Version(4, 0, 0),
    );
  }
  return constraint;
}

/// The result of computing an edit to a pubspec file's SDK constraint.
///
/// The edit replaces the whole of [originalConstraint] with [newConstraint].
class PubspecEdit({
  /// The character offset in the document where the edit should be applied.
  required final int offset,

  /// The full original SDK constraint text before the edit is applied.
  required final String originalConstraint,

  /// The full new SDK constraint text after the edit is applied.
  required final String newConstraint,

  /// The target version to migrate to.
  required final Version targetVersion,
}) {
  /// The length of the text to be replaced.
  final int length = originalConstraint.length;
}

/// A target package's `pubspec.yaml` file and the parts of it a migration
/// needs.
///
/// Used to avoid reading and parsing the `pubspec.yaml` file multiple times.
class PubspecTarget {
  /// The `pubspec.yaml` file for the package.
  final File file;

  /// The name the package declares, or `null` if it doesn't declare one.
  ///
  /// This is the name a dependent writes in [dependencyNames] to refer to this
  /// package, so it is what identifies the package to anything reasoning about
  /// dependencies. Use [displayName] to name the package in output instead: a
  /// package without a declared name still has to be reported somehow.
  final String? name;

  /// The names of the packages this one depends on, directly or transitively.
  ///
  /// Dev dependencies are included: they take part in the version solve for
  /// the package that declares them, so they're subject to the same SDK
  /// constraint ordering as regular dependencies.
  ///
  /// Transitive dependencies are only known when the package has been
  /// resolved. They include `dependency_overrides`.
  final Set<String> dependencyNames;

  /// Creates a target from the parsed [pubspec] in [file].
  ///
  /// The [resolvedPackages] are the packages in the package config the package
  /// is analyzed with. That config can belong to a parent directory and list
  /// packages this one doesn't depend on, which only holds back more than
  /// needed.
  new({
    required this.file,
    required YamlMap pubspec,
    required Packages resolvedPackages,
  }) : name = switch (pubspec['name']) {
         String name => name,
         _ => null,
       },
       dependencyNames = _dependencyNamesIn(pubspec, resolvedPackages);

  /// The name to show for the package, falling back to the directory it sits
  /// in when it doesn't declare one.
  String get displayName => name ?? file.parent.shortName;

  static Set<String> _dependencyNamesIn(
    YamlMap pubspec,
    Packages resolvedPackages,
  ) => {
    for (var section in const ['dependencies', 'dev_dependencies'])
      if (pubspec[section] case YamlMap dependencies)
        ...dependencies.keys.whereType<String>(),
    for (var package in resolvedPackages.packages) package.name,
  };
}
