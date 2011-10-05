// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _EntryArrayWrappingImplementation extends DOMWrapperBase implements EntryArray {
  _EntryArrayWrappingImplementation() : super() {}

  static create__EntryArrayWrappingImplementation() native {
    return new _EntryArrayWrappingImplementation();
  }

  int get length() { return _get__EntryArray_length(this); }
  static int _get__EntryArray_length(var _this) native;

  Entry item(int index) {
    return _item(this, index);
  }
  static Entry _item(receiver, index) native;

  String get typeName() { return "EntryArray"; }
}
