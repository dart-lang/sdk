// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.vmstats;

// Base class of model that reports changes to registered listeners.
abstract class ObservableModel {
  List<ModelListener> _listeners = [];

  void addListener(Function onUpdate, Function onFailure) {
    _listeners.add(new ModelListener(onUpdate, onFailure));
  }

  void removeListener(Function onUpdate) {
    Iterator<ModelListener> iterator = _listeners.iterator;
    while (iterator.moveNext()) {
      if (iterator.current._onUpdate == onUpdate) {
        _listeners.remove(iterator.current);
        return;
      }
    }
  }

  void notifySuccess() {
   _listeners.forEach((listener) => listener.changed(this));
  }

  void notifyFailure() {
    _listeners.forEach((listener) => listener.failed());
  }
}

// Model of a set of listener functions to call when a model changes.
class ModelListener {
  Function _onUpdate;
  Function _onFailure;

  ModelListener(this._onUpdate, this._onFailure) {}

  void changed(IsolateListModel model) => Function.apply(_onUpdate, [model]);
  void failed() => Function.apply(_onFailure, []);
}


// Model of the current running isolates.
class IsolateListModel extends ObservableModel {
  List<Isolate> _isolates = [];

  void update() {
    HttpRequest.getString('/isolates').then(
        (Map response) => _onUpdate(JSON.parse(response)),
        onError: (e) => notifyFailure());
  }

  void _onUpdate(Map isolateMap) {
    _isolates = [];
    List list = isolateMap['isolates'];
    for (int i = 0; i < list.length; i++) {
      _isolates.add(new Isolate(list[i]));
    }
    notifySuccess();
  }

  String toString() {
    return _isolates.join(', ');
  }

  // List delegate method subset.
  Isolate elementAt(int index) => _isolates[index];

  void forEach(void f(Isolate element)) => _isolates.forEach(f);

  bool isEmpty() => _isolates.isEmpty;

  Iterator<Isolate> get iterator => _isolates.iterator;

  int get length => _isolates.length;

  Isolate operator[](int index) => _isolates[index];
}


// Model of a single isolate.
class Isolate {
  final String handle;
  final String name;
  final int port;
  final int startTime;
  final int stackLimit;
  final Space newSpace;
  final Space oldSpace;

  // Create an isolate from a map describing an isolate in the observed VM.
  Isolate(Map raw):
      handle = raw['handle'],
      name = raw['name'],
      port = raw['port'],
      startTime = raw['starttime'],
      stackLimit = raw['stacklimit'],
      newSpace = new Space(raw['newspace']),
      oldSpace = new Space(raw['oldspace']) {}

  String toString() {
    return '$name: ${newSpace.used + oldSpace.used}K';
  }
}

// Model of a memory space.
class Space {
  final int used;
  final int capacity;

  Space(Map raw): used = raw['used'], capacity = raw['capacity'] {}

  String toString() {
    return 'used: $used capacity: $capacity';
  }
}
