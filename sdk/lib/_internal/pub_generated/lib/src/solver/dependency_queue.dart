library pub.solver.dependency_queue;
import 'dart:async';
import 'dart:collection' show Queue;
import '../log.dart' as log;
import '../package.dart';
import 'backtracking_solver.dart';
class DependencyQueue {
  final BacktrackingSolver _solver;
  final Queue<PackageDep> _presorted;
  final List<PackageDep> _remaining;
  bool _isSorted = false;
  bool get isEmpty => _presorted.isEmpty && _remaining.isEmpty;
  Future _sortFuture;
  factory DependencyQueue(BacktrackingSolver solver, Iterable<PackageDep> deps)
      {
    var presorted = <PackageDep>[];
    var remaining = <PackageDep>[];
    for (var dep in deps) {
      if (solver.getSelected(dep.name) != null ||
          solver.getLocked(dep.name) != null) {
        presorted.add(dep);
      } else {
        remaining.add(dep);
      }
    }
    presorted.sort((a, b) => a.name.compareTo(b.name));
    return new DependencyQueue._(
        solver,
        new Queue<PackageDep>.from(presorted),
        remaining);
  }
  DependencyQueue._(this._solver, this._presorted, this._remaining);
  Future<PackageDep> advance() {
    if (_presorted.isNotEmpty) {
      return new Future.value(_presorted.removeFirst());
    }
    if (!_isSorted) return _sort().then((_) => _remaining.removeAt(0));
    return new Future.value(_remaining.removeAt(0));
  }
  Future _sort() {
    assert(_sortFuture == null);
    _sortFuture = Future.wait(_remaining.map(_getNumVersions)).then((versions) {
      _sortFuture = null;
      var versionMap = new Map.fromIterables(_remaining, versions);
      _remaining.sort((a, b) {
        if (versionMap[a] != versionMap[b]) {
          return versionMap[a].compareTo(versionMap[b]);
        }
        return a.name.compareTo(b.name);
      });
      _isSorted = true;
    });
    return _sortFuture;
  }
  Future<int> _getNumVersions(PackageDep dep) {
    if (dep.isRoot) {
      return new Future.value(1);
    }
    return _solver.cache.getVersions(dep.toRef()).then((versions) {
      for (var rootDep in _solver.root.immediateDependencies) {
        if (rootDep.name == dep.name) {
          versions =
              versions.where((id) => rootDep.constraint.allows(id.version));
          break;
        }
      }
      return versions.length;
    }).catchError((error, trace) {
      log.solver("Could not get versions for $dep:\n$error\n\n$trace");
      return 0;
    });
  }
}
