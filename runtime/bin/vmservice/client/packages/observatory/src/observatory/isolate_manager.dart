// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observatory;

/// Collection of isolates which are running in the VM. Updated
class IsolateManager extends ObservableMixin {
  ObservatoryApplication _application;
  ObservatoryApplication get application => _application;

  @observable final Map<int, Isolate> isolates =
      toObservable(new Map<int, Isolate>());

  static bool _foundIsolateInMembers(int id, List<Map> members) {
    return members.any((E) => E['id'] == id);
  }

  void _responseInterceptor() {
    _application.requestManager.responses.forEach((response) {
      if (response['type'] == 'IsolateList') {
        _updateIsolates(response['members']);
      }
    });
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
    deadIsolates.forEach((k) {
      print('Removing ${isolates[k]}');
      isolates.remove(k);
    });
    // Add new isolates.
    members.forEach((k) {
      var id = k['id'];
      var name = k['name'];
      if (isolates[id] == null) {
        var isolate = new Isolate(id, name);
        print('Adding $isolate');
        isolates[id] = isolate;
      }
    });
  }
}
