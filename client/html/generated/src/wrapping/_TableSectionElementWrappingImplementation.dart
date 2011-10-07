// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableSectionElementWrappingImplementation extends ElementWrappingImplementation implements TableSectionElement {
  TableSectionElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get ch() { return _ptr.ch; }

  void set ch(String value) { _ptr.ch = value; }

  String get chOff() { return _ptr.chOff; }

  void set chOff(String value) { _ptr.chOff = value; }

  ElementList get rows() { return LevelDom.wrapElementList(_ptr.rows); }

  String get vAlign() { return _ptr.vAlign; }

  void set vAlign(String value) { _ptr.vAlign = value; }

  void deleteRow(int index) {
    _ptr.deleteRow(index);
    return;
  }

  Element insertRow(int index) {
    return LevelDom.wrapElement(_ptr.insertRow(index));
  }
}
