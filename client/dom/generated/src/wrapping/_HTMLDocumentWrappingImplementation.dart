// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLDocumentWrappingImplementation extends _DocumentWrappingImplementation implements HTMLDocument {
  _HTMLDocumentWrappingImplementation() : super() {}

  static create__HTMLDocumentWrappingImplementation() native {
    return new _HTMLDocumentWrappingImplementation();
  }

  Element get activeElement() { return _get_activeElement(this); }
  static Element _get_activeElement(var _this) native;

  String get alinkColor() { return _get_alinkColor(this); }
  static String _get_alinkColor(var _this) native;

  void set alinkColor(String value) { _set_alinkColor(this, value); }
  static void _set_alinkColor(var _this, String value) native;

  HTMLAllCollection get all() { return _get_all(this); }
  static HTMLAllCollection _get_all(var _this) native;

  void set all(HTMLAllCollection value) { _set_all(this, value); }
  static void _set_all(var _this, HTMLAllCollection value) native;

  String get bgColor() { return _get_bgColor(this); }
  static String _get_bgColor(var _this) native;

  void set bgColor(String value) { _set_bgColor(this, value); }
  static void _set_bgColor(var _this, String value) native;

  String get compatMode() { return _get_compatMode_HTMLDocument(this); }
  static String _get_compatMode_HTMLDocument(var _this) native;

  String get designMode() { return _get_designMode(this); }
  static String _get_designMode(var _this) native;

  void set designMode(String value) { _set_designMode(this, value); }
  static void _set_designMode(var _this, String value) native;

  String get dir() { return _get_dir(this); }
  static String _get_dir(var _this) native;

  void set dir(String value) { _set_dir(this, value); }
  static void _set_dir(var _this, String value) native;

  HTMLCollection get embeds() { return _get_embeds(this); }
  static HTMLCollection _get_embeds(var _this) native;

  String get fgColor() { return _get_fgColor(this); }
  static String _get_fgColor(var _this) native;

  void set fgColor(String value) { _set_fgColor(this, value); }
  static void _set_fgColor(var _this, String value) native;

  int get height() { return _get_height(this); }
  static int _get_height(var _this) native;

  String get linkColor() { return _get_linkColor(this); }
  static String _get_linkColor(var _this) native;

  void set linkColor(String value) { _set_linkColor(this, value); }
  static void _set_linkColor(var _this, String value) native;

  HTMLCollection get plugins() { return _get_plugins(this); }
  static HTMLCollection _get_plugins(var _this) native;

  HTMLCollection get scripts() { return _get_scripts(this); }
  static HTMLCollection _get_scripts(var _this) native;

  String get vlinkColor() { return _get_vlinkColor(this); }
  static String _get_vlinkColor(var _this) native;

  void set vlinkColor(String value) { _set_vlinkColor(this, value); }
  static void _set_vlinkColor(var _this, String value) native;

  int get width() { return _get_width(this); }
  static int _get_width(var _this) native;

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

  void write(String text) {
    _write(this, text);
    return;
  }
  static void _write(receiver, text) native;

  void writeln(String text) {
    _writeln(this, text);
    return;
  }
  static void _writeln(receiver, text) native;

  String get typeName() { return "HTMLDocument"; }
}
