// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A back-tracking depth-first solver. Attempts to find the best solution for
/// a root package's transitive dependency graph, where a "solution" is a set
/// of concrete package versions. A valid solution will select concrete
/// versions for every package reached from the root package's dependency graph,
/// and each of those packages will fit the version constraints placed on it.
///
/// The solver builds up a solution incrementally by traversing the dependency
/// graph starting at the root package. When it reaches a new package, it gets
/// the set of versions that meet the current constraint placed on it. It
/// *speculatively* selects one version from that set and adds it to the
/// current solution and then proceeds. If it fully traverses the dependency
/// graph, the solution is valid and it stops.
///
/// If it reaches an error because:
///
/// - A new dependency is placed on a package that's already been selected in
///   the solution and the selected version doesn't match the new constraint.
///
/// - There are no versions available that meet the constraint placed on a
///   package.
///
/// - etc.
///
/// then the current solution is invalid. It will then backtrack to the most
/// recent speculative version choice and try the next one. That becomes the
/// new in-progress solution and it tries to proceed from there. It will keep
/// doing this, traversing and then backtracking when it meets a failure until
/// a valid solution has been found or until all possible options for all
/// speculative choices have been exhausted.
library pub.solver.backtracking_solver;

import 'dart:async';
import 'dart:collection' show Queue;

import '../lock_file.dart';
import '../log.dart' as log;
import '../package.dart';
import '../pubspec.dart';
import '../sdk.dart' as sdk;
import '../source_registry.dart';
import '../utils.dart';
import '../version.dart';
import 'version_solver.dart';

/// The top-level solver. Keeps track of the current potential solution, and
/// the other possible versions for speculative package selections. Backtracks
/// and advances to the next potential solution in the case of a failure.
class BacktrackingSolver {
  final SourceRegistry sources;
  final Package root;
  final LockFile lockFile;
  final PubspecCache cache;

  /// The set of packages that are being explicitly upgraded. The solver will
  /// only allow the very latest version for each of these packages.
  final _forceLatest = new Set<String>();

  /// Every time a package is encountered when traversing the dependency graph,
  /// the solver must select a version for it, sometimes when multiple versions
  /// are valid. This keeps track of which versions have been selected so far
  /// and which remain to be tried.
  ///
  /// Each entry in the list is an ordered [Queue] of versions to try for a
  /// single package. The first item in the queue is the currently selected
  /// version for that package. When a new dependency is encountered, a queue
  /// of versions of that dependency is pushed onto the end of the list. A
  /// queue is removed from the list once it's empty, indicating that none of
  /// the versions provided a solution.
  ///
  /// The solver tries versions in depth-first order, so only the last queue in
  /// the list will have items removed from it. When a new constraint is placed
  /// on an already-selected package, and that constraint doesn't match the
  /// selected version, that will cause the current solution to fail and
  /// trigger backtracking.
  final _selected = <Queue<PackageId>>[];

  /// The number of solutions the solver has tried so far.
  int get attemptedSolutions => _attemptedSolutions;
  var _attemptedSolutions = 1;

  BacktrackingSolver(SourceRegistry sources, this.root, this.lockFile,
                     List<String> useLatest)
      : sources = sources,
        cache = new PubspecCache(sources) {
    for (var package in useLatest) {
      forceLatestVersion(package);
      lockFile.packages.remove(package);
    }
  }

  /// Run the solver. Completes with a list of specific package versions if
  /// successful or an error if it failed to find a solution.
  Future<SolveResult> solve() {
    var stopwatch = new Stopwatch();

    _logParameters();

    return newFuture(() {
      stopwatch.start();

      // Pre-cache the root package's known pubspec.
      cache.cache(new PackageId.root(root), root.pubspec);

      _validateSdkConstraint(root.pubspec);
      return _traverseSolution();
    }).then((packages) {
      return new SolveResult(packages, null, attemptedSolutions);
    }).catchError((error) {
      if (error is! SolveFailure) throw error;

      // Wrap a failure in a result so we can attach some other data.
      return new SolveResult(null, error, attemptedSolutions);
    }).whenComplete(() {
      // Gather some solving metrics.
      var buffer = new StringBuffer();
      buffer.writeln('${runtimeType} took ${stopwatch.elapsed} seconds.');
      buffer.writeln(
          '- Requested ${cache.versionCacheMisses} version lists');
      buffer.writeln(
          '- Looked up ${cache.versionCacheHits} cached version lists');
      buffer.writeln(
          '- Requested ${cache.pubspecCacheMisses} pubspecs');
      buffer.writeln(
          '- Looked up ${cache.pubspecCacheHits} cached pubspecs');
      log.solver(buffer);
    });
  }

