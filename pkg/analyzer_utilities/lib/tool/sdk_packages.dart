// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains logic for analyzing the subdirectories of the SDK's `pkg`
// directory, and producing metadata about those packages, such as:
// - Which team owns each package
// - Whether the package is published to pub.
//
// This information can be used for automated refactoring of large parts of the
// SDK codebase.

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer_testing/package_root.dart' as package_root;
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

final List<PackageInfo> packages = _computePackages();

/// The absolute path of the root of the SDK repository (the directory
/// containing `pkg`).
final String repoRoot = p.dirname(p.normalize(package_root.packageRoot));

List<PackageInfo> _computePackages() {
  var result = <PackageInfo>[];
  for (var entity in Directory(
    package_root.packageRoot,
  ).listSync().whereType<Directory>()) {
    var packageName = p.basename(entity.path);
    var pubspecPath = p.join(entity.path, 'pubspec.yaml');
    var pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) continue;
    var pubspec = loadYaml(
      pubspecFile.readAsStringSync(),
      sourceUrl: Uri.file(pubspecPath),
    );
    if (pubspec is! YamlMap) {
      throw StateError('Pubspec $pubspecPath is not a map');
    }
    if (pubspec['name'] case var pubspecName when pubspecName != packageName) {
      throw StateError(
        'Pubspec $pubspecPath says the package name is '
        '${json.encode(pubspecName)}; expected ${json.encode(packageName)}',
      );
    }
    var isPublished = pubspec['publish_to'] != 'none';
    var sdkConstraint =
        (pubspec['environment'] as YamlMap).nodes['sdk'] as YamlScalar;
    var ownerStrings = _resolveOwnerStrings(p.join(entity.path, 'OWNERS'));
    result.add(
      PackageInfo(
        path: entity.path,
        name: packageName,
        isPublished: isPublished,
        ownerSet: OwnerSet.fromStrings(ownerStrings),
        sdkConstraint: sdkConstraint.value as String,
        sdkConstraintNode: sdkConstraint,
      ),
    );
  }

  // `listSync` returns directories in whatever order the file system does, so
  // sort to keep everything derived from this list deterministic.
  return result..sortBy((package) => package.name);
}

/// Resolves the set of teams that own the package whose `OWNERS` file is
/// located at [ownersPath].
///
/// Team ownership is expressed by a `file:` directive referring to one of the
/// `/tools/OWNERS_*` files; the returned strings are the lowercased suffixes of
/// those file names (so `file:/tools/OWNERS_MODEL` yields `model`).
///
/// Two other forms of `file:` directive are recognized:
/// - A reference to the repository-global `/OWNERS` file is ignored, since it
///   applies to every package and therefore says nothing about which team owns
///   this particular one.
/// - A reference to another package's `OWNERS` file (for example,
///   `pkg/dart_runtime_service_dds` defers to `pkg/dds`) is resolved
///   recursively, so that the referring package inherits the referenced
///   package's owners.
///
/// `per-file` directives are deliberately not considered, because they describe
/// ownership of individual files rather than of the package as a whole.
///
/// [visited] guards against cycles among mutually-referential `OWNERS` files.
List<String> _resolveOwnerStrings(String ownersPath, {Set<String>? visited}) {
  visited ??= {};
  if (!visited.add(p.canonicalize(ownersPath))) {
    // Already resolved (or currently being resolved) via another path.
    return const [];
  }
  var ownersFile = File(ownersPath);
  if (!ownersFile.existsSync()) return const [];
  var ownerStrings = <String>[];
  for (var line in ownersFile.readAsStringSync().split('\n')) {
    line = line.trim();
    const filePrefix = 'file:';
    if (!line.startsWith(filePrefix)) continue;
    var referencedPath = line.substring(filePrefix.length);
    // Repository-root-relative references may be written with either one or
    // two leading slashes; normalize to one.
    if (referencedPath.startsWith('//')) {
      referencedPath = referencedPath.substring(1);
    }
    if (referencedPath == '/OWNERS') continue;
    const ownersFilePrefix = '/tools/OWNERS_';
    if (referencedPath.startsWith(ownersFilePrefix)) {
      ownerStrings.add(
        referencedPath.substring(ownersFilePrefix.length).toLowerCase(),
      );
    } else if (p.basename(referencedPath) == 'OWNERS') {
      ownerStrings.addAll(
        _resolveOwnerStrings(
          p.join(repoRoot, referencedPath.substring(1)),
          visited: visited,
        ),
      );
    } else {
      throw StateError(
        'OWNERS file $ownersPath refers to unexpected file $referencedPath',
      );
    }
  }
  return ownerStrings;
}

/// Wrapper around `Set<String>` that represents a set of OWNERS files.
///
/// This class provides an `==` operator and `hashCode` implementation, so that
/// packages can be easily categorized by their `OwnerSet`.
class OwnerSet with SetMixin<String> {
  final Set<String> _owners;

  new fromStrings(Iterable<String> strings) : _owners = strings.toSet();

  @override
  int get hashCode => const SetEquality<String>().hash(_owners);

  @override
  Iterator<String> get iterator => _owners.iterator;

  @override
  int get length => _owners.length;

  @override
  bool operator ==(Object other) =>
      other is OwnerSet &&
      const SetEquality<String>().equals(_owners, other._owners);

  @override
  bool add(value) {
    throw StateError('Do not modify OwnerSet');
  }

  @override
  bool contains(Object? element) => _owners.contains(element);

  @override
  lookup(Object? element) => _owners.lookup(element);

  @override
  bool remove(Object? value) {
    throw StateError('Do not modify OwnerSet');
  }

  @override
  Set<String> toSet() => _owners.toSet();

  @override
  String toString() => '{${join(', ')}}';
}

class PackageInfo {
  /// The absolute path of the package directory.
  final String path;

  /// The name of the package.
  final String name;

  /// Whether this package is published to `pub`.
  final bool isPublished;

  /// The set of OWNERS files referenced by `file:` directives in this package's
  /// `OWNERS` file.
  final OwnerSet ownerSet;

  /// The current setting of the package's SDK constraint.
  final String sdkConstraint;

  /// The YAML node for the SDK constraint.
  final YamlScalar sdkConstraintNode;

  new({
    required this.path,
    required this.name,
    required this.isPublished,
    required this.ownerSet,
    required this.sdkConstraint,
    required this.sdkConstraintNode,
  });

  @override
  String toString() =>
      'PackageInfo(name: $name, isPublished: $isPublished, ownerSet: '
      '$ownerSet)';
}
