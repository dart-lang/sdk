// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Attempts to resolve a set of version constraints for a package dependency
 * graph and select an appropriate set of best specific versions for all
 * dependent packages. It works iteratively and tries to reach a stable
 * solution where the constraints of all dependencies are met. If it fails to
 * reach a solution after a certain number of iterations, it assumes the
 * dependency graph is unstable and reports and error.
 *
 * There are two fundamental operations in the process of iterating over the
 * graph:
 *
 * 1.  Changing the selected concrete version of some package. (This includes
 *     adding and removing a package too, which is considering changing the
 *     version to or from "none".) In other words, a node has changed.
 * 2.  Changing the version constraint that one package places on another. In
 *     other words, and edge has changed.
 *
 * Both of these events have a corresponding (potentional) async operation and
 * roughly cycle back and forth between each other. When we change the version
 * of package changes, we asynchronously load the pubspec for the new version.
 * When that's done, we compare the dependencies of the new version versus the
 * old one. For everything that differs, we change those constraints between
 * this package and that dependency.
 *
 * When a constraint on a package changes, we re-calculate the overall
 * constraint on that package. I.e. with a shared dependency, we intersect all
 * of the constraints that its depending packages place on it. If that overall
 * constraint changes (say from "<3.0.0" to "<2.5.0"), then the currently
 * picked version for that package may fall outside of the new constraint. If
 * that happens, we find the new best version that meets the updated constraint
 * and then the change the package to use that version. That cycles back up to
 * the beginning again.
 */
library version_solver;

import 'dart:json';
import 'dart:math';
import 'lock_file.dart';
import 'package.dart';
import 'pubspec.dart';
import 'root_source.dart';
import 'source.dart';
import 'source_registry.dart';
import 'utils.dart';
import 'version.dart';

/**
 * Attempts to select the best concrete versions for all of the transitive
 * dependencies of [root] taking into account all of the [VersionConstraint]s
 * that those dependencies place on each other and the requirements imposed by
 * [lockFile]. If successful, completes to a [Map] that maps package names to
 * the selected version for that package. If it fails, the future will complete
 * with a [NoVersionException], [DisjointConstraintException], or
 * [CouldNotSolveException].
 */
Future<List<PackageId>> resolveVersions(SourceRegistry sources, Package root,
    LockFile lockFile) {
  print('Resolving dependencies...');
  return new VersionSolver(sources, root, lockFile).solve();
}

class VersionSolver {
  final SourceRegistry _sources;
  final Package _root;
  final LockFile lockFile;
  final PubspecCache _pubspecs;
  final Map<String, Dependency> _packages;
  final Queue<WorkItem> _work;
  int _numIterations = 0;

  VersionSolver(SourceRegistry sources, this._root, this.lockFile)
      : _sources = sources,
        _pubspecs = new PubspecCache(sources),
        _packages = <String, Dependency>{},
        _work = new Queue<WorkItem>();

  /**
   * Tell the version solver to use the most recent version of [package] that
   * exists in whatever source it's installed from. If that version violates
   * constraints imposed by other dependencies, an error will be raised when
   * solving the versions, even if an earlier compatible version exists.
   */
  void useLatestVersion(String package) {
    // TODO(nweiz): How do we want to detect and handle unknown dependencies
    // here?
    getDependency(package).useLatestVersion = true;
    lockFile.packages.remove(package);
  }

  Future<List<PackageId>> solve() {
    // Kick off the work by adding the root package at its concrete version to
    // the dependency graph.
    var ref = new PackageRef(
        _root.name, new RootSource(_root), _root.version, _root.name);
    enqueue(new AddConstraint('(entrypoint)', ref));
    _pubspecs.cache(ref.atVersion(_root.version), _root.pubspec);

    Future processNextWorkItem(_) {
      while (true) {
        // Stop if we are done.
        if (_work.isEmpty) return new Future.immediate(buildResults());

        // If we appear to be stuck in a loop, then we probably have an unstable
        // graph, bail. We guess this based on a rough heuristic that it should
        // only take a certain number of steps to solve a graph with a given
        // number of connections.
        // TODO(rnystrom): These numbers here are magic and arbitrary. Tune
        // when we have a better picture of real-world package topologies.
        _numIterations++;
        if (_numIterations > max(50, _packages.length * 5)) {
          throw new CouldNotSolveException();
        }

        // Run the first work item.
        var future = _work.removeFirst().process(this);

        // If we have an async operation to perform, chain the loop to resume
        // when it's done. Otherwise, just loop synchronously.
        if (future != null) {
          return future.chain(processNextWorkItem);
        }
      }
    }

    return processNextWorkItem(null);
  }

