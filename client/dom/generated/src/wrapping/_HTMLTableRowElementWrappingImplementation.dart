// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLTableRowElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLTableRowElement {
  _HTMLTableRowElementWrappingImplementation() : super() {}

  static create__HTMLTableRowElementWrappingImplementation() native {
    return new _HTMLTableRowElementWrappingImplementation();
  }

  String get align() { return _get_align(this); }
  static String _get_align(var _this) native;

  void set align(String value) { _set_align(this, value); }
  static void _set_align(var _this, String value) native;

  String get bgColor() { return _get_bgColor(this); }
  static String _get_bgColor(var _this) native;

  void set bgColor(String value) { _set_bgColor(this, value); }
  static void _set_bgColor(var _this, String value) native;

  HTMLCollection get cells() { return _get_cells(this); }
  static HTMLCollection _get_cells(var _this) native;

  String get ch() { return _get_ch(this); }
  static String _get_ch(var _this) native;

  void set ch(String value) { _set_ch(this, value); }
  static void _set_ch(var _this, String value) native;

  String get chOff() { return _get_chOff(this); }
  static String _get_chOff(var _this) native;

  void set chOff(String value) { _set_chOff(this, value); }
  static void _set_chOff(var _this, String value) native;

  int get rowIndex() { return _get_rowIndex(this); }
  static int _get_rowIndex(var _this) native;

  int get sectionRowIndex() { return _get_sectionRowIndex(this); }
  static int _get_sectionRowIndex(var _this) native;

  String get vAlign() { return _get_vAlign(this); }
  static String _get_vAlign(var _this) native;

  void set vAlign(String value) { _set_vAlign(this, value); }
  static void _set_vAlign(var _this, String value) native;

  void deleteCell(int index) {
    _deleteCell(this, index);
    return;
  }
  static void _deleteCell(receiver, index) native;

  HTMLElement insertCell(int index) {
    return _insertCell(this, index);
  }
  static HTMLElement _insertCell(receiver, index) native;

  String get typeName() { return "HTMLTableRowElement"; }
}
