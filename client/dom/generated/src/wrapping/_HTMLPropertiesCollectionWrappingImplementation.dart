// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLPropertiesCollectionWrappingImplementation extends _HTMLCollectionWrappingImplementation implements HTMLPropertiesCollection {
  _HTMLPropertiesCollectionWrappingImplementation() : super() {}

  static create__HTMLPropertiesCollectionWrappingImplementation() native {
    return new _HTMLPropertiesCollectionWrappingImplementation();
  }

  int get length() { return _get_length_HTMLPropertiesCollection(this); }
  static int _get_length_HTMLPropertiesCollection(var _this) native;

  Node item(int index) {
    return _item_HTMLPropertiesCollection(this, index);
  }
  static Node _item_HTMLPropertiesCollection(receiver, index) native;

  String get typeName() { return "HTMLPropertiesCollection"; }
}
