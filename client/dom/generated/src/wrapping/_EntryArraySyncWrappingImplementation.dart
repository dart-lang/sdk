// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _EntryArraySyncWrappingImplementation extends DOMWrapperBase implements EntryArraySync {
  _EntryArraySyncWrappingImplementation() : super() {}

  static create__EntryArraySyncWrappingImplementation() native {
    return new _EntryArraySyncWrappingImplementation();
  }

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  EntrySync item(int index) {
    return _item(this, index);
  }
  static EntrySync _item(receiver, index) native;

  String get typeName() { return "EntryArraySync"; }
}
