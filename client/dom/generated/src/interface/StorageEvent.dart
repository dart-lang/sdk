// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StorageEvent extends Event {

  String get key();

  String get newValue();

  String get oldValue();

  Storage get storageArea();

  String get url();

  void initStorageEvent(String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, String keyArg = null, String oldValueArg = null, String newValueArg = null, String urlArg = null, Storage storageAreaArg = null);
}
