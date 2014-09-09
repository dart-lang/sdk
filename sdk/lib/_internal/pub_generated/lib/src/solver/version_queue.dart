library pub.solver.version_queue;
import 'dart:async';
import 'dart:collection' show Queue;
import '../package.dart';
typedef Future<Iterable<PackageId>> PackageIdGenerator();
class VersionQueue {
  Queue<PackageId> _allowed;
  final PackageIdGenerator _allowedGenerator;
  PackageId _locked;
  PackageId get current {
    if (_locked != null) return _locked;
    return _allowed.first;
  }
  bool get hasFailed => _hasFailed;
  bool _hasFailed = false;
  static Future<VersionQueue> create(PackageId locked,
      PackageIdGenerator allowedGenerator) {
    var versions = new VersionQueue._(locked, allowedGenerator);
    if (locked != null) return new Future.value(versions);
    return versions._calculateAllowed().then((_) => versions);
  }
  VersionQueue._(this._locked, this._allowedGenerator);
  Future<bool> advance() {
    _hasFailed = false;
    if (_locked != null) {
      return _calculateAllowed().then((_) {
        _locked = null;
        return _allowed.isNotEmpty;
      });
    }
    _allowed.removeFirst();
    return new Future.value(_allowed.isNotEmpty);
  }
  void fail() {
    _hasFailed = true;
  }
  Future _calculateAllowed() {
    return _allowedGenerator().then((allowed) {
      _allowed = new Queue<PackageId>.from(allowed);
    });
  }
}
