// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _StorageEventWrappingImplementation extends _EventWrappingImplementation implements StorageEvent {
  _StorageEventWrappingImplementation() : super() {}

  static create__StorageEventWrappingImplementation() native {
    return new _StorageEventWrappingImplementation();
  }

  String get key() { return _get__StorageEvent_key(this); }
  static String _get__StorageEvent_key(var _this) native;

  String get newValue() { return _get__StorageEvent_newValue(this); }
  static String _get__StorageEvent_newValue(var _this) native;

  String get oldValue() { return _get__StorageEvent_oldValue(this); }
  static String _get__StorageEvent_oldValue(var _this) native;

  Storage get storageArea() { return _get__StorageEvent_storageArea(this); }
  static Storage _get__StorageEvent_storageArea(var _this) native;

  String get url() { return _get__StorageEvent_url(this); }
  static String _get__StorageEvent_url(var _this) native;

  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, Storage storageAreaArg) {
    _initStorageEvent(this, typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg, newValueArg, urlArg, storageAreaArg);
    return;
  }
  static void _initStorageEvent(receiver, typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg, newValueArg, urlArg, storageAreaArg) native;

  String get typeName() { return "StorageEvent"; }
}
