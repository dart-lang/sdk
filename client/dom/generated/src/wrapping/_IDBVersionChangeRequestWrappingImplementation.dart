// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBVersionChangeRequestWrappingImplementation extends _IDBRequestWrappingImplementation implements IDBVersionChangeRequest {
  _IDBVersionChangeRequestWrappingImplementation() : super() {}

  static create__IDBVersionChangeRequestWrappingImplementation() native {
    return new _IDBVersionChangeRequestWrappingImplementation();
  }

  EventListener get onblocked() { return _get_onblocked(this); }
  static EventListener _get_onblocked(var _this) native;

  void set onblocked(EventListener value) { _set_onblocked(this, value); }
  static void _set_onblocked(var _this, EventListener value) native;

  String get typeName() { return "IDBVersionChangeRequest"; }
}
