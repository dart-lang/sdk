// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.package_graph;

import 'entrypoint.dart';
import 'lock_file.dart';
import 'package.dart';
import 'utils.dart';

/// A holistic view of the entire transitive dependency graph for an entrypoint.
///
/// A package graph can be loaded using [Entrypoint.loadPackageGraph].
class PackageGraph {
  /// The entrypoint.
  final Entrypoint entrypoint;

  /// The entrypoint's lockfile.
  ///
  /// This describes the sources and resolved descriptions of everything in
  /// [packages].
  final LockFile lockFile;

  /// All transitive dependencies of the entrypoint (including itself).
  final Map<String, Package> packages;

  /// A map of transitive dependencies for each package.
  Map<String, Set<Package>> _transitiveDependencies;

  PackageGraph(this.entrypoint, this.lockFile, this.packages);

  /// Returns all transitive dependencies of [package].
  ///
  /// For the entrypoint this returns all packages in [packages], which includes
  /// dev and override. For any other package, it ignores dev and override
  /// dependencies.
  Set<Package> transitiveDependencies(String package) {
    if (package == entrypoint.root.name) return packages.values.toSet();

    if (_transitiveDependencies == null) {
      var closure = transitiveClosure(mapMap(packages,
          value: (_, package) => package.dependencies.map((dep) => dep.name)));
      _transitiveDependencies = mapMap(closure,
          value: (_, names) => names.map((name) => packages[name]).toSet());
    }

    return _transitiveDependencies[package];
  }
}
