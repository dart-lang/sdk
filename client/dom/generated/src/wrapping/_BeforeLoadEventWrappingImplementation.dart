// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _BeforeLoadEventWrappingImplementation extends _EventWrappingImplementation implements BeforeLoadEvent {
  _BeforeLoadEventWrappingImplementation() : super() {}

  static create__BeforeLoadEventWrappingImplementation() native {
    return new _BeforeLoadEventWrappingImplementation();
  }

  String get url() { return _get__BeforeLoadEvent_url(this); }
  static String _get__BeforeLoadEvent_url(var _this) native;

  void initBeforeLoadEvent([String type = null, bool canBubble = null, bool cancelable = null, String url = null]) {
    if (type === null) {
      if (canBubble === null) {
        if (cancelable === null) {
          if (url === null) {
            _initBeforeLoadEvent(this);
            return;
          }
        }
      }
    } else {
      if (canBubble === null) {
        if (cancelable === null) {
          if (url === null) {
            _initBeforeLoadEvent_2(this, type);
            return;
          }
        }
      } else {
        if (cancelable === null) {
          if (url === null) {
            _initBeforeLoadEvent_3(this, type, canBubble);
            return;
          }
        } else {
          if (url === null) {
            _initBeforeLoadEvent_4(this, type, canBubble, cancelable);
            return;
          } else {
            _initBeforeLoadEvent_5(this, type, canBubble, cancelable, url);
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initBeforeLoadEvent(receiver) native;
  static void _initBeforeLoadEvent_2(receiver, type) native;
  static void _initBeforeLoadEvent_3(receiver, type, canBubble) native;
  static void _initBeforeLoadEvent_4(receiver, type, canBubble, cancelable) native;
  static void _initBeforeLoadEvent_5(receiver, type, canBubble, cancelable, url) native;

  String get typeName() { return "BeforeLoadEvent"; }
}
