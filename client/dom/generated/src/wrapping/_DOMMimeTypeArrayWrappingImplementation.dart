// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMMimeTypeArrayWrappingImplementation extends DOMWrapperBase implements DOMMimeTypeArray {
  _DOMMimeTypeArrayWrappingImplementation() : super() {}

  static create__DOMMimeTypeArrayWrappingImplementation() native {
    return new _DOMMimeTypeArrayWrappingImplementation();
  }

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  DOMMimeType item(int index) {
    return _item(this, index);
  }
  static DOMMimeType _item(receiver, index) native;

  DOMMimeType namedItem(String name) {
    return _namedItem(this, name);
  }
  static DOMMimeType _namedItem(receiver, name) native;

  String get typeName() { return "DOMMimeTypeArray"; }
}
