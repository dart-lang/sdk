// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMPluginWrappingImplementation extends DOMWrapperBase implements DOMPlugin {
  _DOMPluginWrappingImplementation() : super() {}

  static create__DOMPluginWrappingImplementation() native {
    return new _DOMPluginWrappingImplementation();
  }

  String get description() { return _get_description(this); }
  static String _get_description(var _this) native;

  String get filename() { return _get_filename(this); }
  static String _get_filename(var _this) native;

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  String get name() { return _get_name(this); }
  static String _get_name(var _this) native;

  DOMMimeType item(int index) {
    return _item(this, index);
  }
  static DOMMimeType _item(receiver, index) native;

  DOMMimeType namedItem(String name) {
    return _namedItem(this, name);
  }
  static DOMMimeType _namedItem(receiver, name) native;

  String get typeName() { return "DOMPlugin"; }
}
