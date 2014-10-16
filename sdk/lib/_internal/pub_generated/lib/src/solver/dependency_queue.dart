// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.solver.dependency_queue;

import 'dart:async';
import 'dart:collection' show Queue;

import '../log.dart' as log;
import '../package.dart';
import 'backtracking_solver.dart';

/// A queue of one package's dependencies, ordered by how the solver should
/// traverse them.
///
/// It prefers locked versions so that they stay locked if possible. Then it
/// prefers a currently selected package so that it only has to consider a
/// single version.
///
/// After that, it orders the remaining packages by the number of versions they
/// have so that packages with fewer versions are solved first. (If two
/// packages have the same number of versions, they are sorted alphabetically
/// just to be deterministic.)
///
/// Critically, this queue will *not* sort the dependencies by number of
/// versions until actually needed. This ensures we don't do any network
/// requests until we actually need to. In particular, it means that solving
/// a package graph with an already up-to-date lockfile will do no network
/// requests.
class DependencyQueue {
  final BacktrackingSolver _solver;

  /// The dependencies for packages that have already been selected.
  final Queue<PackageDep> _presorted;

  /// The dependencies on the remaining packages.
  ///
  /// This is lazily sorted right before the first item is requested.
  final List<PackageDep> _remaining;

  bool _isSorted = false;

  /// Gets whether there are any dependencies left to iterate over.
  bool get isEmpty => _presorted.isEmpty && _remaining.isEmpty;

  /// The pending [Future] while the remaining dependencies are being sorted.
  ///
  /// This will only be non-null while a sort is in progress.
  Future _sortFuture;

  factory DependencyQueue(BacktrackingSolver solver, Iterable<PackageDep> deps)
      {
    // Separate out the presorted ones.
    var presorted = <PackageDep>[];
    var remaining = <PackageDep>[];

    for (var dep in deps) {
      // Selected or locked packages come first.
      if (solver.getSelected(dep.name) != null ||
          solver.getLocked(dep.name) != null) {
        presorted.add(dep);
      } else {
        remaining.add(dep);
      }
    }

    // Sort the selected/locked packages by name just to ensure the solver is
    // deterministic.
    presorted.sort((a, b) => a.name.compareTo(b.name));

    return new DependencyQueue._(
        solver,
        new Queue<PackageDep>.from(presorted),
        remaining);
  }

  DependencyQueue._(this._solver, this._presorted, this._remaining);

  /// Emits the next dependency in priority order.
  ///
  /// It is an error to call this if [isEmpty] returns `true`. Note that this
  /// function is *not* re-entrant. You should only advance after the previous
  /// advance has completed.
  Future<PackageDep> advance() {
    // Emit the sorted ones first.
    if (_presorted.isNotEmpty) {
      return new Future.value(_presorted.removeFirst());
    }

    // Sort the remaining packages when we need the first one.
    if (!_isSorted) return _sort().then((_) => _remaining.removeAt(0));

    return new Future.value(_remaining.removeAt(0));
  }

  /// Sorts the unselected packages by number of versions and name.
  Future _sort() {
    // Sorting is not re-entrant.
    assert(_sortFuture == null);

    _sortFuture = Future.wait(_remaining.map(_getNumVersions)).then((versions) {
      _sortFuture = null;

      // Map deps to the number of versions they have.
      var versionMap = new Map.fromIterables(_remaining, versions);

      // Sort in best-first order to minimize backtracking.
      _remaining.sort((a, b) {
        // Traverse into packages with fewer versions since they will lead to
        // less backtracking.
        if (versionMap[a] != versionMap[b]) {
          return versionMap[a].compareTo(versionMap[b]);
        }

        // Otherwise, just sort by name so that it's deterministic.
        return a.name.compareTo(b.name);
      });

      _isSorted = true;
    });

    return _sortFuture;
  }

  /// Given a dependency, returns a future that completes to the number of
  /// versions available for it.
  Future<int> _getNumVersions(PackageDep dep) {
    // There is only ever one version of the root package.
    if (dep.isRoot) {
      return new Future.value(1);
    }

    return _solver.cache.getVersions(dep.toRef()).then((versions) {
      // If the root package depends on this one, ignore versions that don't
      // match that constraint. Since the root package's dependency constraints
      // won't change during solving, we can safely filter out packages that
      // don't meet it.
      for (var rootDep in _solver.root.immediateDependencies) {
        if (rootDep.name == dep.name) {
          versions =
              versions.where((id) => rootDep.constraint.allows(id.version));
          break;
        }
      }

      return versions.length;
    }).catchError((error, trace) {
      // If it fails for any reason, just treat that as no versions. This
      // will sort this reference higher so that we can traverse into it
      // and report the error more properly.
      log.solver("Could not get versions for $dep:\n$error\n\n$trace");
      return 0;
    });
  }
}
