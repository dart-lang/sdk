// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HistoryWrappingImplementation extends DOMWrapperBase implements History {
  _HistoryWrappingImplementation() : super() {}

  static create__HistoryWrappingImplementation() native {
    return new _HistoryWrappingImplementation();
  }

  int get length() { return _get__History_length(this); }
  static int _get__History_length(var _this) native;

  void back() {
    _back(this);
    return;
  }
  static void _back(receiver) native;

  void forward() {
    _forward(this);
    return;
  }
  static void _forward(receiver) native;

  void go(int distance = null) {
    if (distance === null) {
      _go(this);
      return;
    } else {
      _go_2(this, distance);
      return;
    }
  }
  static void _go(receiver) native;
  static void _go_2(receiver, distance) native;

  void pushState(Object data, String title, String url = null) {
    if (url === null) {
      _pushState(this, data, title);
      return;
    } else {
      _pushState_2(this, data, title, url);
      return;
    }
  }
  static void _pushState(receiver, data, title) native;
  static void _pushState_2(receiver, data, title, url) native;

  void replaceState(Object data, String title, String url = null) {
    if (url === null) {
      _replaceState(this, data, title);
      return;
    } else {
      _replaceState_2(this, data, title, url);
      return;
    }
  }
  static void _replaceState(receiver, data, title) native;
  static void _replaceState_2(receiver, data, title, url) native;

  String get typeName() { return "History"; }
}
