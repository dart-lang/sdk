// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLElementWrappingImplementation extends _ElementWrappingImplementation implements HTMLElement {
  _HTMLElementWrappingImplementation() : super() {}

  static create__HTMLElementWrappingImplementation() native {
    return new _HTMLElementWrappingImplementation();
  }

  HTMLCollection get children() { return _get__HTMLElement_children(this); }
  static HTMLCollection _get__HTMLElement_children(var _this) native;

  DOMTokenList get classList() { return _get__HTMLElement_classList(this); }
  static DOMTokenList _get__HTMLElement_classList(var _this) native;

  String get className() { return _get__HTMLElement_className(this); }
  static String _get__HTMLElement_className(var _this) native;

  void set className(String value) { _set__HTMLElement_className(this, value); }
  static void _set__HTMLElement_className(var _this, String value) native;

  String get contentEditable() { return _get__HTMLElement_contentEditable(this); }
  static String _get__HTMLElement_contentEditable(var _this) native;

  void set contentEditable(String value) { _set__HTMLElement_contentEditable(this, value); }
  static void _set__HTMLElement_contentEditable(var _this, String value) native;

  String get dir() { return _get__HTMLElement_dir(this); }
  static String _get__HTMLElement_dir(var _this) native;

  void set dir(String value) { _set__HTMLElement_dir(this, value); }
  static void _set__HTMLElement_dir(var _this, String value) native;

  bool get draggable() { return _get__HTMLElement_draggable(this); }
  static bool _get__HTMLElement_draggable(var _this) native;

  void set draggable(bool value) { _set__HTMLElement_draggable(this, value); }
  static void _set__HTMLElement_draggable(var _this, bool value) native;

  bool get hidden() { return _get__HTMLElement_hidden(this); }
  static bool _get__HTMLElement_hidden(var _this) native;

  void set hidden(bool value) { _set__HTMLElement_hidden(this, value); }
  static void _set__HTMLElement_hidden(var _this, bool value) native;

  String get id() { return _get__HTMLElement_id(this); }
  static String _get__HTMLElement_id(var _this) native;

  void set id(String value) { _set__HTMLElement_id(this, value); }
  static void _set__HTMLElement_id(var _this, String value) native;

  String get innerHTML() { return _get__HTMLElement_innerHTML(this); }
  static String _get__HTMLElement_innerHTML(var _this) native;

  void set innerHTML(String value) { _set__HTMLElement_innerHTML(this, value); }
  static void _set__HTMLElement_innerHTML(var _this, String value) native;

  String get innerText() { return _get__HTMLElement_innerText(this); }
  static String _get__HTMLElement_innerText(var _this) native;

  void set innerText(String value) { _set__HTMLElement_innerText(this, value); }
  static void _set__HTMLElement_innerText(var _this, String value) native;

  bool get isContentEditable() { return _get__HTMLElement_isContentEditable(this); }
  static bool _get__HTMLElement_isContentEditable(var _this) native;

  String get lang() { return _get__HTMLElement_lang(this); }
  static String _get__HTMLElement_lang(var _this) native;

  void set lang(String value) { _set__HTMLElement_lang(this, value); }
  static void _set__HTMLElement_lang(var _this, String value) native;

  String get outerHTML() { return _get__HTMLElement_outerHTML(this); }
  static String _get__HTMLElement_outerHTML(var _this) native;

  void set outerHTML(String value) { _set__HTMLElement_outerHTML(this, value); }
  static void _set__HTMLElement_outerHTML(var _this, String value) native;

  String get outerText() { return _get__HTMLElement_outerText(this); }
  static String _get__HTMLElement_outerText(var _this) native;

  void set outerText(String value) { _set__HTMLElement_outerText(this, value); }
  static void _set__HTMLElement_outerText(var _this, String value) native;

  bool get spellcheck() { return _get__HTMLElement_spellcheck(this); }
  static bool _get__HTMLElement_spellcheck(var _this) native;

  void set spellcheck(bool value) { _set__HTMLElement_spellcheck(this, value); }
  static void _set__HTMLElement_spellcheck(var _this, bool value) native;

  int get tabIndex() { return _get__HTMLElement_tabIndex(this); }
  static int _get__HTMLElement_tabIndex(var _this) native;

  void set tabIndex(int value) { _set__HTMLElement_tabIndex(this, value); }
  static void _set__HTMLElement_tabIndex(var _this, int value) native;

  String get title() { return _get__HTMLElement_title(this); }
  static String _get__HTMLElement_title(var _this) native;

  void set title(String value) { _set__HTMLElement_title(this, value); }
  static void _set__HTMLElement_title(var _this, String value) native;

  String get webkitdropzone() { return _get__HTMLElement_webkitdropzone(this); }
  static String _get__HTMLElement_webkitdropzone(var _this) native;

  void set webkitdropzone(String value) { _set__HTMLElement_webkitdropzone(this, value); }
  static void _set__HTMLElement_webkitdropzone(var _this, String value) native;

  Element insertAdjacentElement([String where = null, Element element = null]) {
    if (where === null) {
      if (element === null) {
        return _insertAdjacentElement(this);
      }
    } else {
      if (element === null) {
        return _insertAdjacentElement_2(this, where);
      } else {
        return _insertAdjacentElement_3(this, where, element);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static Element _insertAdjacentElement(receiver) native;
  static Element _insertAdjacentElement_2(receiver, where) native;
  static Element _insertAdjacentElement_3(receiver, where, element) native;

  void insertAdjacentHTML([String where = null, String html = null]) {
    if (where === null) {
      if (html === null) {
        _insertAdjacentHTML(this);
        return;
      }
    } else {
      if (html === null) {
        _insertAdjacentHTML_2(this, where);
        return;
      } else {
        _insertAdjacentHTML_3(this, where, html);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _insertAdjacentHTML(receiver) native;
  static void _insertAdjacentHTML_2(receiver, where) native;
  static void _insertAdjacentHTML_3(receiver, where, html) native;

  void insertAdjacentText([String where = null, String text = null]) {
    if (where === null) {
      if (text === null) {
        _insertAdjacentText(this);
        return;
      }
    } else {
      if (text === null) {
        _insertAdjacentText_2(this, where);
        return;
      } else {
        _insertAdjacentText_3(this, where, text);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _insertAdjacentText(receiver) native;
  static void _insertAdjacentText_2(receiver, where) native;
  static void _insertAdjacentText_3(receiver, where, text) native;

  String get typeName() { return "HTMLElement"; }
}
