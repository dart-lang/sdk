// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StorageEventWrappingImplementation extends EventWrappingImplementation implements StorageEvent {
  StorageEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get key() { return _ptr.key; }

  String get newValue() { return _ptr.newValue; }

  String get oldValue() { return _ptr.oldValue; }

  Storage get storageArea() { return LevelDom.wrapStorage(_ptr.storageArea); }

  String get url() { return _ptr.url; }

  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, Storage storageAreaArg) {
    _ptr.initStorageEvent(typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg, newValueArg, urlArg, LevelDom.unwrap(storageAreaArg));
    return;
  }
}
