// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library version_solver;

import 'dart:async';
import 'dart:json' as json;

import '../lock_file.dart';
import '../log.dart' as log;
import '../package.dart';
import '../pubspec.dart';
import '../source.dart';
import '../source_registry.dart';
import '../version.dart';
import 'backtracking_solver.dart';
import 'greedy_solver.dart';

/// Attempts to select the best concrete versions for all of the transitive
/// dependencies of [root] taking into account all of the [VersionConstraint]s
/// that those dependencies place on each other and the requirements imposed by
/// [lockFile].
///
/// If [useLatest] is given, then only the latest versions of the referenced
/// packages will be used. This is for forcing an update to one or more
/// packages.
///
/// If [allowBacktracking] is `true` the backtracking version solver will
/// be used. Otherwise, the non-backtracking one will be.
Future<SolveResult> resolveVersions(SourceRegistry sources, Package root,
    {LockFile lockFile, bool allowBacktracking, List<PackageRef> useLatest}) {
  log.message('Resolving dependencies...');

  if (allowBacktracking == null) allowBacktracking = false;
  if (lockFile == null) lockFile = new LockFile.empty();
  if (useLatest == null) useLatest = [];

  var solver;
  if (allowBacktracking) {
    solver = new BacktrackingVersionSolver(sources, root, lockFile, useLatest);
  } else {
    solver = new GreedyVersionSolver(sources, root, lockFile, useLatest);
  }

  return solver.solve();
}

/// Base class for an implementation of the version constraint solver.
class VersionSolver {
  final SourceRegistry sources;
  final Package root;
  final LockFile lockFile;
  final PubspecCache cache;

  VersionSolver(SourceRegistry sources, this.root, this.lockFile,
                List<String> useLatest)
      : sources = sources,
        cache = new PubspecCache(sources) {
    for (var package in useLatest) {
      forceLatestVersion(package);
      lockFile.packages.remove(package);
    }
  }

  /// The number of solutions the solver has tried so far.
  int get attemptedSolutions;

  /// Force the solver to upgrade [package] to the latest available version.
  void forceLatestVersion(String package);