  void enqueue(WorkItem work) {
    _work.add(work);
  }

  Dependency getDependency(String package) {
    // There can be unused dependencies in the graph, so just create an empty
    // one if needed.
    _packages.putIfAbsent(package, () => new Dependency(package));
    return _packages[package];
  }

  /**
   * Sets the best selected version of [package] to [version].
   */
  void setVersion(String package, Version version) {
    _packages[package].version = version;
  }

  /**
   * Returns the most recent version of [dependency] that satisfies all of its
   * version constraints.
   */
  Future<Version> getBestVersion(Dependency dependency) {
    return dependency.getVersions().transform((versions) {
      var best = null;
      for (var version in versions) {
        if (dependency.useLatestVersion ||
            dependency.constraint.allows(version)) {
          if (best == null || version > best) best = version;
        }
      }

      // TODO(rnystrom): Better exception.
      if (best == null) {
        if (tryUnlockDepender(dependency)) return null;
        throw new NoVersionException(dependency.name, dependency.constraint);
      } else if (!dependency.constraint.allows(best)) {
        if (tryUnlockDepender(dependency)) return null;
        throw new CouldNotUpdateException(
            dependency.name, dependency.constraint, best);
      }

      return best;
    });
  }

  /**
   * Looks for a package that depends (transitively) on [dependency] and has its
   * version locked in the lockfile. If one is found, enqueues an
   * [UnlockPackage] work item for it and returns true. Otherwise, returns
   * false.
   *
   * This does a breadth-first search; immediate dependers will be unlocked
   * first, followed by transitive dependers.
   */
  bool tryUnlockDepender(Dependency dependency, [Set<String> seen]) {
    if (seen == null) seen = new Set();
    // Avoid an infinite loop if there are circular dependencies.
    if (seen.contains(dependency.name)) return false;
    seen.add(dependency.name);

    for (var dependerName in dependency.dependers) {
      var depender = getDependency(dependerName);
      var locked = lockFile.packages[dependerName];
      if (locked != null && depender.version == locked.version) {
        enqueue(new UnlockPackage(depender));
        return true;
      }
    }

    return dependency.dependers.map(getDependency).some((subdependency) =>
        tryUnlockDepender(subdependency, seen));
  }

  List<PackageId> buildResults() {
    return _packages.values.filter((dep) => dep.isDependedOn).map((dep) {
      var description = dep.description;

      // If the lockfile contains a fully-resolved description for the package,
      // use that. This allows e.g. Git to ensure that the same commit is used.
      var lockedPackage = lockFile.packages[dep.name];
      if (lockedPackage != null && lockedPackage.version == dep.version &&
          lockedPackage.source.name == dep.source.name &&
          dep.source.descriptionsEqual(
              description, lockedPackage.description)) {
        description = lockedPackage.description;
      }

      return new PackageId(dep.name, dep.source, dep.version, description);
    });
  }
}

/**
 * The constraint solver works by iteratively processing a queue of work items.
 * Each item is a single atomic change to the dependency graph. Handling them
 * in a queue lets us handle asynchrony (resolving versions requires information
 * from servers) as well as avoid deeply nested recursion.
*/
abstract class WorkItem {
  /**
   * Processes this work item. Returns a future that completes when the work is
   * done. If `null` is returned, that means the work has completed
   * synchronously and the next item can be started immediately.
   */
  Future process(VersionSolver solver);
}

/**
 * The best selected version for a package has changed to [version]. If the
 * previous version of the package is `null`, that means the package is being
 * added to the graph. If [version] is `null`, it is being removed.
 */
class ChangeVersion implements WorkItem {
  /// The name of the package whose version is being changed.
  final String package;

  /**
   * The source of the package whose version is changing.
   */
  final Source source;

  /**
   * The description identifying the package whose version is changing.
   */
  final description;

  /**
   * The new selected version.
   */
  final Version version;

  ChangeVersion(this.package, this.source, this.description, this.version) {
    if (source == null) throw "null source";
  }

