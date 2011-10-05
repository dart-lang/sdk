// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMFormDataWrappingImplementation extends DOMWrapperBase implements DOMFormData {
  _DOMFormDataWrappingImplementation() : super() {}

  static create__DOMFormDataWrappingImplementation() native {
    return new _DOMFormDataWrappingImplementation();
  }

  void append([String name = null, String value = null]) {
    if (name === null) {
      if (value === null) {
        _append(this);
        return;
      }
    } else {
      if (value === null) {
        _append_2(this, name);
        return;
      } else {
        _append_3(this, name, value);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _append(receiver) native;
  static void _append_2(receiver, name) native;
  static void _append_3(receiver, name, value) native;

  String get typeName() { return "DOMFormData"; }
}
