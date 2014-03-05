// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// A [ServiceObject] is an object known to the VM service and is tied
/// to an owning [Isolate].
abstract class ServiceObject extends Observable {
  /// Owning isolate.
  final Isolate isolate;
  /// The complete service url of this object.
  String get link => isolate.relativeLink(_id);
  String _id;
  /// The id of this object.
  String get id => _id;
  String _serviceType;
  /// The service type of this object.
  String get serviceType => _serviceType;

  /// Refresh [this]. Returns a future which completes to [this].
  Future refresh();

  ServiceObject(this.isolate, this._id, this._serviceType);
}


/// A [ServiceObject] which implements [Map].
class ServiceMap extends ServiceObject implements Map {
  final Map _map = new ObservableMap();

  ServiceMap(Isolate isolate, String id, String serviceType) :
      super(isolate, id, serviceType) {
  }

  ServiceMap.fromMap(Isolate isolate, Map m) :
      super(isolate, m['id'], m['type']) {
    _fill(m);
  }

  Future refresh() {
    isolate.getMap(_id).then(_fill);
    return new Future.value(this);
  }

  void _fill(Map m) {
    _map.clear();
    _map.addAll(m);
    // TODO(johnmccutchan): Recursively promote all contained Maps to
    // ServiceMaps if they have a 'type' key.
  }

  // Implement Map by forwarding methods to _map.
  void addAll(Map other) => _map.addAll(other);
  void clear() => _map.clear();
  bool containsValue(v) => _map.containsValue(v);
  bool containsKey(k) => _map.containsKey(k);
  void forEach(Function f) => _map.forEach(f);
  putIfAbsent(key, Function ifAbsent) => _map.putIfAbsent(key, ifAbsent);
  void remove(key) => _map.remove(key);
  operator [](k) => _map[k];
  operator []=(k, v) => _map[k] = v;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
  Iterable get keys => _map.keys;
  Iterable get values => _map.values;
  int get length => _map.length;
}