  Future process(VersionSolver solver) {
    var dependency = solver.getDependency(package);
    var oldVersion = dependency.version;
    solver.setVersion(package, version);

    // The dependencies between the old and new version may be different. Walk
    // them both and update any constraints that differ between the two.
    return Futures.wait([
        getDependencyRefs(solver, oldVersion),
        getDependencyRefs(solver, version)]).transform((list) {
      var oldDependencyRefs = list[0];
      var newDependencyRefs = list[1];

      for (var oldRef in oldDependencyRefs.values) {
        if (newDependencyRefs.containsKey(oldRef.name)) {
          // The dependency is in both versions of this package, but its
          // constraint may have changed.
          var newRef = newDependencyRefs.remove(oldRef.name);
          solver.enqueue(new AddConstraint(package, newRef));
        } else {
          // The dependency is not in the new version of the package, so just
          // remove its constraint.
          solver.enqueue(new RemoveConstraint(package, oldRef.name));
        }
      }

      // Everything that's left is a depdendency that's only in the new
      // version of the package.
      for (var newRef in newDependencyRefs.values) {
        solver.enqueue(new AddConstraint(package, newRef));
      }
    });
  }

  /**
   * Get the dependencies at [version] of the package being changed.
   */
  Future<Map<String, PackageRef>> getDependencyRefs(VersionSolver solver,
      Version version) {
    // If there is no version, it means no package, so no dependencies.
    if (version == null) {
      return
          new Future<Map<String, PackageRef>>.immediate(<String, PackageRef>{});
    }

    var id = new PackageId(package, source, version, description);
    return solver._pubspecs.load(id).transform((pubspec) {
      var dependencies = <String, PackageRef>{};
      for (var dependency in pubspec.dependencies) {
        dependencies[dependency.name] = dependency;
      }
      return dependencies;
    });
  }
}

/**
 * A constraint that a depending package places on a dependent package has
 * changed.
 *
 * This is an abstract class that contains logic for updating the dependency
 * graph once a dependency has changed. Changing the dependency is the
 * responsibility of subclasses.
 */
abstract class ChangeConstraint implements WorkItem {
  Future process(VersionSolver solver);

  void undo(VersionSolver solver);

  Future _processChange(VersionSolver solver, Dependency oldDependency,
      Dependency newDependency) {
    var name = newDependency.name;
    var source = oldDependency.source != null ?
      oldDependency.source : newDependency.source;
    var description = oldDependency.description != null ?
      oldDependency.description : newDependency.description;
    var oldConstraint = oldDependency.constraint;
    var newConstraint = newDependency.constraint;

    // If the package is over-constrained, i.e. the packages depending have
    // disjoint constraints, then try unlocking a depender that's locked by the
    // lockfile. If there are no remaining locked dependencies, throw an error.
    if (newConstraint != null && newConstraint.isEmpty) {
      if (solver.tryUnlockDepender(newDependency)) {
        undo(solver);
        return null;
      }

      throw new DisjointConstraintException(name);
    }

    // If this constraint change didn't cause the overall constraint on the
    // package to change, then we don't need to do any further work.
    if (oldConstraint == newConstraint) return null;

    // If the dependency has been cut free from the graph, just remove it.
    if (!newDependency.isDependedOn) {
      solver.enqueue(new ChangeVersion(name, source, description, null));
      return null;
    }

    // If the dependency is on the root package, then we don't need to do
    // anything since it's already at the best version.
    if (name == solver._root.name) {
      solver.enqueue(new ChangeVersion(
          name, source, description, solver._root.version));
      return null;
    }

    // If the dependency is on a package in the lockfile, use the lockfile's
    // version for that package if it's valid given the other constraints.
    var lockedPackage = solver.lockFile.packages[name];
    if (lockedPackage != null) {
      var lockedVersion = lockedPackage.version;
      if (newConstraint.allows(lockedVersion)) {
        solver.enqueue(
            new ChangeVersion(name, source, description, lockedVersion));
        return null;
      }
    }

    // The constraint has changed, so see what the best version of the package
    // that meets the new constraint is.
    return solver.getBestVersion(newDependency).transform((best) {
      if (best == null) {
        undo(solver);
      } else if (newDependency.version != best) {
        solver.enqueue(new ChangeVersion(name, source, description, best));
      }
    });
  }
}

/**
 * The constraint given by [ref] is being placed by [depender].
 */
class AddConstraint extends ChangeConstraint {
  /**
   * The package that has the dependency.
   */
  final String depender;

