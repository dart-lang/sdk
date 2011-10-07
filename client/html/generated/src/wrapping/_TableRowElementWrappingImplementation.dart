// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableRowElementWrappingImplementation extends ElementWrappingImplementation implements TableRowElement {
  TableRowElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get bgColor() { return _ptr.bgColor; }

  void set bgColor(String value) { _ptr.bgColor = value; }

  ElementList get cells() { return LevelDom.wrapElementList(_ptr.cells); }

  String get ch() { return _ptr.ch; }

  void set ch(String value) { _ptr.ch = value; }

  String get chOff() { return _ptr.chOff; }

  void set chOff(String value) { _ptr.chOff = value; }

  int get rowIndex() { return _ptr.rowIndex; }

  int get sectionRowIndex() { return _ptr.sectionRowIndex; }

  String get vAlign() { return _ptr.vAlign; }

  void set vAlign(String value) { _ptr.vAlign = value; }

  void deleteCell(int index) {
    _ptr.deleteCell(index);
    return;
  }

  Element insertCell(int index) {
    return LevelDom.wrapElement(_ptr.insertCell(index));
  }
}
