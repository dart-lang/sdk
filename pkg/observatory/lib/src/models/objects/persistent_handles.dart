// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class PersistentHandles {
  Iterable<PersistentHandle> get elements;
  Iterable<WeakPersistentHandle> get weakElements;
}

abstract class PersistentHandle {
  ObjectRef get object;
}

abstract class WeakPersistentHandle implements PersistentHandle {
  int get externalSize;
  String get peer;
  String get callbackSymbolName;
  String get callbackAddress;
}
