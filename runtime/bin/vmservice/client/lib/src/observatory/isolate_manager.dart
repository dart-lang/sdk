// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observatory;

/// Collection of isolates which are running in the VM. Updated
class IsolateManager extends Observable {
  ObservatoryApplication _application;
  ObservatoryApplication get application => _application;

  @observable final Map<String, Isolate> isolates =
      toObservable(new Map<String, Isolate>());

  static bool _foundIsolateInMembers(String id, List<Map> members) {
    return members.any((E) => E['id'] == id);
  }

  void _responseInterceptor() {
    _application.requestManager.responses.forEach((response) {
      if (response['type'] == 'IsolateList') {
        _updateIsolates(response['members']);
      }
    });
  }

  Isolate getIsolate(String id) {
    Isolate isolate = isolates[id];
    if (isolate == null) {
      isolate = new Isolate.fromId(id);
      isolates[id] = isolate;
    }
    if (isolate.vmName == null) {
      // First time we are using this isolate.
      isolate.refresh();
    }
    return isolate;
  }

  void _updateIsolates(List<Map> members) {
    // Find dead isolates.
    var deadIsolates = [];
    isolates.forEach((k, v) {
      if (!_foundIsolateInMembers(k, members)) {
        deadIsolates.add(k);
      }
    });
    // Remove them.
    deadIsolates.forEach((id) {
      isolates.remove(id);
    });
    // Add new isolates.
    members.forEach((map) {
      var id = map['id'];
      var isolate = isolates[id];
      if (isolate == null) {
        isolate = new Isolate.fromMap(map);
        isolates[id] = isolate;
      }
      isolate.refresh();
    });
  }
}
