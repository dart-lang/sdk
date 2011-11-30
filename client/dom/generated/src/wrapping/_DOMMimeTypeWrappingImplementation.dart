// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMMimeTypeWrappingImplementation extends DOMWrapperBase implements DOMMimeType {
  _DOMMimeTypeWrappingImplementation() : super() {}

  static create__DOMMimeTypeWrappingImplementation() native {
    return new _DOMMimeTypeWrappingImplementation();
  }

  String get description() { return _get_description(this); }
  static String _get_description(var _this) native;

  DOMPlugin get enabledPlugin() { return _get_enabledPlugin(this); }
  static DOMPlugin _get_enabledPlugin(var _this) native;

  String get suffixes() { return _get_suffixes(this); }
  static String _get_suffixes(var _this) native;

  String get type() { return _get_type(this); }
  static String _get_type(var _this) native;

  String get typeName() { return "DOMMimeType"; }
}
