// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.solver.unselected_package_queue;

import 'dart:async';
import 'dart:collection';

import 'package:stack_trace/stack_trace.dart';

import '../log.dart' as log;
import '../package.dart';
import 'backtracking_solver.dart';

/// A priority queue of package references.
///
/// This is used to determine which packages should be selected by the solver,
/// and when. It's ordered such that the earliest packages should be selected
/// first.
class UnselectedPackageQueue {
  /// The underlying priority set.
  SplayTreeSet<PackageRef> _set;

  /// The version solver.
  final BacktrackingSolver _solver;

  /// A cache of the number of versions for each package ref.
  ///
  /// This is cached because sorting is synchronous and retrieving this
  /// information is asynchronous.
  final _numVersions = new Map<PackageRef, int>();

  /// The first package in the queue (that is, the package that should be
  /// selected soonest).
  PackageRef get first => _set.first;

  /// Whether there are no more packages in the queue.
  bool get isEmpty => _set.isEmpty;

  UnselectedPackageQueue(this._solver) {
    _set = new SplayTreeSet(_comparePackages);
  }

  /// Adds [ref] to the queue, if it's not there already.
  Future add(PackageRef ref) async {
    if (_solver.getLocked(ref.name) == null && !_numVersions.containsKey(ref)) {
      // Only get the number of versions for unlocked packages. We do this for
      // two reasons: first, locked packages are always sorted first anyway;
      // second, if every package is locked, we want to do version resolution
      // without any HTTP requests if possible.
      _numVersions[ref] = await _getNumVersions(ref);
    }

    _set.add(ref);
  }

  /// Removes [ref] from the queue.
  void remove(PackageRef ref) {
    _set.remove(ref);
  }

  /// The [Comparator] used to sort the queue.
  int _comparePackages(PackageRef ref1, PackageRef ref2) {
    var name1 = ref1.name;
    var name2 = ref2.name;

    if (name1 == name2) {
      assert(ref1 == ref2);
      return 0;
    }

    // Select the root package before anything else.
    if (ref1.isRoot) return -1;
    if (ref2.isRoot) return 1;

    // Sort magic refs before anything other than the root. The only magic
    // dependency that makes sense as a ref is "pub itself", and it only has a
    // single version.
    if (ref1.isMagic && ref2.isMagic) return name1.compareTo(name2);
    if (ref1.isMagic) return -1;
    if (ref2.isMagic) return 1;

    var locked1 = _solver.getLocked(name1) != null;
    var locked2 = _solver.getLocked(name2) != null;

    // Select locked packages before unlocked packages to ensure that they
    // remain locked as long as possible.
    if (locked1 && !locked2) return -1;
    if (!locked1 && locked2) return 1;

    // TODO(nweiz): Should we sort packages by something like number of
    // dependencies? We should be able to get that quickly for locked packages
    // if we have their pubspecs locally.

    // Sort locked packages by name among themselves to ensure that solving is
    // deterministic.
    if (locked1 && locked2) return name1.compareTo(name2);

    // Sort unlocked packages by the number of versions that might be selected
    // for them. In general, packages with fewer versions are less likely to
    // benefit from changing versions, so they should be selected earlier.
    var versions1 = _numVersions[ref1];
    var versions2 = _numVersions[ref2];
    if (versions1 == null && versions2 != null) return -1;
    if (versions1 != null && versions2 == null) return 1;
    if (versions1 != versions2) return versions1.compareTo(versions2);

    // Fall back on sorting by name to ensure determinism.
    return name1.compareTo(name2);
  }

  /// Returns the number of versions available for a given package.
  ///
  /// This excludes versions that don't match the root package's dependencies,
  /// since those versions can never be selected by the solver.
  Future<int> _getNumVersions(PackageRef ref) async {
    // There is only ever one version of the root package.
    if (ref.isRoot) return 1;

    var versions;
    try {
      versions = await _solver.cache.getVersions(ref);
    } catch (error, stackTrace) {
      // If it fails for any reason, just treat that as no versions. This
      // will sort this reference higher so that we can traverse into it
      // and report the error more properly.
      log.solver("Could not get versions for $ref:\n$error\n\n" +
          new Chain.forTrace(stackTrace).terse.toString());
      return 0;
    }

    // If the root package depends on this one, ignore versions that don't match
    // that constraint. Since the root package's dependency constraints won't
    // change during solving, we can safely filter out packages that don't meet
    // it.
    for (var rootDep in _solver.root.immediateDependencies) {
      if (rootDep.name != ref.name) continue;
      return versions.where((id) => rootDep.constraint.allows(id.version))
          .length;
    }

    // TODO(nweiz): Also ignore versions with non-matching SDK constraints or
    // dependencies that are incompatible with the root package's.
    return versions.length;
  }

  String toString() => _set.toString();
}
