// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class StorageEventWrappingImplementation extends EventWrappingImplementation implements StorageEvent {
  StorageEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory StorageEventWrappingImplementation(String type, String key,
      String url, Storage storageArea, [bool canBubble = true,
      bool cancelable = true, String oldValue = null,
      String newValue = null]) {
    final e = dom.document.createEvent("StorageEvent");
    e.initStorageEvent(type, canBubble, cancelable, key, oldValue, newValue,
        url, LevelDom.unwrap(storageArea));
    return LevelDom.wrapStorageEvent(e);
  }

  String get key() => _ptr.key;

  String get newValue() => _ptr.newValue;

  String get oldValue() => _ptr.oldValue;

  Storage get storageArea() => LevelDom.wrapStorage(_ptr.storageArea);

  String get url() => _ptr.url;
}
