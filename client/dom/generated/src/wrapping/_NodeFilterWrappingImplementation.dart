// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _NodeFilterWrappingImplementation extends DOMWrapperBase implements NodeFilter {
  _NodeFilterWrappingImplementation() : super() {}

  static create__NodeFilterWrappingImplementation() native {
    return new _NodeFilterWrappingImplementation();
  }

  int acceptNode(Node n) {
    return _acceptNode(this, n);
  }
  static int _acceptNode(receiver, n) native;

  String get typeName() { return "NodeFilter"; }
}
