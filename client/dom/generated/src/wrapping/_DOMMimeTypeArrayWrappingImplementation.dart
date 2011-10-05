// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMMimeTypeArrayWrappingImplementation extends DOMWrapperBase implements DOMMimeTypeArray {
  _DOMMimeTypeArrayWrappingImplementation() : super() {}

  static create__DOMMimeTypeArrayWrappingImplementation() native {
    return new _DOMMimeTypeArrayWrappingImplementation();
  }

  int get length() { return _get__DOMMimeTypeArray_length(this); }
  static int _get__DOMMimeTypeArray_length(var _this) native;

  DOMMimeType item([int index = null]) {
    if (index === null) {
      return _item(this);
    } else {
      return _item_2(this, index);
    }
  }
  static DOMMimeType _item(receiver) native;
  static DOMMimeType _item_2(receiver, index) native;

  DOMMimeType namedItem([String name = null]) {
    if (name === null) {
      return _namedItem(this);
    } else {
      return _namedItem_2(this, name);
    }
  }
  static DOMMimeType _namedItem(receiver) native;
  static DOMMimeType _namedItem_2(receiver, name) native;

  String get typeName() { return "DOMMimeTypeArray"; }
}
