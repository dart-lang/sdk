// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

abstract class VM extends Observable {
  @observable ObservatoryApplication get app => _app;
  ObservatoryApplication _app;

  Future<String> fetchString(String path);

  Future<ObservableMap> fetchMap(String path) {
    return fetchString(path).then((response) {
      try {
        var map = JSON.decode(response);
        return toObservable(map);
      } catch (e, st) {
        return toObservable({
          'type': 'Error',
          'errorType': 'DecodeError',
          'text': '$e $st'
        });
      }
    }).catchError((error) {
      return toObservable({
        'type': 'Error',
        'errorType': 'FetchError',
        'text': '$error'
      });
    });
  }

  @observable final ObservableMap isolates = new ObservableMap();
  Isolate getIsolate(String id) {
    var isolate = isolates[id];
    if (isolate != null) {
      return isolate;
    }
    isolate = new Isolate.fromId(this, id);
    isolates[id] = isolate;
    return isolate;
  }

  static bool _foundIsolateInMembers(String id, List<Map> members) {
    return members.any((E) => E['id'] == id);
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
        isolate = new Isolate.fromMap(this, map);
        isolates[id] = isolate;
      }
      isolate.refresh();
    });
  }

  void refreshIsolates() {
    fetchMap('isolates').then((map) {
      assert(map['type'] == 'IsolateList');
      _updateIsolates(map['members']);
      app.setResponse(map);
    });
  }
}


class HttpVM extends VM {
  final String address;
  HttpVM(this.address);

  Future<String> fetchString(String path) {
    Logger.root.info('Fetching $path from $address');
    return HttpRequest.getString(address + path);
  }
}

class DartiumVM extends VM {
  final Map _outstandingRequests = new Map();
  int _requestSerial = 0;
  PostMessageRequestManager() {
    window.onMessage.listen(_messageHandler);
  }

  void _messageHandler(msg) {
    var id = msg.data['id'];
    var name = msg.data['name'];
    var data = msg.data['data'];
    if (name != 'observatoryData') {
      return;
    }
    var completer = _outstandingRequests[id];
    assert(completer != null);
    _outstandingRequests.remove(id);
    completer.complete(data);
  }

  Future<String> fetchString(String path) {
    var idString = '$_requestSerial';
    Map message = {};
    message['id'] = idString;
    message['method'] = 'observatoryQuery';
    message['query'] = path;
    _requestSerial++;
    var completer = new Completer();
    _outstandingRequests[idString] = completer;
    window.parent.postMessage(JSON.encode(message), '*');
    return completer.future;
  }
}
