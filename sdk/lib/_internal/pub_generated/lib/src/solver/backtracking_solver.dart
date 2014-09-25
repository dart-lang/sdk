library pub.solver.backtracking_solver;
import 'dart:async';
import 'dart:collection' show Queue;
import '../barback.dart' as barback;
import '../exceptions.dart';
import '../lock_file.dart';
import '../log.dart' as log;
import '../package.dart';
import '../pubspec.dart';
import '../sdk.dart' as sdk;
import '../source_registry.dart';
import '../source/unknown.dart';
import '../utils.dart';
import '../version.dart';
import 'dependency_queue.dart';
import 'version_queue.dart';
import 'version_solver.dart';
class BacktrackingSolver {
  final SolveType type;
  final SourceRegistry sources;
  final Package root;
  final LockFile lockFile;
  final PubspecCache cache;
  final _forceLatest = new Set<String>();
  final _overrides = new Map<String, PackageDep>();
  final _selected = <VersionQueue>[];
  int get attemptedSolutions => _attemptedSolutions;
  var _attemptedSolutions = 1;
  BacktrackingSolver(SolveType type, SourceRegistry sources, this.root,
      this.lockFile, List<String> useLatest)
      : type = type,
        sources = sources,
        cache = new PubspecCache(type, sources) {
    for (var package in useLatest) {
      _forceLatest.add(package);
    }
    for (var override in root.dependencyOverrides) {
      _overrides[override.name] = override;
    }
  }
  Future<SolveResult> solve() {
    var stopwatch = new Stopwatch();
    _logParameters();
    var overrides = _overrides.values.toList();
    overrides.sort((a, b) => a.name.compareTo(b.name));
    return newFuture(() {
      stopwatch.start();
      cache.cache(new PackageId.root(root), root.pubspec);
      _validateSdkConstraint(root.pubspec);
      return _traverseSolution();
    }).then((packages) {
      var pubspecs = new Map.fromIterable(
          packages,
          key: (id) => id.name,
          value: (id) => cache.getCachedPubspec(id));
      return new SolveResult.success(
          sources,
          root,
          lockFile,
          packages,
          overrides,
          pubspecs,
          _getAvailableVersions(packages),
          attemptedSolutions);
    }).catchError((error) {
      if (error is! SolveFailure) throw error;
      return new SolveResult.failure(
          sources,
          root,
          lockFile,
          overrides,
          error,
          attemptedSolutions);
    }).whenComplete(() {
      var buffer = new StringBuffer();
      buffer.writeln('${runtimeType} took ${stopwatch.elapsed} seconds.');
      buffer.writeln(cache.describeResults());
      log.solver(buffer);
    });
  }
  Map<String, List<Version>> _getAvailableVersions(List<PackageId> packages) {
    var availableVersions = new Map<String, List<Version>>();
    for (var package in packages) {
      var cached = cache.getCachedVersions(package.toRef());
      var versions;
      if (cached != null) {
        versions = cached.map((id) => id.version).toList();
      } else {
        versions = [package.version];
      }
      availableVersions[package.name] = versions;
    }
    return availableVersions;
  }
  PackageId select(VersionQueue versions) {
    _selected.add(versions);
    logSolve();
    return versions.current;
  }
  PackageId getSelected(String name) {
    if (root.name == name) return new PackageId.root(root);
    for (var i = _selected.length - 1; i >= 0; i--) {
      if (_selected[i].current.name == name) return _selected[i].current;
    }
    return null;
  }
  PackageId getLocked(String package) {
    if (type == SolveType.GET) return lockFile.packages[package];
    if (type == SolveType.DOWNGRADE) {
      var locked = lockFile.packages[package];
      if (locked != null && !sources[locked.source].hasMultipleVersions) {
        return locked;
      }
    }
    if (_forceLatest.isEmpty || _forceLatest.contains(package)) return null;
    return lockFile.packages[package];
  }
  Future<List<PackageId>> _traverseSolution() => resetStack(() {
    return new Traverser(this).traverse().catchError((error) {
      if (error is! SolveFailure) throw error;
      return _backtrack(error).then((canTry) {
        if (canTry) {
          _attemptedSolutions++;
          return _traverseSolution();
        }
        throw error;
      });
    });
  });
  Future<bool> _backtrack(SolveFailure failure) {
    if (_selected.isEmpty) return new Future.value(false);
    var dependers = _getTransitiveDependers(failure.package);
    for (var selected in _selected) {
      if (dependers.contains(selected.current.name)) {
        selected.fail();
      }
    }
    advanceVersion() {
      _backjump(failure);
      var previous = _selected.last.current;
      return _selected.last.advance().then((success) {
        if (success) {
          logSolve();
          return true;
        }
        logSolve('$previous is last version, backtracking');
        _selected.removeLast();
        if (_selected.isEmpty) return false;
        return advanceVersion();
      });
    }
    return advanceVersion();
  }
  void _backjump(SolveFailure failure) {
    for (var i = _selected.length - 1; i >= 0; i--) {
      var selected = _selected[i].current;
      if (failure is DisjointConstraintException &&
          selected.name == failure.package) {
        logSolve("skipping past disjoint selected ${selected.name}");
        continue;
      }
      if (_selected[i].hasFailed) {
        logSolve('backjump to ${selected.name}');
        _selected.removeRange(i + 1, _selected.length);
        return;
      }
    }
    _selected.removeRange(1, _selected.length);
  }
  Set<String> _getTransitiveDependers(String dependency) {
    var dependers = new Map<String, Set<String>>();
    addDependencies(name, deps) {
      dependers.putIfAbsent(name, () => new Set<String>());
      for (var dep in deps) {
        dependers.putIfAbsent(dep.name, () => new Set<String>()).add(name);
      }
    }
    for (var i = 0; i < _selected.length; i++) {
      var id = _selected[i].current;
      var pubspec = cache.getCachedPubspec(id);
      if (pubspec != null) addDependencies(id.name, pubspec.dependencies);
    }
    addDependencies(root.name, root.immediateDependencies);
    var visited = new Set<String>();
    walk(String package) {
      if (visited.contains(package)) return;
      visited.add(package);
      var depender = dependers[package].forEach(walk);
    }
    walk(dependency);
    return visited;
  }
  void _logParameters() {
    var buffer = new StringBuffer();
    buffer.writeln("Solving dependencies:");
    for (var package in root.dependencies) {
      buffer.write("- $package");
      var locked = getLocked(package.name);
      if (_forceLatest.contains(package.name)) {
        buffer.write(" (use latest)");
      } else if (locked != null) {
        var version = locked.version;
        buffer.write(" (locked to $version)");
      }
      buffer.writeln();
    }
    log.solver(buffer.toString().trim());
  }
  void logSolve([String message]) {
    if (message == null) {
      if (_selected.isEmpty) {
        message = "* start at root";
      } else {
        message = "* select ${_selected.last.current}";
      }
    } else {
      message = prefixLines(message);
    }
    var prefix = _selected.skip(1).map((_) => '| ').join();
    log.solver(prefixLines(message, prefix: prefix));
  }
}
class Traverser {
  final BacktrackingSolver _solver;
  final _packages = new Queue<PackageId>();
  final _visited = new Set<PackageId>();
  final _dependencies = <String, List<Dependency>>{};
  Traverser(this._solver);
  Future<List<PackageId>> traverse() {
    _packages.add(new PackageId.root(_solver.root));
    return _traversePackage();
  }
  Future<List<PackageId>> _traversePackage() {
    if (_packages.isEmpty) {
      return new Future<List<PackageId>>.value(_visited.toList());
    }
    var id = _packages.removeFirst();
    if (_visited.contains(id)) {
      return _traversePackage();
    }
    _visited.add(id);
    return _solver.cache.getPubspec(id).then((pubspec) {
      _validateSdkConstraint(pubspec);
      var deps = pubspec.dependencies.toSet();
      if (id.isRoot) {
        deps.addAll(pubspec.devDependencies);
        deps.addAll(_solver._overrides.values);
      }
      deps = deps.map((dep) {
        var override = _solver._overrides[dep.name];
        if (override != null) return override;
        return dep;
      }).toSet();
      for (var dep in deps) {
        if (!dep.isRoot && _solver.sources[dep.source] is UnknownSource) {
          throw new UnknownSourceException(
              id.name,
              [new Dependency(id.name, id.version, dep)]);
        }
      }
      return _traverseDeps(id, new DependencyQueue(_solver, deps));
    }).catchError((error) {
      if (error is! PackageNotFoundException) throw error;
      throw new NoVersionException(id.name, null, id.version, []);
    });
  }
  Future<List<PackageId>> _traverseDeps(PackageId depender,
      DependencyQueue deps) {
    if (deps.isEmpty) return _traversePackage();
    return resetStack(() {
      return deps.advance().then((dep) {
        var dependency = new Dependency(depender.name, depender.version, dep);
        return _registerDependency(dependency).then((_) {
          if (dep.name == "barback") return _addImplicitDependencies();
        });
      }).then((_) => _traverseDeps(depender, deps));
    });
  }
  Future _registerDependency(Dependency dependency) {
    return new Future.sync(() {
      _validateDependency(dependency);
      var dep = dependency.dep;
      var dependencies = _getDependencies(dep.name);
      dependencies.add(dependency);
      var constraint = _getConstraint(dep.name);
      if (constraint.isEmpty) {
        var constraints = dependencies.map(
            (dep) => "  ${dep.dep.constraint} from ${dep.depender}").join('\n');
        _solver.logSolve('disjoint constraints on ${dep.name}:\n$constraints');
        throw new DisjointConstraintException(dep.name, dependencies);
      }
      var selected = _validateSelected(dep, constraint);
      if (selected != null) {
        _packages.add(selected);
        return null;
      }
      var locked = _getValidLocked(dep.name);
      return VersionQueue.create(locked, () {
        return _getAllowedVersions(dep);
      }).then((versions) => _packages.add(_solver.select(versions)));
    });
  }
  Future<Iterable<PackageId>> _getAllowedVersions(PackageDep dep) {
    var constraint = _getConstraint(dep.name);
    return _solver.cache.getVersions(dep.toRef()).then((versions) {
      var allowed = versions.where((id) => constraint.allows(id.version));
      if (allowed.isEmpty) {
        _solver.logSolve('no versions for ${dep.name} match $constraint');
        throw new NoVersionException(
            dep.name,
            null,
            constraint,
            _getDependencies(dep.name));
      }
      if (_solver._forceLatest.contains(dep.name)) allowed = [allowed.first];
      var locked = _getValidLocked(dep.name);
      if (locked != null) {
        allowed = allowed.where((dep) => dep.version != locked.version);
      }
      return allowed;
    }).catchError((error, stackTrace) {
      if (error is PackageNotFoundException) {
        throw new DependencyNotFoundException(
            dep.name,
            error,
            _getDependencies(dep.name));
      }
      throw error;
    });
  }
  void _validateDependency(Dependency dependency) {
    var dep = dependency.dep;
    var required = _getRequired(dep.name);
    if (required == null) return;
    if (required.dep.source != dep.source) {
      _solver.logSolve(
          'source mismatch on ${dep.name}: ${required.dep.source} ' '!= ${dep.source}');
      throw new SourceMismatchException(dep.name, [required, dependency]);
    }
    var source = _solver.sources[dep.source];
    if (!source.descriptionsEqual(dep.description, required.dep.description)) {
      _solver.logSolve(
          'description mismatch on ${dep.name}: '
              '${required.dep.description} != ${dep.description}');
      throw new DescriptionMismatchException(dep.name, [required, dependency]);
    }
  }
  PackageId _validateSelected(PackageDep dep, VersionConstraint constraint) {
    var selected = _solver.getSelected(dep.name);
    if (selected == null) return null;
    if (!dep.constraint.allows(selected.version)) {
      _solver.logSolve('selection $selected does not match $constraint');
      throw new NoVersionException(
          dep.name,
          selected.version,
          constraint,
          _getDependencies(dep.name));
    }
    return selected;
  }
  Future _addImplicitDependencies() {
    if (_getDependencies("barback").length != 1) return new Future.value();
    return Future.wait(barback.pubConstraints.keys.map((depName) {
      var constraint = barback.pubConstraints[depName];
      _solver.logSolve(
          'add implicit $constraint pub dependency on ' '$depName');
      var override = _solver._overrides[depName];
      var pubDep = override == null ?
          new PackageDep(depName, "hosted", constraint, depName) :
          override.withConstraint(constraint);
      return _registerDependency(
          new Dependency("pub itself", Version.none, pubDep));
    }));
  }
  List<Dependency> _getDependencies(String name) {
    return _dependencies.putIfAbsent(name, () => <Dependency>[]);
  }
  Dependency _getRequired(String name) {
    return _getDependencies(
        name).firstWhere((dep) => !dep.dep.isRoot, orElse: () => null);
  }
  VersionConstraint _getConstraint(String name) {
    var constraint = _getDependencies(
        name).map(
            (dep) =>
                dep.dep.constraint).fold(VersionConstraint.any, (a, b) => a.intersect(b));
    return constraint;
  }
  PackageId _getValidLocked(String name) {
    var package = _solver.getLocked(name);
    if (package == null) return null;
    var constraint = _getConstraint(name);
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
          package.description,
          required.dep.description)) return null;
    }
    return package;
  }
}
void _validateSdkConstraint(Pubspec pubspec) {
  if (pubspec.environment.sdkVersion.allows(sdk.version)) return;
  throw new BadSdkVersionException(
      pubspec.name,
      'Package ${pubspec.name} requires SDK version '
          '${pubspec.environment.sdkVersion} but the current SDK is ' '${sdk.version}.');
}