  /// Run the solver. Completes with a list of specific package versions if
  /// successful or an error if it failed to find a solution.
  Future<SolveResult> solve() {
    var stopwatch = new Stopwatch();
    stopwatch.start();

    // Pre-cache the root package's known pubspec.
    cache.cache(new PackageId.root(root), root.pubspec);

    return runSolver().then((packages) {
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

  /// Entrypoint for subclasses to actually begin solving. External code should
  /// call [solve()].
  Future<List<PackageId>> runSolver();
}

/// The result of a version resolution.
class SolveResult {
  /// Whether the solver found a complete solution or failed.
  bool get succeeded => error == null;

  /// The list of concrete package versions that were selected for each package
  /// reachable from the root, or `null` if the solver failed.
  final List<PackageId> packages;

  /// The error that prevented the solver from finding a solution or `null` if
  /// it was successful.
  final SolveFailure error;

  /// The number of solutions that were attempted before either finding a
  /// successful solution or exhausting all options. In other words, one more
  /// than the number of times it had to backtrack because it found an invalid
  /// solution.
  final int attemptedSolutions;

  SolveResult(this.packages, this.error, this.attemptedSolutions);

  String toString() {
    if (!succeeded) {
      return 'Failed to solve after $attemptedSolutions attempts:\n'
             '$error';
    }

    return 'Took $attemptedSolutions tries to resolve to\n'
           '- ${packages.join("\n- ")}';
  }
}

/// Maintains a cache of previously-requested data: pubspecs and version lists.
/// Used to avoid requesting the same pubspec from the server repeatedly.
class PubspecCache {
  final SourceRegistry _sources;
  final _versions = new Map<PackageId, List<PackageId>>();
  final _pubspecs = new Map<PackageId, Pubspec>();

  /// The number of times a version list was requested and it wasn't cached and
  /// had to be requested from the source.
  int versionCacheMisses = 0;

  /// The number of times a version list was requested and the cached version
  /// was returned.
  int versionCacheHits = 0;

  /// The number of times a pubspec was requested and it wasn't cached and had
  /// to be requested from the source.
  int pubspecCacheMisses = 0;

  /// The number of times a pubspec was requested and the cached version was
  /// returned.
  int pubspecCacheHits = 0;

  PubspecCache(this._sources);

  /// Caches [pubspec] as the [Pubspec] for the package identified by [id].
  void cache(PackageId id, Pubspec pubspec) {
    _pubspecs[id] = pubspec;
  }

  /// Loads the pubspec for the package identified by [id].
  Future<Pubspec> getPubspec(PackageId id) {
    // Complete immediately if it's already cached.
    if (_pubspecs.containsKey(id)) {
      pubspecCacheHits++;
      return new Future<Pubspec>.value(_pubspecs[id]);
    }

    pubspecCacheMisses++;
    return id.describe().then((pubspec) {
      log.solver('requested $id pubspec');

      // Cache it.
      _pubspecs[id] = pubspec;
      return pubspec;
    });
  }

  /// Returns the previously cached pubspec for the package identified by [id]
  /// or returns `null` if not in the cache.
  Pubspec getCachedPubspec(PackageId id) => _pubspecs[id];

  /// Gets the list of versions for [package] in descending order.
  Future<List<PackageId>> getVersions(String package, Source source,
      description) {
    // Create a fake ID to use as a key.
    // TODO(rnystrom): Create a separate type for (name, source, description)
    // without a version.
    var id = new PackageId(package, source, Version.none, description);

    // See if we have it cached.
    var versions = _versions[id];
    if (versions != null) {
      versionCacheHits++;
      return new Future.value(versions);
    }

    versionCacheMisses++;
    return source.getVersions(package, description).then((versions) {
      var ids = versions
          .map((version) => new PackageId(package, source, version,
              description))
          .toList();

      // Sort by descending version so we try newer versions first.
      ids.sort((a, b) => b.version.compareTo(a.version));

      log.solver('requested $package version list');
      _versions[id] = ids;
      return ids;
    });
  }
}

/// A reference from a depending package to a package that it depends on.
class Dependency {
  /// The name of the package that has this dependency.
  final String depender;

  /// The referenced dependent package.
  final PackageRef ref;

  Dependency(this.depender, this.ref);

  String toString() => '$depender -> $ref';
}

/// Base class for all failures that can occur while trying to resolve versions.
class SolveFailure implements Exception {
  /// The name of the package whose version could not be solved. Will be `null`
  /// if the failure is not specific to one package.
  final String package;

  /// The known dependencies on [package] at the time of the failure. Will be
  /// an empty collection if the failure is not specific to one package.
  final Iterable<Dependency> dependencies;

  SolveFailure(this.package, Iterable<Dependency> dependencies)
      : dependencies = dependencies != null ? dependencies : <Dependency>[];

  /// Writes [dependencies] to [buffer] as a bullet list. If [describe] is
  /// passed, it will be called for each dependency and the result will be
  /// written next to the dependency.
  void writeDependencies(StringBuffer buffer,
      [String describe(PackageRef ref)]) {
    var map = {};
    for (var dep in dependencies) {
      map[dep.depender] = dep.ref;
    }

    var names = map.keys.toList();
    names.sort();

    for (var name in names) {
      buffer.writeln("- '$name' ");
      if (describe != null) {
        buffer.writeln(describe(map[name]));
      } else {
        buffer.writeln("depends on version ${map[name].constraint}");
      }
    }
  }

  String toString() {
    if (dependencies.isEmpty) return _message;

    var buffer = new StringBuffer();
    buffer.writeln("$_message:");

    var map = {};
    for (var dep in dependencies) {
      map[dep.depender] = dep.ref;
    }

    var names = map.keys.toList();
    names.sort();

    for (var name in names) {
      buffer.writeln("- '$name' ${_describeDependency(map[name])}");
    }

    return buffer.toString();
  }

  /// A message describing the specific kind of solve failure.
  String get _message;

  /// Describes a dependencie's reference in the output message. Override this
  /// to highlight which aspect of [ref] led to the failure.
  String _describeDependency(PackageRef ref) =>
      "depends on version ${ref.constraint}";
}

/// Exception thrown when the [VersionSolver] fails to find a solution after a
/// certain number of iterations.
class CouldNotSolveException extends SolveFailure {
  CouldNotSolveException()
      : super(null, null);

  /// A message describing the specific kind of solve failure.
  String get _message =>
      "Could not find a solution that met all constraints.";
}

/// Exception thrown when the [VersionConstraint] used to match a package is
/// valid (i.e. non-empty), but there are no available versions of the package
/// that fit that constraint.
class NoVersionException extends SolveFailure {
  final VersionConstraint constraint;

  NoVersionException(String package, this.constraint,
      Iterable<Dependency> dependencies)
      : super(package, dependencies);

  String get _message => "Package '$package' has no versions that match "
      "$constraint derived from";
}

// TODO(rnystrom): Report the list of depending packages and their constraints.
/// Exception thrown when the most recent version of [package] must be selected,
/// but doesn't match the [VersionConstraint] imposed on the package.
class CouldNotUpdateException extends SolveFailure {
  final VersionConstraint constraint;
  final Version best;

  CouldNotUpdateException(String package, this.constraint, this.best)
      : super(package, null);

  String get _message =>
      "The latest version of '$package', $best, does not match $constraint.";
}

/// Exception thrown when the [VersionConstraint] used to match a package is
/// the empty set: in other words, multiple packages depend on it and have
/// conflicting constraints that have no overlap.
class DisjointConstraintException extends SolveFailure {
  DisjointConstraintException(String package, Iterable<Dependency> dependencies)
      : super(package, dependencies);

  String get _message => "Incompatible version constraints on '$package'";
}

/// Exception thrown when two packages with the same name but different sources
/// are depended upon.
class SourceMismatchException extends SolveFailure {

  SourceMismatchException(String package, Iterable<Dependency> dependencies)
      : super(package, dependencies);

  String get _message => "Incompatible dependencies on '$package'";

  String _describeDependency(PackageRef ref) =>
      "depends on it from source ${ref.source}";
}

/// Exception thrown when two packages with the same name and source but
/// different descriptions are depended upon.
class DescriptionMismatchException extends SolveFailure {
  DescriptionMismatchException(String package,
      Iterable<Dependency> dependencies)
      : super(package, dependencies);

  String get _message => "Incompatible dependencies on '$package'";

  String _describeDependency(PackageRef ref) {
    // TODO(nweiz): Dump descriptions to YAML when that's supported.
    return "depends on it with description ${json.stringify(ref.description)}";
  }
}
