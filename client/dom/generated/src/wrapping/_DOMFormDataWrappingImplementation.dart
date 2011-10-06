// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMFormDataWrappingImplementation extends DOMWrapperBase implements DOMFormData {
  _DOMFormDataWrappingImplementation() : super() {}

  static create__DOMFormDataWrappingImplementation() native {
    return new _DOMFormDataWrappingImplementation();
  }

  void append(String name, String value) {
    _append(this, name, value);
    return;
  }
  static void _append(receiver, name, value) native;

  String get typeName() { return "DOMFormData"; }
}