  void forceLatestVersion(String package) {
    _forceLatest.add(package);
  }

  /// Adds [versions], which is the list of all allowed versions of a given
  /// package, to the set of versions to consider for solutions. The first item
  /// in the list will be the currently selected version of that package.
  /// Subsequent items will be tried if it the current selection fails. Returns
  /// the first selected version.
  PackageId select(Iterable<PackageId> versions) {
    _selected.add(new Queue<PackageId>.from(versions));
    logSolve();
    return versions.first;
  }

  /// Returns the the currently selected id for the package [name] or `null` if
  /// no concrete version has been selected for that package yet.
  PackageId getSelected(String name) {
    // Always prefer the root package.
    if (root.name == name) return new PackageId.root(root);

    // Look through the current selections.
    for (var i = _selected.length - 1; i >= 0; i--) {
      if (_selected[i].first.name == name) return _selected[i].first;
    }

    return null;
  }

  /// Gets the version of [package] currently locked in the lock file. Returns
  /// `null` if it isn't in the lockfile (or has been unlocked).
  PackageId getLocked(String package) => lockFile.packages[package];

  /// Traverses the root package's dependency graph using the current potential
  /// solution. If successful, completes to the solution. If not, backtracks
  /// to the most recently selected version of a package and tries the next
  /// version of it. If there are no more versions, continues to backtrack to
  /// previous selections, and so on. If there is nothing left to backtrack to,
  /// completes to the last failure that occurred.
  Future<List<PackageId>> _traverseSolution() => resetStack(() {
    return new Traverser(this).traverse().catchError((error) {
      if (error is! SolveFailure) throw error;

      if (_backtrack(error)) {
        _attemptedSolutions++;
        return _traverseSolution();
      }

      // All out of solutions, so fail.
      throw error;
    });
  });

  /// Backtracks from the current failed solution and determines the next
  /// solution to try. If possible, it will backjump based on the cause of the
  /// [failure] to minize backtracking. Otherwise, it will simply backtrack to
  /// the next possible solution.
  ///
  /// Returns `true` if there is a new solution to try.
  bool _backtrack(SolveFailure failure) {
    var dependers = failure.dependencies.map((dep) => dep.depender).toSet();

    while (!_selected.isEmpty) {
      _backjump(failure);

      // Advance past the current version of the leaf-most package.
      var previous = _selected.last.removeFirst();
      if (!_selected.last.isEmpty) {
        logSolve();
        return true;
      }

      logSolve('$previous is last version, backtracking');

      // That package has no more versions, so pop it and try the next one.
      _selected.removeLast();
    }

    return false;
  }

  /// Walks the selected packages from most to least recent to determine which
  /// ones can be ignored and jumped over by the backtracker. The only packages
  /// we need to backtrack to are ones that have other versions to try and that
  /// led (possibly indirectly) to the failure. Everything else can be skipped.
  void _backjump(SolveFailure failure) {
    for (var i = _selected.length - 1; i >= 0; i--) {
      // Each queue will never be empty since it gets discarded by _backtrack()
      // when that happens.
      var selected = _selected[i].first;

      // If the package has no more versions, we can jump over it.
      if (_selected[i].length == 1) continue;

      // If we get to the package that failed, backtrack to here.
      if (selected.name == failure.package) {
        logSolve('backjump to failed package ${selected.name}');
        _selected.removeRange(i + 1, _selected.length);
        return;
      }

      // If we get to a package that depends on the failing package, backtrack
      // to here.
      var path = _getDependencyPath(selected, failure.package);
      if (path != null) {
        logSolve('backjump to ${selected.name} because it depends on '
                 '${failure.package} along $path');
        _selected.removeRange(i + 1, _selected.length);
        return;
      }
    }

    // If we got here, we walked the entire list without finding a package that
    // could lead to another solution, so discard everything. This will happen
    // if every package that led to the failure has no other versions that it
    // can try to select.
    _selected.removeRange(1, _selected.length);
  }

