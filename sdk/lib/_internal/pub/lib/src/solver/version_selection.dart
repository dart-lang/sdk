// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.solver.version_selection;

import 'dart:async';
import 'dart:collection';

import 'package:pub_semver/pub_semver.dart';

import '../package.dart';
import 'backtracking_solver.dart';
import 'unselected_package_queue.dart';
import 'version_solver.dart';

/// A representation of the version solver's current selected versions.
///
/// This is used to track the joint constraints from the selected packages on
/// other packages, as well as the set of packages that are depended on but have
/// yet to be selected.
///
/// A [VersionSelection] is always internally consistent. That is, all selected
/// packages are compatible with dependencies on those packages, no constraints
/// are empty, and dependencies agree on sources and descriptions. However, the
/// selection itself doesn't ensure this; that's up to the [BacktrackingSolver]
/// that controls it.
class VersionSelection {
  /// The version solver.
  final BacktrackingSolver _solver;

  /// The packages that have been selected, in the order they were selected.
  List<PackageId> get ids => new UnmodifiableListView<PackageId>(_ids);
  final _ids = <PackageId>[];

  /// Tracks all of the dependencies on a given package.
  ///
  /// Each key is a package. Its value is the list of dependencies placed on
  /// that package, in the order that their dependers appear in [ids].
  final _dependencies = new Map<String, List<Dependency>>();

  /// A priority queue of packages that are depended on but have yet to be
  /// selected.
  final UnselectedPackageQueue _unselected;

  /// The next package for which some version should be selected by the solver.
  PackageRef get nextUnselected =>
      _unselected.isEmpty ? null : _unselected.first;

  VersionSelection(BacktrackingSolver solver)
      : _solver = solver,
        _unselected = new UnselectedPackageQueue(solver);

  /// Adds [id] to the selection.
  Future select(PackageId id) async {
    _unselected.remove(id.toRef());
    _ids.add(id);

    // TODO(nweiz): Use a real for loop when issue 23394 is fixed.

    // Add all of [id]'s dependencies to [_dependencies], as well as to
    // [_unselected] if necessary.
    await Future.forEach(await _solver.depsFor(id), (dep) async {
      var deps = getDependencies(dep.name);
      deps.add(new Dependency(id, dep));

      // If this is the first dependency on this package, add it to the
      // unselected queue.
      if (deps.length == 1 && dep.name != _solver.root.name) {
        await _unselected.add(dep.toRef());

        // If the package depends on barback, add pub's implicit dependency on
        // barback and related packages as well.
        if (dep.name == 'barback') {
          await _unselected.add(new PackageRef.magic('pub itself'));
        }
      }
    });
  }

  /// Removes the most recently selected package from the selection.
  Future unselectLast() async {
    var id = _ids.removeLast();
    await _unselected.add(id.toRef());

    for (var dep in await _solver.depsFor(id)) {
      var deps = getDependencies(dep.name);
      deps.removeLast();

      if (deps.isEmpty) {
        _unselected.remove(dep.toRef());

        // If this was the last package that depended on barback, get rid of
        // pub's implicit dependency.
        if (dep.name == 'barback') {
          _unselected.remove(new PackageRef.magic('pub itself'));
        }
      }
    }
  }

  /// Returns the selected id for [packageName].
  PackageId selected(String packageName) =>
      ids.firstWhere((id) => id.name == packageName, orElse: () => null);

  /// Gets a "required" reference to the package [name].
  ///
  /// This is the first non-root dependency on that package. All dependencies
  /// on a package must agree on source and description, except for references
  /// to the root package. This will return a reference to that "canonical"
  /// source and description, or `null` if there is no required reference yet.
  ///
  /// This is required because you may have a circular dependency back onto the
  /// root package. That second dependency won't be a root dependency and it's
  /// *that* one that other dependencies need to agree on. In other words, you
  /// can have a bunch of dependencies back onto the root package as long as
  /// they all agree with each other.
  Dependency getRequiredDependency(String name) {
    return getDependencies(name)
        .firstWhere((dep) => !dep.dep.isRoot, orElse: () => null);
  }

  /// Gets the combined [VersionConstraint] currently placed on package [name].
  VersionConstraint getConstraint(String name) {
    var constraint = getDependencies(name)
        .map((dep) => dep.dep.constraint)
        .fold(VersionConstraint.any, (a, b) => a.intersect(b));

    // The caller should ensure that no version gets added with conflicting
    // constraints.
    assert(!constraint.isEmpty);

    return constraint;
  }

  /// Returns a string description of the dependencies on [name].
  String describeDependencies(String name) =>
      getDependencies(name).map((dep) => "  $dep").join('\n');

  /// Gets the list of known dependencies on package [name].
  ///
  /// Creates an empty list if needed.
  List<Dependency> getDependencies(String name) =>
      _dependencies.putIfAbsent(name, () => <Dependency>[]);
}
