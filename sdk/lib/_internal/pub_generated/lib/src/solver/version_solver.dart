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
Future<SolveResult> resolveVersions(SolveType type, SourceRegistry sources,
    Package root, {LockFile lockFile, List<String> useLatest}) {
  if (lockFile == null) lockFile = new LockFile.empty();
  if (useLatest == null) useLatest = [];
  return log.progress('Resolving dependencies', () {
    return new BacktrackingSolver(
        type,
        sources,
        root,
        lockFile,
        useLatest).solve();
  });
}
class SolveResult {
  bool get succeeded => error == null;
  final List<PackageId> packages;
  final List<PackageDep> overrides;
  final Map<String, Pubspec> pubspecs;
  final Map<String, List<Version>> availableVersions;
  final SolveFailure error;
  final int attemptedSolutions;
  final SourceRegistry _sources;
  final Package _root;
  final LockFile _previousLockFile;
  Set<String> get changedPackages {
    if (packages == null) return null;
    var changed = packages.where(
        (id) =>
            !_sources.idsEqual(
                _previousLockFile.packages[id.name],
                id)).map((id) => id.name).toSet();
    return changed.union(
        _previousLockFile.packages.keys.where(
            (package) => !availableVersions.containsKey(package)).toSet());
  }
  SolveResult.success(this._sources, this._root, this._previousLockFile,
      this.packages, this.overrides, this.pubspecs, this.availableVersions,
      this.attemptedSolutions)
      : error = null;
  SolveResult.failure(this._sources, this._root, this._previousLockFile,
      this.overrides, this.error, this.attemptedSolutions)
      : this.packages = null,
        this.pubspecs = null,
        this.availableVersions = {};
  void showReport(SolveType type) {
    new SolveReport(type, _sources, _root, _previousLockFile, this).show();
  }
  void summarizeChanges(SolveType type, {bool dryRun: false}) {
    new SolveReport(
        type,
        _sources,
        _root,
        _previousLockFile,
        this).summarize(dryRun: dryRun);
  }
  String toString() {
    if (!succeeded) {
      return 'Failed to solve after $attemptedSolutions attempts:\n' '$error';
    }
    return 'Took $attemptedSolutions tries to resolve to\n'
        '- ${packages.join("\n- ")}';
  }
}
class PubspecCache {
  final SourceRegistry _sources;
  final _versions = new Map<PackageRef, List<PackageId>>();
  final _versionErrors = new Map<PackageRef, Pair<Object, Chain>>();
  final _pubspecs = new Map<PackageId, Pubspec>();
  final SolveType _type;
  int _versionCacheMisses = 0;
  int _versionCacheHits = 0;
  int _pubspecCacheMisses = 0;
  int _pubspecCacheHits = 0;
  PubspecCache(this._type, this._sources);
  void cache(PackageId id, Pubspec pubspec) {
    _pubspecs[id] = pubspec;
  }
  Future<Pubspec> getPubspec(PackageId id) {
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
  Pubspec getCachedPubspec(PackageId id) => _pubspecs[id];
  Future<List<PackageId>> getVersions(PackageRef package) {
    if (package.isRoot) {
      throw new StateError("Cannot get versions for root package $package.");
    }
    var versions = _versions[package];
    if (versions != null) {
      _versionCacheHits++;
      return new Future.value(versions);
    }
    var error = _versionErrors[package];
    if (error != null) {
      _versionCacheHits++;
      return new Future.error(error.first, error.last);
    }
    _versionCacheMisses++;
    var source = _sources[package.source];
    return source.getVersions(
        package.name,
        package.description).then((versions) {
      versions.sort(
          _type == SolveType.DOWNGRADE ? Version.antiPrioritize : Version.prioritize);
      var ids =
          versions.reversed.map((version) => package.atVersion(version)).toList();
      _versions[package] = ids;
      return ids;
    }).catchError((error, trace) {
      log.solver("Could not get versions for $package:\n$error\n\n$trace");
      _versionErrors[package] = new Pair(error, new Chain.forTrace(trace));
      throw error;
    });
  }
  List<PackageId> getCachedVersions(PackageRef package) => _versions[package];
  String describeResults() {
    var results = '''- Requested $_versionCacheMisses version lists
- Looked up $_versionCacheHits cached version lists
- Requested $_pubspecCacheMisses pubspecs
- Looked up $_pubspecCacheHits cached pubspecs
''';
    return results;
  }
  String _debugDescribePackageGraph() {
    var packages = {};
    _pubspecs.forEach((id, pubspec) {
      var deps = {};
      packages["${id.name} ${id.version}"] = deps;
      for (var dep in pubspec.dependencies) {
        deps[dep.name] = dep.constraint.toString();
      }
    });
    _versions.forEach((ref, versions) {
      for (var id in versions) {
        packages.putIfAbsent("${id.name} ${id.version}", () => {});
      }
    });
    return JSON.encode(packages);
  }
}
class Dependency {
  final String depender;
  final Version dependerVersion;
  final PackageDep dep;
  bool get isMagic => depender.contains(" ");
  Dependency(this.depender, this.dependerVersion, this.dep);
  String toString() => '$depender $dependerVersion -> $dep';
}
class SolveType {
  static const GET = const SolveType._("get");
  static const UPGRADE = const SolveType._("upgrade");
  static const DOWNGRADE = const SolveType._("downgrade");
  final String _name;
  const SolveType._(this._name);
  String toString() => _name;
}
abstract class SolveFailure implements ApplicationException {
  final String package;
  final Iterable<Dependency> dependencies;
  String get message => toString();
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
      if (!dep.isMagic) buffer.write(" ${dep.dependerVersion}");
      buffer.write(" ${_describeDependency(dep.dep)}");
    }
    return buffer.toString();
  }
  String _describeDependency(PackageDep dep) =>
      "depends on version ${dep.constraint}";
}
class BadSdkVersionException extends SolveFailure {
  final String _message;
  BadSdkVersionException(String package, String message)
      : super(package, null),
        _message = message;
}
class NoVersionException extends SolveFailure {
  final VersionConstraint constraint;
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
class CouldNotUpgradeException extends SolveFailure {
  final VersionConstraint constraint;
  final Version best;
  CouldNotUpgradeException(String package, this.constraint, this.best)
      : super(package, null);
  String get _message =>
      "The latest version of $package, $best, does not match $constraint.";
}
class DisjointConstraintException extends SolveFailure {
  DisjointConstraintException(String package, Iterable<Dependency> dependencies)
      : super(package, dependencies);
  String get _message => "Incompatible version constraints on $package";
}
class SourceMismatchException extends SolveFailure {
  String get _message => "Incompatible dependencies on $package";
  SourceMismatchException(String package, Iterable<Dependency> dependencies)
      : super(package, dependencies);
  String _describeDependency(PackageDep dep) =>
      "depends on it from source ${dep.source}";
}
class UnknownSourceException extends SolveFailure {
  UnknownSourceException(String package, Iterable<Dependency> dependencies)
      : super(package, dependencies);
  String toString() {
    var dep = dependencies.single;
    return 'Package ${dep.depender} depends on ${dep.dep.name} from unknown '
        'source "${dep.dep.source}".';
  }
}
class DescriptionMismatchException extends SolveFailure {
  String get _message => "Incompatible dependencies on $package";
  DescriptionMismatchException(String package,
      Iterable<Dependency> dependencies)
      : super(package, dependencies);
  String _describeDependency(PackageDep dep) {
    return "depends on it with description ${JSON.encode(dep.description)}";
  }
}
class DependencyNotFoundException extends SolveFailure {
  final PackageNotFoundException _innerException;
  String get _message => "${_innerException.message}\nDepended on by";
  DependencyNotFoundException(String package, this._innerException,
      Iterable<Dependency> dependencies)
      : super(package, dependencies);
  String _describeDependency(PackageDep dep) => "";
}