  /// Determines if [depender] has a direct or indirect dependency on
  /// [dependent] based on the currently selected versions of all packages.
  /// Returns a string describing the dependency chain if it does, or `null` if
  /// there is no dependency.
  String _getDependencyPath(PackageId depender, String dependent) {
    // TODO(rnystrom): This is O(n^2) where n is the number of selected
    // packages. Could store the reverse dependency graph to address that. If
    // we do that, we need to make sure it gets correctly rolled back when
    // backtracking occurs.
    var visited = new Set<String>();

    walkDeps(PackageId package, String currentPath) {
      if (visited.contains(package.name)) return null;
      visited.add(package.name);

      var pubspec = cache.getCachedPubspec(package);
      if (pubspec == null) return null;

      for (var dep in pubspec.dependencies) {
        if (dep.name == dependent) return currentPath;

        var selected = getSelected(dep.name);
        // Ignore unselected dependencies. We haven't traversed into them yet,
        // so they can't affect backjumping.
        if (selected == null) continue;

        var depPath = walkDeps(selected, '$currentPath -> ${dep.name}');
        if (depPath != null) return depPath;
      }

      return null;
    }

    return walkDeps(depender, depender.name);
  }

  /// Logs the initial parameters to the solver.
  void _logParameters() {
    var buffer = new StringBuffer();
    buffer.writeln("Solving dependencies:");
    for (var package in root.dependencies) {
      buffer.write("- $package");
      if (_forceLatest.contains(package.name)) {
        buffer.write(" (use latest)");
      } else if (lockFile.packages.containsKey(package.name)) {
        var version = lockFile.packages[package.name].version;
        buffer.write(" (locked to $version)");
      }
      buffer.writeln();
    }
    log.solver(buffer.toString().trim());
  }

  /// Logs [message] in the context of the current selected packages. If
  /// [message] is omitted, just logs a description of leaf-most selection.
  void logSolve([String message]) {
    if (message == null) {
      if (_selected.isEmpty) {
        message = "* start at root";
      } else {
        var count = _selected.last.length;
        message = "* select ${_selected.last.first} ($count versions)";
      }
    } else {
      // Otherwise, indent it under the current selected package.
      message = "| $message";
    }

    // Indent for the previous selections.
    var buffer = new StringBuffer();
    buffer.writeAll(_selected.skip(1).map((_) => '| '));
    buffer.write(message);
    log.solver(buffer);
  }
}

/// Given the solver's current set of selected package versions, this tries to
/// traverse the dependency graph and see if a complete set of valid versions
/// has been chosen. If it reaches a conflict, it will fail and stop
/// traversing. If it reaches a package that isn't selected it will refine the
/// solution by adding that package's set of allowed versions to the solver and
/// then select the best one and continue.
class Traverser {
  final BacktrackingSolver _solver;

  /// The queue of packages left to traverse. We do a breadth-first traversal
  /// using an explicit queue just to avoid the code complexity of a recursive
  /// asynchronous traversal.
  final _packages = new Queue<PackageId>();

  /// The packages we have already traversed. Used to avoid traversing the same
  /// package multiple times, and to build the complete solution results.
  final _visited = new Set<PackageId>();

  /// The dependencies visited so far in the traversal. For each package name
  /// (the map key) we track the list of dependencies that other packages have
  /// placed on it so that we can calculate the complete constraint for shared
  /// dependencies.
  final _dependencies = <String, List<Dependency>>{};

  Traverser(this._solver);

  /// Walks the dependency graph starting at the root package and validates
  /// that each reached package has a valid version selected.
  Future<List<PackageId>> traverse() {
    // Start at the root.
    _packages.add(new PackageId.root(_solver.root));
    return _traversePackage();
  }

