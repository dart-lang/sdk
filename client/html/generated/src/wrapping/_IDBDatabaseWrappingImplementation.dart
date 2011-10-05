// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBDatabaseWrappingImplementation extends DOMWrapperBase implements IDBDatabase {
  IDBDatabaseWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  EventListener get onabort() { return LevelDom.wrapEventListener(_ptr.onabort); }

  void set onabort(EventListener value) { _ptr.onabort = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onversionchange() { return LevelDom.wrapEventListener(_ptr.onversionchange); }

  void set onversionchange(EventListener value) { _ptr.onversionchange = LevelDom.unwrap(value); }

  String get version() { return _ptr.version; }

  void addEventListener(String type, EventListener listener, bool useCapture) {
    _ptr.addEventListener(type, LevelDom.unwrap(listener), useCapture);
    return;
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

  void removeEventListener(String type, EventListener listener, bool useCapture) {
    _ptr.removeEventListener(type, LevelDom.unwrap(listener), useCapture);
    return;
  }

  IDBVersionChangeRequest setVersion(String version) {
    return LevelDom.wrapIDBVersionChangeRequest(_ptr.setVersion(version));
  }

  String get typeName() { return "IDBDatabase"; }
}
