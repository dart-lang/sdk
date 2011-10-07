// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBTransactionWrappingImplementation extends DOMWrapperBase implements IDBTransaction {
  IDBTransactionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  IDBDatabase get db() { return LevelDom.wrapIDBDatabase(_ptr.db); }

  int get mode() { return _ptr.mode; }

  EventListener get onabort() { return LevelDom.wrapEventListener(_ptr.onabort); }

  void set onabort(EventListener value) { _ptr.onabort = LevelDom.unwrap(value); }

  EventListener get oncomplete() { return LevelDom.wrapEventListener(_ptr.oncomplete); }

  void set oncomplete(EventListener value) { _ptr.oncomplete = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  void abort() {
    _ptr.abort();
    return;
  }

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }

  bool dispatchEvent(Event evt) {
    return _ptr.dispatchEvent(LevelDom.unwrap(evt));
  }

  IDBObjectStore objectStore(String name) {
    return LevelDom.wrapIDBObjectStore(_ptr.objectStore(name));
  }

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }
}
