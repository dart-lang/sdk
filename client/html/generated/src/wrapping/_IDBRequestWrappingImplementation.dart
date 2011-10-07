// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBRequestWrappingImplementation extends DOMWrapperBase implements IDBRequest {
  IDBRequestWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get errorCode() { return _ptr.errorCode; }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onsuccess() { return LevelDom.wrapEventListener(_ptr.onsuccess); }

  void set onsuccess(EventListener value) { _ptr.onsuccess = LevelDom.unwrap(value); }

  int get readyState() { return _ptr.readyState; }

  IDBAny get result() { return LevelDom.wrapIDBAny(_ptr.result); }

  IDBAny get source() { return LevelDom.wrapIDBAny(_ptr.source); }

  IDBTransaction get transaction() { return LevelDom.wrapIDBTransaction(_ptr.transaction); }

  String get webkitErrorMessage() { return _ptr.webkitErrorMessage; }

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
