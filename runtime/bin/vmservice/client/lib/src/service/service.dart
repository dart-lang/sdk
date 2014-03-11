// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of service;

/// A [ServiceObject] is an object known to the VM service and is tied
/// to an owning [Isolate].
abstract class ServiceObject extends Observable {
  Isolate _isolate;

  /// Owning isolate.
  @reflectable Isolate get isolate => _isolate;

  /// Owning vm.
  @reflectable VM get vm => _isolate.vm;

  /// The complete service url of this object.
  @reflectable String get link => isolate.relativeLink(_id);

  /// The complete service url of this object with a '#/' prefix.
  @reflectable String get hashLink => isolate.relativeHashLink(_id);

  String _id;
  /// The id of this object.
  @reflectable String get id => _id;

  String _serviceType;
  /// The service type of this object.
  @reflectable String get serviceType => _serviceType;

  bool _ref;

  @observable String name;
  @observable String vmName;

  ServiceObject(this._isolate, this._id, this._serviceType) {
    _ref = isRefType(_serviceType);
    _serviceType = stripRef(_serviceType);
    _created();
  }

  ServiceObject.fromMap(this._isolate, ObservableMap m) {
    assert(isServiceMap(m));
    _id = m['id'];
    _ref = isRefType(m['type']);
    _serviceType = stripRef(m['type']);
    _created();
    update(m);
  }

  /// If [this] was created from a reference, load the full object
  /// from the service by calling [reload]. Else, return [this].
  Future<ServiceObject> load() {
    if (!_ref) {
      // Not a reference.
      return new Future.value(this);
    }
    // Call refresh which will fill in the entire object.
    return reload();
  }

  /// Reload [this]. Returns a future which completes to [this] or
  /// a [ServiceError].
  Future<ServiceObject> reload() {
    assert(isolate != null);
    if (id == '') {
      // Errors don't have ids.
      assert(serviceType == 'Error');
      return new Future.value(this);
    }
    return isolate.vm.getAsMap(link).then(update);
  }

  /// Update [this] using [m] as a source. [m] can be a reference.
  ServiceObject update(ObservableMap m) {
    // Assert that m is a service map.
    assert(ServiceObject.isServiceMap(m));
    if ((m['type'] == 'Error') && (_serviceType != 'Error')) {
      // Got an unexpected error. Don't update the object.
      return _upgradeToServiceObject(vm, isolate, m);
    }
    // TODO(johnmccutchan): Should we allow for a ServiceObject's id
    // or type to change?
    _id = m['id'];
    _serviceType = stripRef(m['type']);
    _update(m);
    return this;
  }

  // update internal state from [map]. [map] can be a reference.
  void _update(ObservableMap map);

  /// Returns true if [this] has only been partially initialized via
  /// a reference. See [load].
  bool isRef() => _ref;

  void _created() {
    var refNotice = _ref ? ' Created from reference.' : '';
    Logger.root.info('Created ServiceObject for \'${_id}\' with type '
                     '\'${_serviceType}\'.' + refNotice);
  }

  /// Returns true if [map] is a service map. i.e. it has the following keys:
  /// 'id' and a 'type'.
  static bool isServiceMap(ObservableMap m) {
    return (m != null) && (m['id'] != null) && (m['type'] != null);
  }

  /// Returns true if [type] is a reference type. i.e. it begins with an
  /// '@' character.
  static bool isRefType(String type) {
    return type.startsWith('@');
  }

  /// Returns the unreffed version of [type].
  static String stripRef(String type) {
    if (!isRefType(type)) {
      return type;
    }
    // Strip off the '@' character.
    return type.substring(1);
  }
}

/// Recursively upgrades all [ServiceObject]s inside [collection] which must
/// be an [ObservableMap] or an [ObservableList]. Upgraded elements will be
/// associated with [vm] and [isolate].
void upgradeCollection(collection, VM vm, Isolate isolate) {
  if (collection is ObservableMap) {
    _upgradeObservableMap(collection, vm, isolate);
  } else if (collection is ObservableList) {
    _upgradeObservableList(collection, vm, isolate);
  }
}

void _upgradeObservableMap(ObservableMap map, VM vm, Isolate isolate) {
  map.forEach((k, v) {
    if ((v is ObservableMap) && ServiceObject.isServiceMap(v)) {
      map[k] = v = _upgradeToServiceObject(vm, isolate, v);
    } else if (v is ObservableList) {
      _upgradeObservableList(v, vm, isolate);
    } else if (v is ObservableMap) {
      _upgradeObservableMap(v, vm, isolate);
    }
  });
}

void _upgradeObservableList(ObservableList list, VM vm, Isolate isolate) {
  for (var i = 0; i < list.length; i++) {
    var v = list[i];
    if ((v is ObservableMap) && ServiceObject.isServiceMap(v)) {
      list[i] = _upgradeToServiceObject(vm, isolate, v);
    } else if (v is ObservableList) {
      _upgradeObservableList(v, vm, isolate);
    } else if (v is ObservableMap) {
      _upgradeObservableMap(v, vm, isolate);
    }
  }
}

/// Upgrades response ([m]) from [vm] and [isolate] to a [ServiceObject].
/// This acts like a factory which consumes an ObservableMap and returns
/// a fully upgraded ServiceObject.
ServiceObject _upgradeToServiceObject(VM vm, Isolate isolate, ObservableMap m) {
  assert(ServiceObject.isServiceMap(m));
  var type = ServiceObject.stripRef(m['type']);
  switch (type) {
    case 'Error':
      return new ServiceError.fromMap(isolate, m);
    case 'IsolateList':
      vm.isolates.update(m);
      return vm.isolates;
    case 'Script':
      return isolate.scripts.putIfAbsent(m);
    case 'Code':
      return isolate.codes.putIfAbsent(m);
    case 'Isolate':
      return vm.isolates.getIsolateFromMap(m);
    case 'Class':
      return isolate.classes.putIfAbsent(m);
  }
  return new ServiceMap.fromMap(isolate, m);
}