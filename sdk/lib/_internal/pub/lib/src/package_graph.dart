// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.package_graph;

import 'entrypoint.dart';
import 'lock_file.dart';
import 'package.dart';

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

  PackageGraph(this.entrypoint, this.lockFile, this.packages);
}
