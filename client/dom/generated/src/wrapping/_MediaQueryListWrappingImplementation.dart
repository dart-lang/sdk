// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MediaQueryListWrappingImplementation extends DOMWrapperBase implements MediaQueryList {
  _MediaQueryListWrappingImplementation() : super() {}

  static create__MediaQueryListWrappingImplementation() native {
    return new _MediaQueryListWrappingImplementation();
  }

  bool get matches() { return _get__MediaQueryList_matches(this); }
  static bool _get__MediaQueryList_matches(var _this) native;

  String get media() { return _get__MediaQueryList_media(this); }
  static String _get__MediaQueryList_media(var _this) native;

  void addListener(MediaQueryListListener listener) {
    _addListener(this, listener);
    return;
  }
  static void _addListener(receiver, listener) native;

  void removeListener(MediaQueryListListener listener) {
    _removeListener(this, listener);
    return;
  }
  static void _removeListener(receiver, listener) native;

  String get typeName() { return "MediaQueryList"; }
}
