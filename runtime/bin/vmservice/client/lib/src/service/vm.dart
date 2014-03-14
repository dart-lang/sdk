// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of service;

abstract class VM extends Observable {
  @reflectable IsolateList _isolates;
  @reflectable IsolateList get isolates => _isolates;

  void _initOnce() {
    assert(_isolates == null);
    _isolates = new IsolateList(this);
  }

  VM() {
    _initOnce();
  }

  /// Get [id] as an [ObservableMap] from the service directly.
  Future<ObservableMap> getAsMap(String id) {
    return getString(id).then((response) {
      try {
        var map = JSON.decode(response);
        Logger.root.info('Decoded $id');
        return toObservable(map);
      } catch (e, st) {
        return toObservable({
          'type': 'Error',
          'id': '',
          'kind': 'DecodeError',
          'message': '$e',
        });
      }
    }).catchError((error) {
      return toObservable({
        'type': 'Error',
        'id': '',
        'kind': 'LastResort',
        'message': '$error'
      });
    });
  }

  /// Get [id] as a [String] from the service directly. See [getAsMap].
  Future<String> getString(String id);
}