  /**
   * The package being depended on and the constraints being placed on it. The
   * source, version, and description in this ref are all considered constraints
   * on the dependent package.
   */
  final PackageRef ref;

  AddConstraint(this.depender, this.ref);

  Future process(VersionSolver solver) {
    var dependency = solver.getDependency(ref.name);
    var oldDependency = dependency.clone();
    dependency.placeConstraint(depender, ref);
    return _processChange(solver, oldDependency, dependency);
  }

  void undo(VersionSolver solver) {
    solver.getDependency(ref.name).removeConstraint(depender);
  }
}

/**
 * [depender] is no longer placing a constraint on [dependent].
 */
class RemoveConstraint extends ChangeConstraint {
  /**
   * The package that was placing a constraint on [dependent].
   */
  String depender;

  /**
   * The package that was being depended on.
   */
  String dependent;

  /** The constraint that was removed. */
  PackageRef _removed;

  RemoveConstraint(this.depender, this.dependent);

  Future process(VersionSolver solver) {
    var dependency = solver.getDependency(dependent);
    var oldDependency = dependency.clone();
    _removed = dependency.removeConstraint(depender);
    return _processChange(solver, oldDependency, dependency);
  }

  void undo(VersionSolver solver) {
    solver.getDependency(dependent).placeConstraint(depender, _removed);
  }
}

/** [package]'s version is no longer constrained by the lockfile. */
class UnlockPackage implements WorkItem {
  /** The package being unlocked. */
  Dependency package;

  UnlockPackage(this.package);

  Future process(VersionSolver solver) {
    solver.lockFile.packages.remove(package.name);
    return solver.getBestVersion(package).transform((best) {
      if (best == null) return null;
      solver.enqueue(new ChangeVersion(
          package.name, package.source, package.description, best));
    });
  }
}

// TODO(rnystrom): Instead of always pulling from the source (which will mean
// hitting a server), we should consider caching pubspecs of uninstalled
// packages in the system cache.
/**
 * Maintains a cache of previously-loaded pubspecs. Used to avoid requesting
 * the same pubspec from the server repeatedly.
 */
class PubspecCache {
  final SourceRegistry _sources;
  final Map<PackageId, Pubspec> _pubspecs;

  PubspecCache(this._sources)
      : _pubspecs = new Map<PackageId, Pubspec>();

  /**
   * Caches [pubspec] as the [Pubspec] for the package identified by [id].
   */
  void cache(PackageId id, Pubspec pubspec) {
    _pubspecs[id] = pubspec;
  }

  /**
   * Loads the pubspec for the package identified by [id].
   */
  Future<Pubspec> load(PackageId id) {
    // Complete immediately if it's already cached.
    if (_pubspecs.containsKey(id)) {
      return new Future<Pubspec>.immediate(_pubspecs[id]);
    }

    return id.describe().transform((pubspec) {
      // Cache it.
      _pubspecs[id] = pubspec;
      return pubspec;
    });
  }
}

/**
 * Describes one [Package] in the [DependencyGraph] and keeps track of which
 * packages depend on it and what constraints they place on it.
 */
class Dependency {
  /**
   * The name of the this dependency's package.
   */
  final String name;

  /**
   * The [PackageRefs] that represent constraints that depending packages have
   * placed on this one.
   */
  final Map<String, PackageRef> _refs;

  /**
   * The currently-selected best version for this dependency.
   */
  Version version;

  /**
   * Whether this dependency should always select the latest version.
   */
  bool useLatestVersion = false;

  /**
   * Gets whether or not any other packages are currently depending on this
   * one. If `false`, then it means this package is not part of the dependency
   * graph and should be omitted.
   */
  bool get isDependedOn => !_refs.isEmpty;

  /** The names of all the packages that depend on this dependency. */
  Collection<String> get dependers => _refs.keys;

  /**
   * Gets the overall constraint that all packages are placing on this one.
   * If no packages have a constraint on this one (which can happen when this
   * package is in the process of being added to the graph), returns `null`.
   */
  VersionConstraint get constraint {
    if (_refs.isEmpty) return null;
    return new VersionConstraint.intersection(
        _refs.values.map((ref) => ref.constraint));
  }

  /// The source of this dependency's package.
  Source get source {
     var canonical = _canonicalRef();
     if (canonical == null) return null;
     return canonical.source;
  }

  /// The description of this dependency's package.
  get description {
     var canonical = _canonicalRef();
     if (canonical == null) return null;
     return canonical.description;
  }

