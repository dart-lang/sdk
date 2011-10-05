// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLTableRowElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLTableRowElement {
  _HTMLTableRowElementWrappingImplementation() : super() {}

  static create__HTMLTableRowElementWrappingImplementation() native {
    return new _HTMLTableRowElementWrappingImplementation();
  }

  String get align() { return _get__HTMLTableRowElement_align(this); }
  static String _get__HTMLTableRowElement_align(var _this) native;

  void set align(String value) { _set__HTMLTableRowElement_align(this, value); }
  static void _set__HTMLTableRowElement_align(var _this, String value) native;

  String get bgColor() { return _get__HTMLTableRowElement_bgColor(this); }
  static String _get__HTMLTableRowElement_bgColor(var _this) native;

  void set bgColor(String value) { _set__HTMLTableRowElement_bgColor(this, value); }
  static void _set__HTMLTableRowElement_bgColor(var _this, String value) native;

  HTMLCollection get cells() { return _get__HTMLTableRowElement_cells(this); }
  static HTMLCollection _get__HTMLTableRowElement_cells(var _this) native;

  String get ch() { return _get__HTMLTableRowElement_ch(this); }
  static String _get__HTMLTableRowElement_ch(var _this) native;

  void set ch(String value) { _set__HTMLTableRowElement_ch(this, value); }
  static void _set__HTMLTableRowElement_ch(var _this, String value) native;

  String get chOff() { return _get__HTMLTableRowElement_chOff(this); }
  static String _get__HTMLTableRowElement_chOff(var _this) native;

  void set chOff(String value) { _set__HTMLTableRowElement_chOff(this, value); }
  static void _set__HTMLTableRowElement_chOff(var _this, String value) native;

  int get rowIndex() { return _get__HTMLTableRowElement_rowIndex(this); }
  static int _get__HTMLTableRowElement_rowIndex(var _this) native;

  int get sectionRowIndex() { return _get__HTMLTableRowElement_sectionRowIndex(this); }
  static int _get__HTMLTableRowElement_sectionRowIndex(var _this) native;

  String get vAlign() { return _get__HTMLTableRowElement_vAlign(this); }
  static String _get__HTMLTableRowElement_vAlign(var _this) native;

  void set vAlign(String value) { _set__HTMLTableRowElement_vAlign(this, value); }
  static void _set__HTMLTableRowElement_vAlign(var _this, String value) native;

  void deleteCell(int index = null) {
    if (index === null) {
      _deleteCell(this);
      return;
    } else {
      _deleteCell_2(this, index);
      return;
    }
  }
  static void _deleteCell(receiver) native;
  static void _deleteCell_2(receiver, index) native;

  HTMLElement insertCell(int index = null) {
    if (index === null) {
      return _insertCell(this);
    } else {
      return _insertCell_2(this, index);
    }
  }
  static HTMLElement _insertCell(receiver) native;
  static HTMLElement _insertCell_2(receiver, index) native;

  String get typeName() { return "HTMLTableRowElement"; }
}
