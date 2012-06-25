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
#library('version_solver');

#import('package.dart');
#import('pubspec.dart');
#import('source.dart');
#import('source_registry.dart');
#import('utils.dart');
#import('version.dart');

/**
 * Attempts to select the best concrete versions for all of the transitive
 * dependencies of [root] taking into account all of the [VersionConstraint]s
 * that those dependencies place on each other. If successful, completes to a
 * [Map] that maps package names to the selected version for that package. If
 * it fails, the future will complete with a [NoVersionException],
 * [DisjointConstraintException], or [CouldNotSolveException].
 */
Future<Map<String, Version>> resolveVersions(
    SourceRegistry sources, Package root) {
  return new VersionSolver(sources).solve(root);
}

class VersionSolver {
  final SourceRegistry _sources;
  final PubspecCache _pubspecs;
  final Map<String, Dependency> _packages;
  final Queue<WorkItem> _work;
  int _numIterations = 0;

  VersionSolver(SourceRegistry sources)
      : _sources = sources,
        _pubspecs = new PubspecCache(sources),
        _packages = <Dependency>{},
        _work = new Queue<WorkItem>();

  Future<Map<String, Version>> solve(Package root) {
    // Kick off the work by adding the root package at its concrete version to
    // the dependency graph.
    _pubspecs.cache(root);
    enqueue(new ChangeConstraint('(entrypoint)', root.name, root.version));

    Future processNextWorkItem(_) {
      while (true) {
        // Stop if we are done.
        if (_work.isEmpty()) return new Future.immediate(buildResults());

        // If we appear to be stuck in a loop, then we probably have an unstable
        // graph, bail. We guess this based on a rough heuristic that it should
        // only take a certain number of steps to solve a graph with a given
        // number of connections.
        // TODO(rnystrom): These numbers here are magic and arbitrary. Tune
        // when we have a better picture of real-world package topologies.
        _numIterations++;
        if (_numIterations > Math.max(50, _packages.length * 5)) {
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
    _packages.putIfAbsent(package, () => new Dependency());
    return _packages[package];
  }

  /**
   * Sets the best selected version of [package] to [version].
   */
  void setVersion(String package, Version version) {
    _packages[package].version = version;
  }

  Map<String, Version> buildResults() {
    var results = <Version>{};
    _packages.forEach((name, dependency) {
      if (dependency.isDependedOn) {
        results[name] = dependency.version;
      }
    });

    return results;
  }
}

/**
 * The constraint solver works by iteratively processing a queue of work items.
 * Each item is a single atomic change to the dependency graph. Handling them
 * in a queue lets us handle asynchrony (resolving versions requires information
 * from servers) as well as avoid deeply nested recursion.
*/
interface WorkItem {
  /**
   * Processes this work item. Returns a future that completes when the work is
   * done. If `null` is returned, that means the work has completed
   * synchronously and the next item can be started immediately.
   */
  Future process(VersionSolver solver);
}

/**
 * The best selected version for [package] has changed to [version].
 * If the previous version of the package is `null`, that means the package is
 * being added to the graph. If [version] is `null`, it is being removed.
 */
class ChangeVersion implements WorkItem {
  /**
   * The package whose version is changing.
   */
  final String package;

  /**
   * The new selected version.
   */
  final Version version;

  ChangeVersion(this.package, this.version);

  Future process(VersionSolver solver) {
    var oldVersion = solver.getDependency(package).version;
    solver.setVersion(package, version);

    // The dependencies between the old and new version may be different. Walk
    // them both and update any constraints that differ between the two.
    return Futures.wait([
        getDependencyRefs(solver, oldVersion),
        getDependencyRefs(solver, version)]).transform((list) {
      var oldDependencies = list[0];
      var newDependencies = list[1];

      for (var dependency in oldDependencies.getValues()) {
        var constraint;
        if (newDependencies.containsKey(dependency.name)) {
          // The dependency is in both versions of this package, but its
          // constraint may have changed.
          constraint = newDependencies.remove(dependency.name).constraint;
        } else {
          // The dependency is not in the new version of the package, so just
          // remove its constraint.
          constraint = null;
        }

        solver.enqueue(new ChangeConstraint(
            package, dependency.name, constraint));
      }

      // Everything that's left is a depdendency that's only in the new
      // version of the package.
      for (var dependency in newDependencies.getValues()) {
        solver.enqueue(new ChangeConstraint(
            package, dependency.name, dependency.constraint));
      }
    });
  }

  /**
   * Get the dependencies that [package] has at [version].
   */
  Future<Map<String, PackageRef>> getDependencyRefs(VersionSolver solver,
      Version version) {
    // If there is no version, it means no package, so no dependencies.
    if (version == null) {
      return new Future<Map<String, PackageRef>>.immediate(<PackageRef>{});
    }

    return solver._pubspecs.load(package, version).transform((pubspec) {
      var dependencies = <PackageRef>{};
      for (var dependency in pubspec.dependencies) {
        dependencies[dependency.name] = dependency;
      }
      return dependencies;
    });
  }
}

/**
 * The [VersionConstraint] that [depender] places on [dependent] has changed.
 */
class ChangeConstraint implements WorkItem {
  /**
   * The package that has the dependency.
   */
  final String depender;

  /**
   * The package being depended on.
   */
  final String dependent;

  /**
   * The constraint that [depender] places on [dependent]'s version.
   */
  final VersionConstraint constraint;

  ChangeConstraint(this.depender, this.dependent, this.constraint);

  Future process(VersionSolver solver) {
    var dependency = solver.getDependency(dependent);
    var oldConstraint = dependency.constraint;
    dependency.placeConstraint(depender, constraint);
    var newConstraint = dependency.constraint;

    // If the package is over-constrained, i.e. the packages depending have
    // disjoint constraints, then stop.
    if (newConstraint != null && newConstraint.isEmpty) {
      throw new DisjointConstraintException(dependent);
    }

    // If this constraint change didn't cause the overall constraint on the
    // package to change, then we don't need to do any further work.
    if (oldConstraint == newConstraint) return null;

    // If the dependency has been cut free from the graph, just remove it.
    if (!dependency.isDependedOn) {
      solver.enqueue(new ChangeVersion(dependent, null));
      return null;
    }

    // The constraint has changed, so see what the best version of the package
    // that meets the new constraint is.
    // TODO(rnystrom): Should this always be the default source?
    var source = solver._sources.defaultSource;
    return source.getVersions(dependent).transform((versions) {
      var best = null;
      for (var version in versions) {
        if (newConstraint.allows(version)) {
          if (best == null || version > best) best = version;
        }
      }

      // TODO(rnystrom): Better exception.
      if (best == null) throw new NoVersionException(dependent, newConstraint);

      if (dependency.version != best) {
        solver.enqueue(new ChangeVersion(dependent, best));
      }
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
  final Map<String, Map<Version, Pubspec>> _pubspecs;

  PubspecCache(this._sources)
      : _pubspecs = <Map<Version, Pubspec>>{};

  /**
   * Adds the already loaded [package] to the cache.
   */
  void cache(Package package) {
    _pubspecs.putIfAbsent(package.name, () => new Map<Version, Pubspec>());
    _pubspecs[package.name][package.version] = package.pubspec;
  }

  /**
   * Loads the pubspec for [package] at [version].
   */
  Future<Pubspec> load(String package, Version version) {
    // Complete immediately if it's already cached.
    if (_pubspecs.containsKey(package) &&
        _pubspecs[package].containsKey(version)) {
      return new Future<Pubspec>.immediate(_pubspecs[package][version]);
    }

    // TODO(rnystrom): Should this always be the default source?
    var source = _sources.defaultSource;
    return source.describe(package, version).transform((pubspec) {
      // Cache it.
      _pubspecs.putIfAbsent(package, () => new Map<Version, Pubspec>());
      _pubspecs[package][version] = pubspec;

      return pubspec;
    });
  }
}

/**
 * Describes one [Package] in the [DependencyGraph] and keeps track of which
 * packages depend on it and what [VersionConstraint]s they place on it.
 */
class Dependency {
  /**
   * The currently selected best version for this dependency.
   */
  Version version;

  /**
   * The constraints that depending packages have placed on this one.
   */
  final Map<String, VersionConstraint> _constraints;

  /**
   * Gets whether or not any other packages are currently depending on this
   * one. If `false`, then it means this package is not part of the dependency
   * graph and should be omitted.
   */
  bool get isDependedOn() => !_constraints.isEmpty();

  /**
   * Gets the overall constraint that all packages are placing on this one.
   * If no packages have a constraint on this one (which can happen when this
   * package is in the process of being added to the graph), returns `null`.
   */
  VersionConstraint get constraint() {
    if (_constraints.isEmpty()) return null;
    return new VersionConstraint.intersect(_constraints.getValues());
  }

  Dependency()
      : _constraints = <VersionConstraint>{};

  /**
   * Places [constraint] from [package] onto this.
   */
  void placeConstraint(String package, VersionConstraint constraint) {
    if (constraint == null) {
      _constraints.remove(package);
    } else {
      _constraints[package] = constraint;
    }
  }
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
