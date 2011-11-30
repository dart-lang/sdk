// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ElementTimeControlWrappingImplementation extends DOMWrapperBase implements ElementTimeControl {
  _ElementTimeControlWrappingImplementation() : super() {}

  static create__ElementTimeControlWrappingImplementation() native {
    return new _ElementTimeControlWrappingImplementation();
  }

  void beginElement() {
    _beginElement(this);
    return;
  }
  static void _beginElement(receiver) native;

  void beginElementAt(num offset) {
    _beginElementAt(this, offset);
    return;
  }
  static void _beginElementAt(receiver, offset) native;

  void endElement() {
    _endElement(this);
    return;
  }
  static void _endElement(receiver) native;

  void endElementAt(num offset) {
    _endElementAt(this, offset);
    return;
  }
  static void _endElementAt(receiver, offset) native;

  String get typeName() { return "ElementTimeControl"; }
}
