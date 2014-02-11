// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.solver.version_solver;

import 'dart:async';
import "dart:convert";

import '../lock_file.dart';
import '../log.dart' as log;
import '../package.dart';
import '../pubspec.dart';
import '../source_registry.dart';
import '../version.dart';
import '../utils.dart';
import 'backtracking_solver.dart';
import 'solve_report.dart' as solve_report;

/// Attempts to select the best concrete versions for all of the transitive
/// dependencies of [root] taking into account all of the [VersionConstraint]s
/// that those dependencies place on each other and the requirements imposed by
/// [lockFile].
///
/// If [useLatest] is given, then only the latest versions of the referenced
/// packages will be used. This is for forcing an upgrade to one or more
/// packages.
///
/// If [upgradeAll] is true, the contents of [lockFile] are ignored.
Future<SolveResult> resolveVersions(SourceRegistry sources, Package root,
    {LockFile lockFile, List<String> useLatest, bool upgradeAll: false}) {
  if (lockFile == null) lockFile = new LockFile.empty();
  if (useLatest == null) useLatest = [];

  return log.progress('Resolving dependencies', () {
    return new BacktrackingSolver(sources, root, lockFile, useLatest,
        upgradeAll: upgradeAll).solve();
  });
}

/// The result of a version resolution.
class SolveResult {
  /// Whether the solver found a complete solution or failed.
  bool get succeeded => error == null;

  /// The list of concrete package versions that were selected for each package
  /// reachable from the root, or `null` if the solver failed.
  final List<PackageId> packages;

  /// The dependency overrides that were used in the solution.
  final List<PackageDep> overrides;

  /// The available versions of all selected packages from their source.
  ///
  /// Will be empty if the solve failed. An entry here may not include the full
  /// list of versions available if the given package was locked and did not
  /// need to be unlocked during the solve.
  final Map<String, List<Version>> availableVersions;

  /// The error that prevented the solver from finding a solution or `null` if
  /// it was successful.
  final SolveFailure error;

  /// The number of solutions that were attempted before either finding a
  /// successful solution or exhausting all options. In other words, one more
  /// than the number of times it had to backtrack because it found an invalid
  /// solution.
  final int attemptedSolutions;

  final SourceRegistry _sources;
  final Package _root;
  final LockFile _previousLockFile;

  SolveResult.success(this._sources, this._root, this._previousLockFile,
      this.packages, this.overrides, this.availableVersions,
      this.attemptedSolutions)
      : error = null;

  SolveResult.failure(this._sources, this._root, this._previousLockFile,
      this.overrides, this.error, this.attemptedSolutions)
      : this.packages = null,
        this.availableVersions = {};

  /// Displays a report of what changes were made to the lockfile.
  ///
  /// If [showAll] is true, displays all new and previous dependencies.
  /// Otherwise, just shows a warning for any overrides in effect.
  ///
  /// Returns the number of changed (added, removed, or modified) dependencies.
  int showReport({bool showAll: false}) {
    return solve_report.show(_sources, _root, _previousLockFile, this,
        showAll: showAll);
  }

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

  /// The already-requested cached version lists.
  final _versions = new Map<PackageRef, List<PackageId>>();

  /// The already-requested cached pubspecs.
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

    var source = _sources[id.source];
    return source.describe(id).then((pubspec) {
      _pubspecs[id] = pubspec;
      return pubspec;
    });
  }

  /// Returns the previously cached pubspec for the package identified by [id]
  /// or returns `null` if not in the cache.
  Pubspec getCachedPubspec(PackageId id) => _pubspecs[id];

  /// Gets the list of versions for [package].
  ///
  /// Packages are sorted in descending version order with all "stable"
  /// versions (i.e. ones without a prerelease suffix) before pre-release
  /// versions. This ensures that the solver prefers stable packages over
  /// unstable ones.
  Future<List<PackageId>> getVersions(PackageRef package) {
    if (package.isRoot) {
      throw new StateError("Cannot get versions for root package $package.");
    }

    // See if we have it cached.
    var versions = _versions[package];
    if (versions != null) {
      versionCacheHits++;
      return new Future.value(versions);
    }

    versionCacheMisses++;

    var source = _sources[package.source];
    return source.getVersions(package.name, package.description)
        .then((versions) {
      // Sort by priority so we try preferred versions first.
      versions.sort(Version.prioritize);

      var ids = versions.reversed.map(
          (version) => package.atVersion(version)).toList();
      _versions[package] = ids;
      return ids;
    });
  }

  /// Returns the previously cached list of versions for the package identified
  /// by [package] or returns `null` if not in the cache.
  List<PackageId> getCachedVersions(PackageRef package) => _versions[package];
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
abstract class SolveFailure implements ApplicationException {
  /// The name of the package whose version could not be solved. Will be `null`
  /// if the failure is not specific to one package.
  final String package;

