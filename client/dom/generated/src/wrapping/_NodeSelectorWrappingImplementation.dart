// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _NodeSelectorWrappingImplementation extends DOMWrapperBase implements NodeSelector {
  _NodeSelectorWrappingImplementation() : super() {}

  static create__NodeSelectorWrappingImplementation() native {
    return new _NodeSelectorWrappingImplementation();
  }

  Element querySelector(String selectors) {
    return _querySelector(this, selectors);
  }
  static Element _querySelector(receiver, selectors) native;

  NodeList querySelectorAll(String selectors) {
    return _querySelectorAll(this, selectors);
  }
  static NodeList _querySelectorAll(receiver, selectors) native;

  String get typeName() { return "NodeSelector"; }
}