  /// Return the PackageRef that has the canonical source and description for
  /// this package. If any dependency requires that this package come from a
  /// [RootSource], that will be used; otherwise, it will be the source and
  /// description that all dependencies agree upon.
  PackageRef _canonicalRef() {
    if (_refs.isEmpty) return null;
    var refs = _refs.values;
    for (var ref in refs) {
      if (ref is RootSource) return ref;
    }
    return refs[0];
  }

  Dependency(this.name)
      : _refs = <String, PackageRef>{};

  Dependency._clone(Dependency other)
      : name = other.name,
        version = other.version,
        _refs = new Map<String, PackageRef>.from(other._refs);

  /** Creates a copy of this dependency. */
  Dependency clone() => new Dependency._clone(this);

  /// Return a list of available versions for this dependency.
  Future<List<Version>> getVersions() => source.getVersions(name, description);

  /**
   * Places [ref] as a constraint from [package] onto this.
   */
  void placeConstraint(String package, PackageRef ref) {
    var required = _requiredRef();
    if (required != null) {
      if (required.source.name != ref.source.name) {
        throw new SourceMismatchException(name, required.source, ref.source);
      } else if (!required.source.descriptionsEqual(
                     required.description, ref.description)) {
        throw new DescriptionMismatchException(
            name, required.description, ref.description);
      }
    }

    _refs[package] = ref;
  }

  /// Returns a PackageRef whose source and description any new constraints are
  /// required to match. Returns null if there are no requirements on new
  /// constraints.
  PackageRef _requiredRef() {
    if (_refs.isEmpty) return null;
    var refs = _refs.values;
    var first = refs[0];
    if (refs.length == 1) {
      if (first.source is RootSource) return null;
      return first;
    }
    return refs[1];
  }

  /**
   * Removes the constraint from [package] onto this.
   */
  PackageRef removeConstraint(String package) => _refs.remove(package);
}

// TODO(rnystrom): Report the last of depending packages and their constraints.
/**
 * Exception thrown when the [VersionConstraint] used to match a package is
 * valid (i.e. non-empty), but there are no released versions of the package
 * that fit that constraint.
 */
class NoVersionException implements Exception {
  final String package;
  final VersionConstraint constraint;

  NoVersionException(this.package, this.constraint);

  String toString() =>
      "Package '$package' has no versions that match $constraint.";
}

// TODO(rnystrom): Report the list of depending packages and their constraints.
/**
 * Exception thrown when the most recent version of [package] must be selected,
 * but doesn't match the [VersionConstraint] imposed on the package.
 */
class CouldNotUpdateException implements Exception {
  final String package;
  final VersionConstraint constraint;
  final Version best;

  CouldNotUpdateException(this.package, this.constraint, this.best);

  String toString() =>
      "The latest version of '$package', $best, does not match $constraint.";
}

// TODO(rnystrom): Report the last of depending packages and their constraints.
/**
 * Exception thrown when the [VersionConstraint] used to match a package is
 * the empty set: in other words, multiple packages depend on it and have
 * conflicting constraints that have no overlap.
 */
class DisjointConstraintException implements Exception {
  final String package;

  DisjointConstraintException(this.package);

  String toString() =>
      "Package '$package' has disjoint constraints.";
}

/**
 * Exception thrown when the [VersionSolver] fails to find a solution after a
 * certain number of iterations.
 */
class CouldNotSolveException implements Exception {
  CouldNotSolveException();

  String toString() =>
      "Could not find a solution that met all version constraints.";
}

/**
 * Exception thrown when two packages with the same name but different sources
 * are depended upon.
 */
class SourceMismatchException implements Exception {
  final String package;
  final Source source1;
  final Source source2;

  SourceMismatchException(this.package, this.source1, this.source2);

  String toString() {
    return "Package '$package' is depended on from both sources "
    "'${source1.name}' and '${source2.name}'.";
  }
}

/**
 * Exception thrown when two packages with the same name and source but
 * different descriptions are depended upon.
 */
class DescriptionMismatchException implements Exception {
  final String package;
  final description1;
  final description2;

  DescriptionMismatchException(this.package, this.description1,
      this.description2);

  // TODO(nweiz): Dump to YAML when that's supported
  String toString() => "Package '$package' has conflicting descriptions "
    "'${JSON.stringify(description1)}' and '${JSON.stringify(description2)}'";
}
