// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBVersionChangeRequestWrappingImplementation extends IDBRequestWrappingImplementation implements IDBVersionChangeRequest {
  IDBVersionChangeRequestWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  EventListener get onblocked() { return LevelDom.wrapEventListener(_ptr.onblocked); }

  void set onblocked(EventListener value) { _ptr.onblocked = LevelDom.unwrap(value); }

  String get typeName() { return "IDBVersionChangeRequest"; }
}