  /// Traverses the next package in the queue. Completes to a list of package
  /// IDs if the traversal completed successfully and found a solution.
  /// Completes to an error if the traversal failed. Otherwise, recurses to the
  /// next package in the queue, etc.
  Future<List<PackageId>> _traversePackage() {
    if (_packages.isEmpty) {
      // We traversed the whole graph. If we got here, we successfully found
      // a solution.
      return new Future<List<PackageId>>.value(_visited.toList());
    }

    var id = _packages.removeFirst();

    // Don't visit the same package twice.
    if (_visited.contains(id)) {
      return _traversePackage();
    }
    _visited.add(id);

    return _solver.cache.getPubspec(id).then((pubspec) {
      _validateSdkConstraint(pubspec);

      var deps = pubspec.dependencies.toList();

      // Include dev dependencies of the root package.
      if (id.isRoot) deps.addAll(pubspec.devDependencies);

      // Make sure the package doesn't have any bad dependencies.
      for (var dep in deps) {
        if (!dep.isRoot && !_solver.sources.contains(dep.source)) {
          throw new UnknownSourceException(id.name,
              [new Dependency(id.name, dep)]);
        }
      }

      // Given a package dep, returns a future that completes to a pair of the
      // dep and the number of versions available for it.
      getNumVersions(PackageDep dep) {
        // There is only ever one version of the root package.
        if (dep.isRoot) {
          return new Future.value(new Pair<PackageDep, int>(dep, 1));
        }

        return _solver.cache.getVersions(dep.toRef()).then((versions) {
          return new Pair<PackageDep, int>(dep, versions.length);
        }).catchError((error) {
          // If it fails for any reason, just treat that as no versions. This
          // will sort this reference higher so that we can traverse into it
          // and report the error more properly.
          log.solver("Could not get versions for $dep:\n$error\n\n"
              "${getAttachedStackTrace(error)}");
          return new Pair<PackageDep, int>(dep, 0);
        });
      }

      return Future.wait(deps.map(getNumVersions)).then((pairs) {
        // Future.wait() returns an immutable list, so make a copy.
        pairs = pairs.toList();

        // Sort in best-first order to minimize backtracking.
        pairs.sort((a, b) {
          // Traverse into packages we've already selected first.
          var aIsSelected = _solver.getSelected(a.first.name) != null;
          var bIsSelected = _solver.getSelected(b.first.name) != null;
          if (aIsSelected && !bIsSelected) return -1;
          if (!aIsSelected && bIsSelected) return 1;

          // Traverse into packages with fewer versions since they will lead to
          // less backtracking.
          if (a.last != b.last) return a.last.compareTo(b.last);

          // Otherwise, just sort by name so that it's deterministic.
          return a.first.name.compareTo(b.first.name);
        });

        var queue = new Queue<PackageDep>.from(pairs.map((pair) => pair.first));
        return _traverseDeps(id.name, queue);
      });
    });
  }

  /// Traverses the references that [depender] depends on, stored in [deps].
  /// Desctructively modifies [deps]. Completes to a list of packages if the
  /// traversal is complete. Completes it to an error if a failure occurred.
  /// Otherwise, recurses.
  Future<List<PackageId>> _traverseDeps(String depender,
      Queue<PackageDep> deps) {
    // Move onto the next package if we've traversed all of these references.
    if (deps.isEmpty) return _traversePackage();

    return resetStack(() {
      var dep = deps.removeFirst();

      _validateDependency(dep, depender);
      var constraint = _addConstraint(dep, depender);

      var selected = _validateSelected(dep, constraint);
      if (selected != null) {
        // The selected package version is good, so enqueue it to traverse into
        // it.
        _packages.add(selected);
        return _traverseDeps(depender, deps);
      }

      // We haven't selected a version. Get all of the versions that match the
      // constraints we currently have for this package and add them to the
      // set of solutions to try.
      return _selectPackage(dep, constraint).then(
          (_) => _traverseDeps(depender, deps));
    });
  }

  /// Ensures that dependency [dep] from [depender] is consistent with the
  /// other dependencies on the same package. Throws a [SolveFailure]
  /// exception if not. Only validates sources and descriptions, not the
  /// version.
  void _validateDependency(PackageDep dep, String depender) {
    // Make sure the dependencies agree on source and description.
    var required = _getRequired(dep.name);
    if (required == null) return;

    // Make sure all of the existing sources match the new reference.
    if (required.dep.source != dep.source) {
      _solver.logSolve('source mismatch on ${dep.name}: ${required.dep.source} '
                       '!= ${dep.source}');
      throw new SourceMismatchException(dep.name,
          [required, new Dependency(depender, dep)]);
    }

    // Make sure all of the existing descriptions match the new reference.
    var source = _solver.sources[dep.source];
    if (!source.descriptionsEqual(dep.description, required.dep.description)) {
      _solver.logSolve('description mismatch on ${dep.name}: '
                       '${required.dep.description} != ${dep.description}');
      throw new DescriptionMismatchException(dep.name,
          [required, new Dependency(depender, dep)]);
    }
  }

  /// Adds the version constraint that [depender] places on [dep] to the
  /// overall constraint that all shared dependencies place on [dep]. Throws a
  /// [SolveFailure] if that results in an unsolvable constraints.
  ///
  /// Returns the combined [VersionConstraint] that all dependers place on the
  /// package.
  VersionConstraint _addConstraint(PackageDep dep, String depender) {
    // Add the dependency.
    var dependencies = _getDependencies(dep.name);
    dependencies.add(new Dependency(depender, dep));

    // Determine the overall version constraint.
    var constraint = dependencies
        .map((dep) => dep.dep.constraint)
        .fold(VersionConstraint.any, (a, b) => a.intersect(b));

    // See if it's possible for a package to match that constraint.
    if (constraint.isEmpty) {
      _solver.logSolve('disjoint constraints on ${dep.name}');
      throw new DisjointConstraintException(depender, dependencies);
    }

    return constraint;
  }

