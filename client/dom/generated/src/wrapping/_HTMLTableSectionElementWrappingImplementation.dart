// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLTableSectionElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLTableSectionElement {
  _HTMLTableSectionElementWrappingImplementation() : super() {}

  static create__HTMLTableSectionElementWrappingImplementation() native {
    return new _HTMLTableSectionElementWrappingImplementation();
  }

  String get align() { return _get__HTMLTableSectionElement_align(this); }
  static String _get__HTMLTableSectionElement_align(var _this) native;

  void set align(String value) { _set__HTMLTableSectionElement_align(this, value); }
  static void _set__HTMLTableSectionElement_align(var _this, String value) native;

  String get ch() { return _get__HTMLTableSectionElement_ch(this); }
  static String _get__HTMLTableSectionElement_ch(var _this) native;

  void set ch(String value) { _set__HTMLTableSectionElement_ch(this, value); }
  static void _set__HTMLTableSectionElement_ch(var _this, String value) native;

  String get chOff() { return _get__HTMLTableSectionElement_chOff(this); }
  static String _get__HTMLTableSectionElement_chOff(var _this) native;

  void set chOff(String value) { _set__HTMLTableSectionElement_chOff(this, value); }
  static void _set__HTMLTableSectionElement_chOff(var _this, String value) native;

  HTMLCollection get rows() { return _get__HTMLTableSectionElement_rows(this); }
  static HTMLCollection _get__HTMLTableSectionElement_rows(var _this) native;

  String get vAlign() { return _get__HTMLTableSectionElement_vAlign(this); }
  static String _get__HTMLTableSectionElement_vAlign(var _this) native;

  void set vAlign(String value) { _set__HTMLTableSectionElement_vAlign(this, value); }
  static void _set__HTMLTableSectionElement_vAlign(var _this, String value) native;

  void deleteRow(int index) {
    _deleteRow(this, index);
    return;
  }
  static void _deleteRow(receiver, index) native;

  HTMLElement insertRow(int index) {
    return _insertRow(this, index);
  }
  static HTMLElement _insertRow(receiver, index) native;

  String get typeName() { return "HTMLTableSectionElement"; }
}
