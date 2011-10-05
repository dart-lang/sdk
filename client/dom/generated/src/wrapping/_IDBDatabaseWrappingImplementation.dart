// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBDatabaseWrappingImplementation extends DOMWrapperBase implements IDBDatabase {
  _IDBDatabaseWrappingImplementation() : super() {}

  static create__IDBDatabaseWrappingImplementation() native {
    return new _IDBDatabaseWrappingImplementation();
  }

  String get name() { return _get__IDBDatabase_name(this); }
  static String _get__IDBDatabase_name(var _this) native;

  EventListener get onabort() { return _get__IDBDatabase_onabort(this); }
  static EventListener _get__IDBDatabase_onabort(var _this) native;

  void set onabort(EventListener value) { _set__IDBDatabase_onabort(this, value); }
  static void _set__IDBDatabase_onabort(var _this, EventListener value) native;

  EventListener get onerror() { return _get__IDBDatabase_onerror(this); }
  static EventListener _get__IDBDatabase_onerror(var _this) native;

  void set onerror(EventListener value) { _set__IDBDatabase_onerror(this, value); }
  static void _set__IDBDatabase_onerror(var _this, EventListener value) native;

  EventListener get onversionchange() { return _get__IDBDatabase_onversionchange(this); }
  static EventListener _get__IDBDatabase_onversionchange(var _this) native;

  void set onversionchange(EventListener value) { _set__IDBDatabase_onversionchange(this, value); }
  static void _set__IDBDatabase_onversionchange(var _this, EventListener value) native;

  String get version() { return _get__IDBDatabase_version(this); }
  static String _get__IDBDatabase_version(var _this) native;

  void addEventListener(String type, EventListener listener, bool useCapture = null) {
    if (useCapture === null) {
      _addEventListener(this, type, listener);
      return;
    } else {
      _addEventListener_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _addEventListener(receiver, type, listener) native;
  static void _addEventListener_2(receiver, type, listener, useCapture) native;

  void close() {
    _close(this);
    return;
  }
  static void _close(receiver) native;

  IDBObjectStore createObjectStore(String name) {
    return _createObjectStore(this, name);
  }
  static IDBObjectStore _createObjectStore(receiver, name) native;

  void deleteObjectStore(String name) {
    _deleteObjectStore(this, name);
    return;
  }
  static void _deleteObjectStore(receiver, name) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent(this, evt);
  }
  static bool _dispatchEvent(receiver, evt) native;

  void removeEventListener(String type, EventListener listener, bool useCapture = null) {
    if (useCapture === null) {
      _removeEventListener(this, type, listener);
      return;
    } else {
      _removeEventListener_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _removeEventListener(receiver, type, listener) native;
  static void _removeEventListener_2(receiver, type, listener, useCapture) native;

  IDBVersionChangeRequest setVersion(String version) {
    return _setVersion(this, version);
  }
  static IDBVersionChangeRequest _setVersion(receiver, version) native;

  String get typeName() { return "IDBDatabase"; }
}
