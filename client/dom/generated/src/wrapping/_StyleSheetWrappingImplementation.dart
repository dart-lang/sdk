// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _StyleSheetWrappingImplementation extends DOMWrapperBase implements StyleSheet {
  _StyleSheetWrappingImplementation() : super() {}

  static create__StyleSheetWrappingImplementation() native {
    return new _StyleSheetWrappingImplementation();
  }

  bool get disabled() { return _get__StyleSheet_disabled(this); }
  static bool _get__StyleSheet_disabled(var _this) native;

  void set disabled(bool value) { _set__StyleSheet_disabled(this, value); }
  static void _set__StyleSheet_disabled(var _this, bool value) native;

  String get href() { return _get__StyleSheet_href(this); }
  static String _get__StyleSheet_href(var _this) native;

  MediaList get media() { return _get__StyleSheet_media(this); }
  static MediaList _get__StyleSheet_media(var _this) native;

  Node get ownerNode() { return _get__StyleSheet_ownerNode(this); }
  static Node _get__StyleSheet_ownerNode(var _this) native;

  StyleSheet get parentStyleSheet() { return _get__StyleSheet_parentStyleSheet(this); }
  static StyleSheet _get__StyleSheet_parentStyleSheet(var _this) native;

  String get title() { return _get__StyleSheet_title(this); }
  static String _get__StyleSheet_title(var _this) native;

  String get type() { return _get__StyleSheet_type(this); }
  static String _get__StyleSheet_type(var _this) native;

  String get typeName() { return "StyleSheet"; }
}
