// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.solver.version_solver;

import 'dart:async';
import "dart:convert";

import 'package:stack_trace/stack_trace.dart';

import '../exceptions.dart';
import '../lock_file.dart';
import '../log.dart' as log;
import '../package.dart';
import '../pubspec.dart';
import '../source_registry.dart';
import '../version.dart';
import '../utils.dart';
import 'backtracking_solver.dart';
import 'solve_report.dart';

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
Future<SolveResult> resolveVersions(SolveType type, SourceRegistry sources,
    Package root, {LockFile lockFile, List<String> useLatest}) {
  if (lockFile == null) lockFile = new LockFile.empty();
  if (useLatest == null) useLatest = [];

  return log.progress('Resolving dependencies', () {
    return new BacktrackingSolver(type, sources, root, lockFile, useLatest)
        .solve();
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

  /// A map from package names to the pubspecs for the versions of those
  /// packages that were installed, or `null` if the solver failed.
  final Map<String, Pubspec> pubspecs;

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
  /// successful solution or exhausting all options.
  ///
  /// In other words, one more than the number of times it had to backtrack
  /// because it found an invalid solution.
  final int attemptedSolutions;

  final SourceRegistry _sources;
  final Package _root;
  final LockFile _previousLockFile;

  SolveResult.success(this._sources, this._root, this._previousLockFile,
      this.packages, this.overrides, this.pubspecs, this.availableVersions,
      this.attemptedSolutions)
      : error = null;

  SolveResult.failure(this._sources, this._root, this._previousLockFile,
      this.overrides, this.error, this.attemptedSolutions)
      : this.packages = null,
        this.pubspecs = null,
        this.availableVersions = {};

  /// Displays a report of what changes were made to the lockfile.
  ///
  /// [type] is the type of version resolution that was run.
  void showReport(SolveType type) {
    new SolveReport(type, _sources, _root, _previousLockFile, this).show();
  }

  /// Displays a one-line message summarizing what changes were made (or would
  /// be made) to the lockfile.
  ///
  /// [type] is the type of version resolution that was run.
  void summarizeChanges(SolveType type, {bool dryRun: false}) {
    new SolveReport(type, _sources, _root, _previousLockFile, this)
        .summarize(dryRun: dryRun);
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
///
/// Used to avoid requesting the same pubspec from the server repeatedly.
class PubspecCache {
  final SourceRegistry _sources;

  /// The already-requested cached version lists.
  final _versions = new Map<PackageRef, List<PackageId>>();

  /// The errors from failed version list requests.
  final _versionErrors = new Map<PackageRef, Pair<Object, Chain>>();

  /// The already-requested cached pubspecs.
  final _pubspecs = new Map<PackageId, Pubspec>();

  /// The type of version resolution that was run.
  final SolveType _type;

  /// The number of times a version list was requested and it wasn't cached and
  /// had to be requested from the source.
  int _versionCacheMisses = 0;

  /// The number of times a version list was requested and the cached version
  /// was returned.
  int _versionCacheHits = 0;

  /// The number of times a pubspec was requested and it wasn't cached and had
  /// to be requested from the source.
  int _pubspecCacheMisses = 0;

  /// The number of times a pubspec was requested and the cached version was
  /// returned.
  int _pubspecCacheHits = 0;

  PubspecCache(this._type, this._sources);

  /// Caches [pubspec] as the [Pubspec] for the package identified by [id].
  void cache(PackageId id, Pubspec pubspec) {
    _pubspecs[id] = pubspec;
  }

  /// Loads the pubspec for the package identified by [id].
  Future<Pubspec> getPubspec(PackageId id) {
    // Complete immediately if it's already cached.
    if (_pubspecs.containsKey(id)) {
      _pubspecCacheHits++;
      return new Future<Pubspec>.value(_pubspecs[id]);
    }

    _pubspecCacheMisses++;

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
      _versionCacheHits++;
      return new Future.value(versions);
    }

    // See if we cached a failure.
    var error = _versionErrors[package];
    if (error != null) {
      _versionCacheHits++;
      return new Future.error(error.first, error.last);
    }

    _versionCacheMisses++;

    var source = _sources[package.source];
    return source.getVersions(package.name, package.description)
        .then((versions) {
      // Sort by priority so we try preferred versions first.
      versions.sort(_type == SolveType.DOWNGRADE ? Version.antiPrioritize :
          Version.prioritize);

      var ids = versions.reversed.map(
          (version) => package.atVersion(version)).toList();
      _versions[package] = ids;
      return ids;
    }).catchError((error, trace) {
      // If an error occurs, cache that too. We only want to do one request
      // for any given package, successful or not.
      log.solver("Could not get versions for $package:\n$error\n\n$trace");
      _versionErrors[package] = new Pair(error, new Chain.forTrace(trace));
      throw error;
    });
  }

  /// Returns the previously cached list of versions for the package identified
  /// by [package] or returns `null` if not in the cache.
  List<PackageId> getCachedVersions(PackageRef package) => _versions[package];

  /// Returns a user-friendly output string describing metrics of the solve.
  String describeResults() {
    var results = '''- Requested $_versionCacheMisses version lists
- Looked up $_versionCacheHits cached version lists
- Requested $_pubspecCacheMisses pubspecs
- Looked up $_pubspecCacheHits cached pubspecs
''';

    // Uncomment this to dump the visited package graph to JSON.
    //results += _debugWritePackageGraph();

    return results;
  }

  /// This dumps the set of packages that were looked at by the solver to a
  /// JSON map whose format matches the map passed to [testResolve] in the
  /// version solver unit tests.
  ///
  /// If a real-world version solve is failing, this can be used to mirror that
  /// data to build a regression test using mock packages.
  String _debugDescribePackageGraph() {
    var packages = {};
    _pubspecs.forEach((id, pubspec) {
      var deps = {};
      packages["${id.name} ${id.version}"] = deps;

      for (var dep in pubspec.dependencies) {
        deps[dep.name] = dep.constraint.toString();
      }
    });

    // Add in the packages that we know of but didn't need their pubspecs.
    _versions.forEach((ref, versions) {
      for (var id in versions) {
        packages.putIfAbsent("${id.name} ${id.version}", () => {});
      }
    });

    // TODO(rnystrom): Include dev dependencies and dependency overrides.

    return JSON.encode(packages);
  }
}

/// A reference from a depending package to a package that it depends on.
class Dependency {
  /// The name of the package that has this dependency.
  final String depender;

  /// The version of the depender that has this dependency.
  ///
  /// This will be `null` when [depender] is the magic "pub itself" dependency.
  final Version dependerVersion;

  /// The package being depended on.
  final PackageDep dep;

  Dependency(this.depender, this.dependerVersion, this.dep);

  String toString() => '$depender $dependerVersion -> $dep';
}

/// An enum for types of version resolution.
class SolveType {
  /// As few changes to the lockfile as possible to be consistent with the
  /// pubspec.
  static const GET = const SolveType._("get");

  /// Upgrade all packages or specific packages to the highest versions
  /// possible, regardless of the lockfile.
  static const UPGRADE = const SolveType._("upgrade");

  /// Downgrade all packages or specific packages to the lowest versions
  /// possible, regardless of the lockfile.
  static const DOWNGRADE = const SolveType._("downgrade");

  final String _name;

  const SolveType._(this._name);

  String toString() => _name;
}

/// Base class for all failures that can occur while trying to resolve versions.
abstract class SolveFailure implements ApplicationException {
  /// The name of the package whose version could not be solved.
  ///
  /// Will be `null` if the failure is not specific to one package.
  final String package;

  /// The known dependencies on [package] at the time of the failure.
  ///
  /// Will be an empty collection if the failure is not specific to one package.
  final Iterable<Dependency> dependencies;

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

    var sorted = dependencies.toList();
    sorted.sort((a, b) => a.depender.compareTo(b.depender));

    for (var dep in sorted) {
      buffer.writeln();
      buffer.write("- ${log.bold(dep.depender)}");
      if (dep.dependerVersion != null) {
        buffer.write(" ${dep.dependerVersion}");
      }
      buffer.write(" ${_describeDependency(dep.dep)}");
    }

    return buffer.toString();
  }

  /// Describes a dependency's reference in the output message.
  ///
  /// Override this to highlight which aspect of [dep] led to the failure.
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

  /// The last selected version of the package that failed to meet the new
  /// constraint.
  ///
  /// This will be `null` when the failure occurred because there are no
  /// versions of the package *at all* that match the constraint. It will be
  /// non-`null` when a version was selected, but then the solver tightened a
  /// constraint such that that version was no longer allowed.
  final Version version;

  NoVersionException(String package, this.version, this.constraint,
      Iterable<Dependency> dependencies)
      : super(package, dependencies);

  String get _message {
    if (version == null) {
      return "Package $package has no versions that match $constraint derived "
          "from";
    }

    return "Package $package $version does not match $constraint derived from";
  }
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
