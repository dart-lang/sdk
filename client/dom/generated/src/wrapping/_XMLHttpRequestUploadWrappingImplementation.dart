// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XMLHttpRequestUploadWrappingImplementation extends DOMWrapperBase implements XMLHttpRequestUpload {
  _XMLHttpRequestUploadWrappingImplementation() : super() {}

  static create__XMLHttpRequestUploadWrappingImplementation() native {
    return new _XMLHttpRequestUploadWrappingImplementation();
  }

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _addEventListener_XMLHttpRequestUpload(this, type, listener);
      return;
    } else {
      _addEventListener_XMLHttpRequestUpload_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _addEventListener_XMLHttpRequestUpload(receiver, type, listener) native;
  static void _addEventListener_XMLHttpRequestUpload_2(receiver, type, listener, useCapture) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent_XMLHttpRequestUpload(this, evt);
  }
  static bool _dispatchEvent_XMLHttpRequestUpload(receiver, evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _removeEventListener_XMLHttpRequestUpload(this, type, listener);
      return;
    } else {
      _removeEventListener_XMLHttpRequestUpload_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _removeEventListener_XMLHttpRequestUpload(receiver, type, listener) native;
  static void _removeEventListener_XMLHttpRequestUpload_2(receiver, type, listener, useCapture) native;

  String get typeName() { return "XMLHttpRequestUpload"; }
}
