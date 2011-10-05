// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableElementWrappingImplementation extends ElementWrappingImplementation implements TableElement {
  TableElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get bgColor() { return _ptr.bgColor; }

  void set bgColor(String value) { _ptr.bgColor = value; }

  String get border() { return _ptr.border; }

  void set border(String value) { _ptr.border = value; }

  TableCaptionElement get caption() { return LevelDom.wrapTableCaptionElement(_ptr.caption); }

  void set caption(TableCaptionElement value) { _ptr.caption = LevelDom.unwrap(value); }

  String get cellPadding() { return _ptr.cellPadding; }

  void set cellPadding(String value) { _ptr.cellPadding = value; }

  String get cellSpacing() { return _ptr.cellSpacing; }

  void set cellSpacing(String value) { _ptr.cellSpacing = value; }

  String get frame() { return _ptr.frame; }

  void set frame(String value) { _ptr.frame = value; }

  ElementList get rows() { return LevelDom.wrapElementList(_ptr.rows); }

  String get rules() { return _ptr.rules; }

  void set rules(String value) { _ptr.rules = value; }

  String get summary() { return _ptr.summary; }

  void set summary(String value) { _ptr.summary = value; }

  ElementList get tBodies() { return LevelDom.wrapElementList(_ptr.tBodies); }

  TableSectionElement get tFoot() { return LevelDom.wrapTableSectionElement(_ptr.tFoot); }

  void set tFoot(TableSectionElement value) { _ptr.tFoot = LevelDom.unwrap(value); }

  TableSectionElement get tHead() { return LevelDom.wrapTableSectionElement(_ptr.tHead); }

  void set tHead(TableSectionElement value) { _ptr.tHead = LevelDom.unwrap(value); }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }

  Element createCaption() {
    return LevelDom.wrapElement(_ptr.createCaption());
  }

  Element createTFoot() {
    return LevelDom.wrapElement(_ptr.createTFoot());
  }

  Element createTHead() {
    return LevelDom.wrapElement(_ptr.createTHead());
  }

  void deleteCaption() {
    _ptr.deleteCaption();
    return;
  }

  void deleteRow(int index) {
    _ptr.deleteRow(index);
    return;
  }

  void deleteTFoot() {
    _ptr.deleteTFoot();
    return;
  }

  void deleteTHead() {
    _ptr.deleteTHead();
    return;
  }

  Element insertRow(int index) {
    return LevelDom.wrapElement(_ptr.insertRow(index));
  }

  String get typeName() { return "TableElement"; }
}
