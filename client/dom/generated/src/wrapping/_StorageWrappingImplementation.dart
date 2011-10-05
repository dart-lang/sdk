// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _StorageWrappingImplementation extends DOMWrapperBase implements Storage {
  _StorageWrappingImplementation() : super() {}

  static create__StorageWrappingImplementation() native {
    return new _StorageWrappingImplementation();
  }

  int get length() { return _get__Storage_length(this); }
  static int _get__Storage_length(var _this) native;

  void clear() {
    _clear(this);
    return;
  }
  static void _clear(receiver) native;

  String getItem(String key) {
    return _getItem(this, key);
  }
  static String _getItem(receiver, key) native;

  String key(int index) {
    return _key(this, index);
  }
  static String _key(receiver, index) native;

  void removeItem(String key) {
    _removeItem(this, key);
    return;
  }
  static void _removeItem(receiver, key) native;

  void setItem(String key, String data) {
    _setItem(this, key, data);
    return;
  }
  static void _setItem(receiver, key, data) native;

  String get typeName() { return "Storage"; }
}