  /// The known dependencies on [package] at the time of the failure. Will be
  /// an empty collection if the failure is not specific to one package.
  final Iterable<Dependency> dependencies;

  final innerError = null;
  final innerTrace = null;

  String get message => toString();

  /// A message describing the specific kind of solve failure.
  String get _message {
    throw new UnimplementedError("Must override _message or toString().");
  }

  SolveFailure(this.package, Iterable<Dependency> dependencies)
      : dependencies = dependencies != null ? dependencies : <Dependency>[];

  String toString() {
    if (dependencies.isEmpty) return _message;

    var buffer = new StringBuffer();
    buffer.write("$_message:");

    var map = {};
    for (var dep in dependencies) {
      map[dep.depender] = dep.dep;
    }

    var names = ordered(map.keys);

    for (var name in names) {
      buffer.writeln();
      buffer.write("- $name ${_describeDependency(map[name])}");
    }

    return buffer.toString();
  }

  /// Describes a dependency's reference in the output message. Override this
  /// to highlight which aspect of [dep] led to the failure.
  String _describeDependency(PackageDep dep) =>
      "depends on version ${dep.constraint}";
}

/// Exception thrown when the current SDK's version does not match a package's
/// constraint on it.
class BadSdkVersionException extends SolveFailure {
  final String _message;

  BadSdkVersionException(String package, String message)
      : super(package, null),
        _message = message;
}

/// Exception thrown when the [VersionConstraint] used to match a package is
/// valid (i.e. non-empty), but there are no available versions of the package
/// that fit that constraint.
class NoVersionException extends SolveFailure {
  final VersionConstraint constraint;

  NoVersionException(String package, this.constraint,
      Iterable<Dependency> dependencies)
      : super(package, dependencies);

  String get _message => "Package $package has no versions that match "
      "$constraint derived from";
}

// TODO(rnystrom): Report the list of depending packages and their constraints.
/// Exception thrown when the most recent version of [package] must be selected,
/// but doesn't match the [VersionConstraint] imposed on the package.
class CouldNotUpgradeException extends SolveFailure {
  final VersionConstraint constraint;
  final Version best;

  CouldNotUpgradeException(String package, this.constraint, this.best)
      : super(package, null);

  String get _message =>
      "The latest version of $package, $best, does not match $constraint.";
}

/// Exception thrown when the [VersionConstraint] used to match a package is
/// the empty set: in other words, multiple packages depend on it and have
/// conflicting constraints that have no overlap.
class DisjointConstraintException extends SolveFailure {
  DisjointConstraintException(String package, Iterable<Dependency> dependencies)
      : super(package, dependencies);

  String get _message => "Incompatible version constraints on $package";
}

/// Exception thrown when two packages with the same name but different sources
/// are depended upon.
class SourceMismatchException extends SolveFailure {
  String get _message => "Incompatible dependencies on $package";

  SourceMismatchException(String package, Iterable<Dependency> dependencies)
      : super(package, dependencies);

  String _describeDependency(PackageDep dep) =>
      "depends on it from source ${dep.source}";
}

/// Exception thrown when a dependency on an unknown source name is found.
class UnknownSourceException extends SolveFailure {
  UnknownSourceException(String package, Iterable<Dependency> dependencies)
      : super(package, dependencies);

  String toString() {
    var dep = dependencies.single;
    return 'Package ${dep.depender} depends on ${dep.dep.name} from unknown '
           'source "${dep.dep.source}".';
  }
}

/// Exception thrown when two packages with the same name and source but
/// different descriptions are depended upon.
class DescriptionMismatchException extends SolveFailure {
  String get _message => "Incompatible dependencies on $package";

  DescriptionMismatchException(String package,
      Iterable<Dependency> dependencies)
      : super(package, dependencies);

  String _describeDependency(PackageDep dep) {
    // TODO(nweiz): Dump descriptions to YAML when that's supported.
    return "depends on it with description ${JSON.encode(dep.description)}";
  }
}

/// Exception thrown when a dependency could not be found in its source.
///
/// Unlike [PackageNotFoundException], this includes information about the
/// dependent packages requesting the missing one.
class DependencyNotFoundException extends SolveFailure {
  final PackageNotFoundException _innerException;
  String get _message => "${_innerException.message}\nDepended on by";

  DependencyNotFoundException(String package, this._innerException,
      Iterable<Dependency> dependencies)
      : super(package, dependencies);

  /// The failure isn't because of the version of description of the package,
  /// it's the package itself that can't be found, so just show the name and no
  /// descriptive details.
  String _describeDependency(PackageDep dep) => "";
}
