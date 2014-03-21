// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of service;

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
  if (m == null) {
    return null;
  }
  if (!ServiceObject.isServiceMap(m)) {
    Logger.root.severe("Malformed service object: $m");
  }
  assert(ServiceObject.isServiceMap(m));
  var type = ServiceObject.stripRef(m['type']);
  switch (type) {
    case 'Error':
      if (isolate != null) {
        return new ServiceError.fromMap(isolate, m);
      } else {
        return new ServiceError.fromMap(vm, m);
      }
      break;
    case 'Script':
      return isolate.scripts.putIfAbsent(m);
    case 'Code':
      return isolate.codes.putIfAbsent(m);
    case 'Isolate':
      return vm.isolates.getIsolateFromMap(m);
    case 'Class':
      return isolate.classes.putIfAbsent(m);
    case 'Function':
      return isolate.functions.putIfAbsent(m);
    case 'VM':
      return vm.update(m);
  }
  return new ServiceMap.fromMap(isolate, m);
}
