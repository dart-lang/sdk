// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _UIEventWrappingImplementation extends _EventWrappingImplementation implements UIEvent {
  _UIEventWrappingImplementation() : super() {}

  static create__UIEventWrappingImplementation() native {
    return new _UIEventWrappingImplementation();
  }

  int get charCode() { return _get__UIEvent_charCode(this); }
  static int _get__UIEvent_charCode(var _this) native;

  int get detail() { return _get__UIEvent_detail(this); }
  static int _get__UIEvent_detail(var _this) native;

  int get keyCode() { return _get__UIEvent_keyCode(this); }
  static int _get__UIEvent_keyCode(var _this) native;

  int get layerX() { return _get__UIEvent_layerX(this); }
  static int _get__UIEvent_layerX(var _this) native;

  int get layerY() { return _get__UIEvent_layerY(this); }
  static int _get__UIEvent_layerY(var _this) native;

  int get pageX() { return _get__UIEvent_pageX(this); }
  static int _get__UIEvent_pageX(var _this) native;

  int get pageY() { return _get__UIEvent_pageY(this); }
  static int _get__UIEvent_pageY(var _this) native;

  DOMWindow get view() { return _get__UIEvent_view(this); }
  static DOMWindow _get__UIEvent_view(var _this) native;

  int get which() { return _get__UIEvent_which(this); }
  static int _get__UIEvent_which(var _this) native;

  void initUIEvent(String type = null, bool canBubble = null, bool cancelable = null, DOMWindow view = null, int detail = null) {
    if (type === null) {
      if (canBubble === null) {
        if (cancelable === null) {
          if (view === null) {
            if (detail === null) {
              _initUIEvent(this);
              return;
            }
          }
        }
      }
    } else {
      if (canBubble === null) {
        if (cancelable === null) {
          if (view === null) {
            if (detail === null) {
              _initUIEvent_2(this, type);
              return;
            }
          }
        }
      } else {
        if (cancelable === null) {
          if (view === null) {
            if (detail === null) {
              _initUIEvent_3(this, type, canBubble);
              return;
            }
          }
        } else {
          if (view === null) {
            if (detail === null) {
              _initUIEvent_4(this, type, canBubble, cancelable);
              return;
            }
          } else {
            if (detail === null) {
              _initUIEvent_5(this, type, canBubble, cancelable, view);
              return;
            } else {
              _initUIEvent_6(this, type, canBubble, cancelable, view, detail);
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initUIEvent(receiver) native;
  static void _initUIEvent_2(receiver, type) native;
  static void _initUIEvent_3(receiver, type, canBubble) native;
  static void _initUIEvent_4(receiver, type, canBubble, cancelable) native;
  static void _initUIEvent_5(receiver, type, canBubble, cancelable, view) native;
  static void _initUIEvent_6(receiver, type, canBubble, cancelable, view, detail) native;

  String get typeName() { return "UIEvent"; }
}
