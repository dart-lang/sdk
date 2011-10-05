// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLDocumentWrappingImplementation extends _DocumentWrappingImplementation implements HTMLDocument {
  _HTMLDocumentWrappingImplementation() : super() {}

  static create__HTMLDocumentWrappingImplementation() native {
    return new _HTMLDocumentWrappingImplementation();
  }

  Element get activeElement() { return _get__HTMLDocument_activeElement(this); }
  static Element _get__HTMLDocument_activeElement(var _this) native;

  String get alinkColor() { return _get__HTMLDocument_alinkColor(this); }
  static String _get__HTMLDocument_alinkColor(var _this) native;

  void set alinkColor(String value) { _set__HTMLDocument_alinkColor(this, value); }
  static void _set__HTMLDocument_alinkColor(var _this, String value) native;

  String get bgColor() { return _get__HTMLDocument_bgColor(this); }
  static String _get__HTMLDocument_bgColor(var _this) native;

  void set bgColor(String value) { _set__HTMLDocument_bgColor(this, value); }
  static void _set__HTMLDocument_bgColor(var _this, String value) native;

  String get compatMode() { return _get__HTMLDocument_compatMode(this); }
  static String _get__HTMLDocument_compatMode(var _this) native;

  String get designMode() { return _get__HTMLDocument_designMode(this); }
  static String _get__HTMLDocument_designMode(var _this) native;

  void set designMode(String value) { _set__HTMLDocument_designMode(this, value); }
  static void _set__HTMLDocument_designMode(var _this, String value) native;

  String get dir() { return _get__HTMLDocument_dir(this); }
  static String _get__HTMLDocument_dir(var _this) native;

  void set dir(String value) { _set__HTMLDocument_dir(this, value); }
  static void _set__HTMLDocument_dir(var _this, String value) native;

  HTMLCollection get embeds() { return _get__HTMLDocument_embeds(this); }
  static HTMLCollection _get__HTMLDocument_embeds(var _this) native;

  String get fgColor() { return _get__HTMLDocument_fgColor(this); }
  static String _get__HTMLDocument_fgColor(var _this) native;

  void set fgColor(String value) { _set__HTMLDocument_fgColor(this, value); }
  static void _set__HTMLDocument_fgColor(var _this, String value) native;

  int get height() { return _get__HTMLDocument_height(this); }
  static int _get__HTMLDocument_height(var _this) native;

  String get linkColor() { return _get__HTMLDocument_linkColor(this); }
  static String _get__HTMLDocument_linkColor(var _this) native;

  void set linkColor(String value) { _set__HTMLDocument_linkColor(this, value); }
  static void _set__HTMLDocument_linkColor(var _this, String value) native;

  HTMLCollection get plugins() { return _get__HTMLDocument_plugins(this); }
  static HTMLCollection _get__HTMLDocument_plugins(var _this) native;

  HTMLCollection get scripts() { return _get__HTMLDocument_scripts(this); }
  static HTMLCollection _get__HTMLDocument_scripts(var _this) native;

  String get vlinkColor() { return _get__HTMLDocument_vlinkColor(this); }
  static String _get__HTMLDocument_vlinkColor(var _this) native;

  void set vlinkColor(String value) { _set__HTMLDocument_vlinkColor(this, value); }
  static void _set__HTMLDocument_vlinkColor(var _this, String value) native;

  int get width() { return _get__HTMLDocument_width(this); }
  static int _get__HTMLDocument_width(var _this) native;

  void captureEvents() {
    _captureEvents(this);
    return;
  }
  static void _captureEvents(receiver) native;

  void clear() {
    _clear(this);
    return;
  }
  static void _clear(receiver) native;

  void close() {
    _close(this);
    return;
  }
  static void _close(receiver) native;

  bool hasFocus() {
    return _hasFocus(this);
  }
  static bool _hasFocus(receiver) native;

  void open() {
    _open(this);
    return;
  }
  static void _open(receiver) native;

  void releaseEvents() {
    _releaseEvents(this);
    return;
  }
  static void _releaseEvents(receiver) native;

  void write([String text = null]) {
    if (text === null) {
      _write(this);
      return;
    } else {
      _write_2(this, text);
      return;
    }
  }
  static void _write(receiver) native;
  static void _write_2(receiver, text) native;

  void writeln([String text = null]) {
    if (text === null) {
      _writeln(this);
      return;
    } else {
      _writeln_2(this, text);
      return;
    }
  }
  static void _writeln(receiver) native;
  static void _writeln_2(receiver, text) native;

  String get typeName() { return "HTMLDocument"; }
}
