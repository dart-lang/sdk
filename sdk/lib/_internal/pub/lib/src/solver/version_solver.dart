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

/// Attempts to select the best concrete versions for all of the transitive
/// dependencies of [root] taking into account all of the [VersionConstraint]s
/// that those dependencies place on each other and the requirements imposed by
/// [lockFile].
///
/// If [useLatest] is given, then only the latest versions of the referenced
/// packages will be used. This is for forcing an update to one or more
/// packages.
Future<SolveResult> resolveVersions(SourceRegistry sources, Package root,
    {LockFile lockFile, List<String> useLatest}) {
  log.message('Resolving dependencies...');

  if (lockFile == null) lockFile = new LockFile.empty();
  if (useLatest == null) useLatest = [];

  return new BacktrackingSolver(sources, root, lockFile, useLatest).solve();
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
  final _versions = new Map<PackageRef, List<PackageId>>();
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
  Future<List<PackageId>> getVersions(PackageRef package) {
    // See if we have it cached.
    var versions = _versions[package];
    if (versions != null) {
      versionCacheHits++;
      return new Future.value(versions);
    }

    versionCacheMisses++;
    return package.getVersions().then((ids) {
      // Sort by descending version so we try newer versions first.
      ids.sort((a, b) => b.version.compareTo(a.version));

      log.solver('requested $package version list');
      _versions[package] = ids;
      return ids;
    });
  }
}

/// A reference from a depending package to a package that it depends on.
class Dependency {
  /// The name of the package that has this dependency.
  final String depender;

  /// The package being depended on.
  final PackageDep dep;

  Dependency(this.depender, this.dep);

  String toString() => '$depender -> $dep';
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
      [String describe(PackageDep dep)]) {
    var map = {};
    for (var dep in dependencies) {
      map[dep.depender] = dep.dep;
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
      map[dep.depender] = dep.dep;
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
  /// to highlight which aspect of [dep] led to the failure.
  String _describeDependency(PackageDep dep) =>
      "depends on version ${dep.constraint}";
}

/// Exception thrown when the [VersionSolver] fails to find a solution after a
/// certain number of iterations.
class CouldNotSolveException extends SolveFailure {
  CouldNotSolveException([String message])
      : super(null, null),
        _message = (message != null) ? message :
            "Could not find a solution that met all constraints.";

  /// A message describing the specific kind of solve failure.
  final String _message;
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

  String _describeDependency(PackageDep dep) =>
      "depends on it from source ${dep.source}";
}

/// Exception thrown when two packages with the same name and source but
/// different descriptions are depended upon.
class DescriptionMismatchException extends SolveFailure {
  DescriptionMismatchException(String package,
      Iterable<Dependency> dependencies)
      : super(package, dependencies);

  String get _message => "Incompatible dependencies on '$package'";

  String _describeDependency(PackageDep dep) {
    // TODO(nweiz): Dump descriptions to YAML when that's supported.
    return "depends on it with description ${json.stringify(dep.description)}";
  }
}
