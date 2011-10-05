// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DocumentFragmentWrappingImplementation extends _NodeWrappingImplementation implements DocumentFragment {
  _DocumentFragmentWrappingImplementation() : super() {}

  static create__DocumentFragmentWrappingImplementation() native {
    return new _DocumentFragmentWrappingImplementation();
  }

  Element querySelector(String selectors) {
    return _querySelector(this, selectors);
  }
  static Element _querySelector(receiver, selectors) native;

  NodeList querySelectorAll(String selectors) {
    return _querySelectorAll(this, selectors);
  }
  static NodeList _querySelectorAll(receiver, selectors) native;

  String get typeName() { return "DocumentFragment"; }
}
