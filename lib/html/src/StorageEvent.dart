// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface StorageEvent extends Event default StorageEventWrappingImplementation {

  StorageEvent(String type, String key, String url, Storage storageArea,
      [bool canBubble, bool cancelable, String oldValue, String newValue]);

  String get key;

  String get newValue;

  String get oldValue;

  Storage get storageArea;

  String get url;
}