  /// Validates the currently selected package against the new dependency that
  /// [dep] and [constraint] place on it. Returns `null` if there is no
  /// currently selected package, throws a [SolveFailure] if the new reference
  /// it not does not allow the previously selected version, or returns the
  /// selected package if successful.
  PackageId _validateSelected(PackageDep dep, VersionConstraint constraint) {
    var selected = _solver.getSelected(dep.name);
    if (selected == null) return null;

    // Make sure it meets the constraint.
    if (!dep.constraint.allows(selected.version)) {
      _solver.logSolve('selection $selected does not match $constraint');
      throw new NoVersionException(dep.name, constraint,
                                   _getDependencies(dep.name));
    }

    return selected;
  }

  /// Tries to select a package that matches [dep] and [constraint]. Updates
  /// the solver state so that we can backtrack from this decision if it turns
  /// out wrong, but continues traversing with the new selection.
  ///
  /// Returns a future that completes with a [SolveFailure] if a version
  /// could not be selected or that completes successfully if a package was
  /// selected and traversing should continue.
  Future _selectPackage(PackageDep dep, VersionConstraint constraint) {
    return _solver.cache.getVersions(dep.toRef()).then((versions) {
      var allowed = versions.where((id) => constraint.allows(id.version));

      // See if it's in the lockfile. If so, try that version first. If the
      // locked version doesn't match our constraint, just ignore it.
      var locked = _getValidLocked(dep.name, constraint);
      if (locked != null) {
        allowed = allowed.where((dep) => dep.version != locked.version)
            .toList();
        allowed.insert(0, locked);
      }

      if (allowed.isEmpty) {
        _solver.logSolve('no versions for ${dep.name} match $constraint');
        throw new NoVersionException(dep.name, constraint,
                                     _getDependencies(dep.name));
      }

      // If we're doing an upgrade on this package, only allow the latest
      // version.
      if (_solver._forceLatest.contains(dep.name)) allowed = [allowed.first];

      // Try the first package in the allowed set and keep track of the list of
      // other possible versions in case that fails.
      _packages.add(_solver.select(allowed));
    });
  }

  /// Gets the list of dependencies for package [name]. Will create an empty
  /// list if needed.
  List<Dependency> _getDependencies(String name) {
    return _dependencies.putIfAbsent(name, () => <Dependency>[]);
  }

  /// Gets a "required" reference to the package [name]. This is the first
  /// non-root dependency on that package. All dependencies on a package must
  /// agree on source and description, except for references to the root
  /// package. This will return a reference to that "canonical" source and
  /// description, or `null` if there is no required reference yet.
  ///
  /// This is required because you may have a circular dependency back onto the
  /// root package. That second dependency won't be a root dependency and it's
  /// *that* one that other dependencies need to agree on. In other words, you
  /// can have a bunch of dependencies back onto the root package as long as
  /// they all agree with each other.
  Dependency _getRequired(String name) {
    return _getDependencies(name)
        .firstWhere((dep) => !dep.dep.isRoot, orElse: () => null);
  }

  /// Gets the package [name] that's currently contained in the lockfile if it
  /// meets [constraint] and has the same source and description as other
  /// references to that package. Returns `null` otherwise.
  PackageId _getValidLocked(String name, VersionConstraint constraint) {
    var package = _solver.getLocked(name);
    if (package == null) return null;

    if (!constraint.allows(package.version)) {
      _solver.logSolve('$package is locked but does not match $constraint');
      return null;
    } else {
      _solver.logSolve('$package is locked');
    }

    var required = _getRequired(name);
    if (required != null) {
      if (package.source != required.dep.source) return null;

      var source = _solver.sources[package.source];
      if (!source.descriptionsEqual(
          package.description, required.dep.description)) return null;
    }

    return package;
  }
}

/// Ensures that if [pubspec] has an SDK constraint, then it is compatible
/// with the current SDK. Throws a [SolveFailure] if not.
void _validateSdkConstraint(Pubspec pubspec) {
  // If the user is running a continouous build of the SDK, just disable SDK
  // constraint checking entirely. The actual version number you get is
  // impossibly old and not correct. We'll just assume users on continuous
  // know what they're doing.
  if (sdk.isBleedingEdge) return;

  if (pubspec.environment.sdkVersion.allows(sdk.version)) return;

  throw new BadSdkVersionException(pubspec.name,
      'Package ${pubspec.name} requires SDK version '
      '${pubspec.environment.sdkVersion} but the current SDK is '
      '${sdk.version}.');
}
