// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLElementWrappingImplementation extends _ElementWrappingImplementation implements HTMLElement {
  _HTMLElementWrappingImplementation() : super() {}

  static create__HTMLElementWrappingImplementation() native {
    return new _HTMLElementWrappingImplementation();
  }

  HTMLCollection get children() { return _get_children(this); }
  static HTMLCollection _get_children(var _this) native;

  DOMTokenList get classList() { return _get_classList(this); }
  static DOMTokenList _get_classList(var _this) native;

  String get className() { return _get_className(this); }
  static String _get_className(var _this) native;

  void set className(String value) { _set_className(this, value); }
  static void _set_className(var _this, String value) native;

  String get contentEditable() { return _get_contentEditable(this); }
  static String _get_contentEditable(var _this) native;

  void set contentEditable(String value) { _set_contentEditable(this, value); }
  static void _set_contentEditable(var _this, String value) native;

  String get dir() { return _get_dir(this); }
  static String _get_dir(var _this) native;

  void set dir(String value) { _set_dir(this, value); }
  static void _set_dir(var _this, String value) native;

  bool get draggable() { return _get_draggable(this); }
  static bool _get_draggable(var _this) native;

  void set draggable(bool value) { _set_draggable(this, value); }
  static void _set_draggable(var _this, bool value) native;

  bool get hidden() { return _get_hidden(this); }
  static bool _get_hidden(var _this) native;

  void set hidden(bool value) { _set_hidden(this, value); }
  static void _set_hidden(var _this, bool value) native;

  String get id() { return _get_id(this); }
  static String _get_id(var _this) native;

  void set id(String value) { _set_id(this, value); }
  static void _set_id(var _this, String value) native;

  String get innerHTML() { return _get_innerHTML(this); }
  static String _get_innerHTML(var _this) native;

  void set innerHTML(String value) { _set_innerHTML(this, value); }
  static void _set_innerHTML(var _this, String value) native;

  String get innerText() { return _get_innerText(this); }
  static String _get_innerText(var _this) native;

  void set innerText(String value) { _set_innerText(this, value); }
  static void _set_innerText(var _this, String value) native;

  bool get isContentEditable() { return _get_isContentEditable(this); }
  static bool _get_isContentEditable(var _this) native;

  String get itemId() { return _get_itemId(this); }
  static String _get_itemId(var _this) native;

  void set itemId(String value) { _set_itemId(this, value); }
  static void _set_itemId(var _this, String value) native;

  DOMSettableTokenList get itemProp() { return _get_itemProp(this); }
  static DOMSettableTokenList _get_itemProp(var _this) native;

  DOMSettableTokenList get itemRef() { return _get_itemRef(this); }
  static DOMSettableTokenList _get_itemRef(var _this) native;

  bool get itemScope() { return _get_itemScope(this); }
  static bool _get_itemScope(var _this) native;

  void set itemScope(bool value) { _set_itemScope(this, value); }
  static void _set_itemScope(var _this, bool value) native;

  DOMSettableTokenList get itemType() { return _get_itemType(this); }
  static DOMSettableTokenList _get_itemType(var _this) native;

  Object get itemValue() { return _get_itemValue(this); }
  static Object _get_itemValue(var _this) native;

  void set itemValue(Object value) { _set_itemValue(this, value); }
  static void _set_itemValue(var _this, Object value) native;

  String get lang() { return _get_lang(this); }
  static String _get_lang(var _this) native;

  void set lang(String value) { _set_lang(this, value); }
  static void _set_lang(var _this, String value) native;

  String get outerHTML() { return _get_outerHTML(this); }
  static String _get_outerHTML(var _this) native;

  void set outerHTML(String value) { _set_outerHTML(this, value); }
  static void _set_outerHTML(var _this, String value) native;

  String get outerText() { return _get_outerText(this); }
  static String _get_outerText(var _this) native;

  void set outerText(String value) { _set_outerText(this, value); }
  static void _set_outerText(var _this, String value) native;

  bool get spellcheck() { return _get_spellcheck(this); }
  static bool _get_spellcheck(var _this) native;

  void set spellcheck(bool value) { _set_spellcheck(this, value); }
  static void _set_spellcheck(var _this, bool value) native;

  int get tabIndex() { return _get_tabIndex(this); }
  static int _get_tabIndex(var _this) native;

  void set tabIndex(int value) { _set_tabIndex(this, value); }
  static void _set_tabIndex(var _this, int value) native;

  String get title() { return _get_title(this); }
  static String _get_title(var _this) native;

  void set title(String value) { _set_title(this, value); }
  static void _set_title(var _this, String value) native;

  String get webkitdropzone() { return _get_webkitdropzone(this); }
  static String _get_webkitdropzone(var _this) native;

  void set webkitdropzone(String value) { _set_webkitdropzone(this, value); }
  static void _set_webkitdropzone(var _this, String value) native;

  Element insertAdjacentElement(String where, Element element) {
    return _insertAdjacentElement(this, where, element);
  }
  static Element _insertAdjacentElement(receiver, where, element) native;

  void insertAdjacentHTML(String where, String html) {
    _insertAdjacentHTML(this, where, html);
    return;
  }
  static void _insertAdjacentHTML(receiver, where, html) native;

  void insertAdjacentText(String where, String text) {
    _insertAdjacentText(this, where, text);
    return;
  }
  static void _insertAdjacentText(receiver, where, text) native;

  String get typeName() { return "HTMLElement"; }
}
