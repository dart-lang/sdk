// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBDatabaseWrappingImplementation extends DOMWrapperBase implements IDBDatabase {
  IDBDatabaseWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  String get version() { return _ptr.version; }

  void addEventListener(String type, EventListener listener, [bool useCapture]) {
    if (useCapture === null) {
      _ptr.addEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }

  void close() {
    _ptr.close();
    return;
  }

  IDBObjectStore createObjectStore(String name) {
    return LevelDom.wrapIDBObjectStore(_ptr.createObjectStore(name));
  }

  void deleteObjectStore(String name) {
    _ptr.deleteObjectStore(name);
    return;
  }

  bool dispatchEvent(Event evt) {
    return _ptr.dispatchEvent(LevelDom.unwrap(evt));
  }

  void removeEventListener(String type, EventListener listener, [bool useCapture]) {
    if (useCapture === null) {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }

  IDBVersionChangeRequest setVersion(String version) {
    return LevelDom.wrapIDBVersionChangeRequest(_ptr.setVersion(version));
  }

  IDBTransaction transaction(String storeName, int mode) {
    return LevelDom.wrapIDBTransaction(_ptr.transaction(storeName, mode));
  }
}
