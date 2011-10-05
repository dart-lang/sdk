// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLOptionsCollectionWrappingImplementation extends _HTMLCollectionWrappingImplementation implements HTMLOptionsCollection {
  _HTMLOptionsCollectionWrappingImplementation() : super() {}

  static create__HTMLOptionsCollectionWrappingImplementation() native {
    return new _HTMLOptionsCollectionWrappingImplementation();
  }

  int get length() { return _get__HTMLOptionsCollection_length(this); }
  static int _get__HTMLOptionsCollection_length(var _this) native;

  void set length(int value) { _set__HTMLOptionsCollection_length(this, value); }
  static void _set__HTMLOptionsCollection_length(var _this, int value) native;

  int get selectedIndex() { return _get__HTMLOptionsCollection_selectedIndex(this); }
  static int _get__HTMLOptionsCollection_selectedIndex(var _this) native;

  void set selectedIndex(int value) { _set__HTMLOptionsCollection_selectedIndex(this, value); }
  static void _set__HTMLOptionsCollection_selectedIndex(var _this, int value) native;

  void remove(int index = null) {
    if (index === null) {
      _remove(this);
      return;
    } else {
      _remove_2(this, index);
      return;
    }
  }
  static void _remove(receiver) native;
  static void _remove_2(receiver, index) native;

  String get typeName() { return "HTMLOptionsCollection"; }
}
