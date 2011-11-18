// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLTableElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLTableElement {
  _HTMLTableElementWrappingImplementation() : super() {}

  static create__HTMLTableElementWrappingImplementation() native {
    return new _HTMLTableElementWrappingImplementation();
  }

  String get align() { return _get_align(this); }
  static String _get_align(var _this) native;

  void set align(String value) { _set_align(this, value); }
  static void _set_align(var _this, String value) native;

  String get bgColor() { return _get_bgColor(this); }
  static String _get_bgColor(var _this) native;

  void set bgColor(String value) { _set_bgColor(this, value); }
  static void _set_bgColor(var _this, String value) native;

  String get border() { return _get_border(this); }
  static String _get_border(var _this) native;

  void set border(String value) { _set_border(this, value); }
  static void _set_border(var _this, String value) native;

  HTMLTableCaptionElement get caption() { return _get_caption(this); }
  static HTMLTableCaptionElement _get_caption(var _this) native;

  void set caption(HTMLTableCaptionElement value) { _set_caption(this, value); }
  static void _set_caption(var _this, HTMLTableCaptionElement value) native;

  String get cellPadding() { return _get_cellPadding(this); }
  static String _get_cellPadding(var _this) native;

  void set cellPadding(String value) { _set_cellPadding(this, value); }
  static void _set_cellPadding(var _this, String value) native;

  String get cellSpacing() { return _get_cellSpacing(this); }
  static String _get_cellSpacing(var _this) native;

  void set cellSpacing(String value) { _set_cellSpacing(this, value); }
  static void _set_cellSpacing(var _this, String value) native;

  String get frame() { return _get_frame(this); }
  static String _get_frame(var _this) native;

  void set frame(String value) { _set_frame(this, value); }
  static void _set_frame(var _this, String value) native;

  HTMLCollection get rows() { return _get_rows(this); }
  static HTMLCollection _get_rows(var _this) native;

  String get rules() { return _get_rules(this); }
  static String _get_rules(var _this) native;

  void set rules(String value) { _set_rules(this, value); }
  static void _set_rules(var _this, String value) native;

  String get summary() { return _get_summary(this); }
  static String _get_summary(var _this) native;

  void set summary(String value) { _set_summary(this, value); }
  static void _set_summary(var _this, String value) native;

  HTMLCollection get tBodies() { return _get_tBodies(this); }
  static HTMLCollection _get_tBodies(var _this) native;

  HTMLTableSectionElement get tFoot() { return _get_tFoot(this); }
  static HTMLTableSectionElement _get_tFoot(var _this) native;

  void set tFoot(HTMLTableSectionElement value) { _set_tFoot(this, value); }
  static void _set_tFoot(var _this, HTMLTableSectionElement value) native;

  HTMLTableSectionElement get tHead() { return _get_tHead(this); }
  static HTMLTableSectionElement _get_tHead(var _this) native;

  void set tHead(HTMLTableSectionElement value) { _set_tHead(this, value); }
  static void _set_tHead(var _this, HTMLTableSectionElement value) native;

  String get width() { return _get_width(this); }
  static String _get_width(var _this) native;

  void set width(String value) { _set_width(this, value); }
  static void _set_width(var _this, String value) native;

  HTMLElement createCaption() {
    return _createCaption(this);
  }
  static HTMLElement _createCaption(receiver) native;

  HTMLElement createTFoot() {
    return _createTFoot(this);
  }
  static HTMLElement _createTFoot(receiver) native;

  HTMLElement createTHead() {
    return _createTHead(this);
  }
  static HTMLElement _createTHead(receiver) native;

  void deleteCaption() {
    _deleteCaption(this);
    return;
  }
  static void _deleteCaption(receiver) native;

  void deleteRow(int index) {
    _deleteRow(this, index);
    return;
  }
  static void _deleteRow(receiver, index) native;

  void deleteTFoot() {
    _deleteTFoot(this);
    return;
  }
  static void _deleteTFoot(receiver) native;

  void deleteTHead() {
    _deleteTHead(this);
    return;
  }
  static void _deleteTHead(receiver) native;

  HTMLElement insertRow(int index) {
    return _insertRow(this, index);
  }
  static HTMLElement _insertRow(receiver, index) native;

  String get typeName() { return "HTMLTableElement"; }
}
