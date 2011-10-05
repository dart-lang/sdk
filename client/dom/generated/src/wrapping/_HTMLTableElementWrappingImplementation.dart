// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLTableElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLTableElement {
  _HTMLTableElementWrappingImplementation() : super() {}

  static create__HTMLTableElementWrappingImplementation() native {
    return new _HTMLTableElementWrappingImplementation();
  }

  String get align() { return _get__HTMLTableElement_align(this); }
  static String _get__HTMLTableElement_align(var _this) native;

  void set align(String value) { _set__HTMLTableElement_align(this, value); }
  static void _set__HTMLTableElement_align(var _this, String value) native;

  String get bgColor() { return _get__HTMLTableElement_bgColor(this); }
  static String _get__HTMLTableElement_bgColor(var _this) native;

  void set bgColor(String value) { _set__HTMLTableElement_bgColor(this, value); }
  static void _set__HTMLTableElement_bgColor(var _this, String value) native;

  String get border() { return _get__HTMLTableElement_border(this); }
  static String _get__HTMLTableElement_border(var _this) native;

  void set border(String value) { _set__HTMLTableElement_border(this, value); }
  static void _set__HTMLTableElement_border(var _this, String value) native;

  HTMLTableCaptionElement get caption() { return _get__HTMLTableElement_caption(this); }
  static HTMLTableCaptionElement _get__HTMLTableElement_caption(var _this) native;

  void set caption(HTMLTableCaptionElement value) { _set__HTMLTableElement_caption(this, value); }
  static void _set__HTMLTableElement_caption(var _this, HTMLTableCaptionElement value) native;

  String get cellPadding() { return _get__HTMLTableElement_cellPadding(this); }
  static String _get__HTMLTableElement_cellPadding(var _this) native;

  void set cellPadding(String value) { _set__HTMLTableElement_cellPadding(this, value); }
  static void _set__HTMLTableElement_cellPadding(var _this, String value) native;

  String get cellSpacing() { return _get__HTMLTableElement_cellSpacing(this); }
  static String _get__HTMLTableElement_cellSpacing(var _this) native;

  void set cellSpacing(String value) { _set__HTMLTableElement_cellSpacing(this, value); }
  static void _set__HTMLTableElement_cellSpacing(var _this, String value) native;

  String get frame() { return _get__HTMLTableElement_frame(this); }
  static String _get__HTMLTableElement_frame(var _this) native;

  void set frame(String value) { _set__HTMLTableElement_frame(this, value); }
  static void _set__HTMLTableElement_frame(var _this, String value) native;

  HTMLCollection get rows() { return _get__HTMLTableElement_rows(this); }
  static HTMLCollection _get__HTMLTableElement_rows(var _this) native;

  String get rules() { return _get__HTMLTableElement_rules(this); }
  static String _get__HTMLTableElement_rules(var _this) native;

  void set rules(String value) { _set__HTMLTableElement_rules(this, value); }
  static void _set__HTMLTableElement_rules(var _this, String value) native;

  String get summary() { return _get__HTMLTableElement_summary(this); }
  static String _get__HTMLTableElement_summary(var _this) native;

  void set summary(String value) { _set__HTMLTableElement_summary(this, value); }
  static void _set__HTMLTableElement_summary(var _this, String value) native;

  HTMLCollection get tBodies() { return _get__HTMLTableElement_tBodies(this); }
  static HTMLCollection _get__HTMLTableElement_tBodies(var _this) native;

  HTMLTableSectionElement get tFoot() { return _get__HTMLTableElement_tFoot(this); }
  static HTMLTableSectionElement _get__HTMLTableElement_tFoot(var _this) native;

  void set tFoot(HTMLTableSectionElement value) { _set__HTMLTableElement_tFoot(this, value); }
  static void _set__HTMLTableElement_tFoot(var _this, HTMLTableSectionElement value) native;

  HTMLTableSectionElement get tHead() { return _get__HTMLTableElement_tHead(this); }
  static HTMLTableSectionElement _get__HTMLTableElement_tHead(var _this) native;

  void set tHead(HTMLTableSectionElement value) { _set__HTMLTableElement_tHead(this, value); }
  static void _set__HTMLTableElement_tHead(var _this, HTMLTableSectionElement value) native;

  String get width() { return _get__HTMLTableElement_width(this); }
  static String _get__HTMLTableElement_width(var _this) native;

  void set width(String value) { _set__HTMLTableElement_width(this, value); }
  static void _set__HTMLTableElement_width(var _this, String value) native;

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

  void deleteRow([int index = null]) {
    if (index === null) {
      _deleteRow(this);
      return;
    } else {
      _deleteRow_2(this, index);
      return;
    }
  }
  static void _deleteRow(receiver) native;
  static void _deleteRow_2(receiver, index) native;

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

  HTMLElement insertRow([int index = null]) {
    if (index === null) {
      return _insertRow(this);
    } else {
      return _insertRow_2(this, index);
    }
  }
  static HTMLElement _insertRow(receiver) native;
  static HTMLElement _insertRow_2(receiver, index) native;

  String get typeName() { return "HTMLTableElement"; }
}
