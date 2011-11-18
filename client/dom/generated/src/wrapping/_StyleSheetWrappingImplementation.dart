// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _StyleSheetWrappingImplementation extends DOMWrapperBase implements StyleSheet {
  _StyleSheetWrappingImplementation() : super() {}

  static create__StyleSheetWrappingImplementation() native {
    return new _StyleSheetWrappingImplementation();
  }

  bool get disabled() { return _get_disabled(this); }
  static bool _get_disabled(var _this) native;

  void set disabled(bool value) { _set_disabled(this, value); }
  static void _set_disabled(var _this, bool value) native;

  String get href() { return _get_href(this); }
  static String _get_href(var _this) native;

  MediaList get media() { return _get_media(this); }
  static MediaList _get_media(var _this) native;

  Node get ownerNode() { return _get_ownerNode(this); }
  static Node _get_ownerNode(var _this) native;

  StyleSheet get parentStyleSheet() { return _get_parentStyleSheet(this); }
  static StyleSheet _get_parentStyleSheet(var _this) native;

  String get title() { return _get_title(this); }
  static String _get_title(var _this) native;

  String get type() { return _get_type(this); }
  static String _get_type(var _this) native;

  String get typeName() { return "StyleSheet"; }
}
