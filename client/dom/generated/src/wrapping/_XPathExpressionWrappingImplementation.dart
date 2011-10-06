// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XPathExpressionWrappingImplementation extends DOMWrapperBase implements XPathExpression {
  _XPathExpressionWrappingImplementation() : super() {}

  static create__XPathExpressionWrappingImplementation() native {
    return new _XPathExpressionWrappingImplementation();
  }

  XPathResult evaluate(Node contextNode, int type, XPathResult inResult) {
    return _evaluate(this, contextNode, type, inResult);
  }
  static XPathResult _evaluate(receiver, contextNode, type, inResult) native;

  String get typeName() { return "XPathExpression"; }
}
