// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XPathExpressionWrappingImplementation extends DOMWrapperBase implements XPathExpression {
  _XPathExpressionWrappingImplementation() : super() {}

  static create__XPathExpressionWrappingImplementation() native {
    return new _XPathExpressionWrappingImplementation();
  }

  XPathResult evaluate([Node contextNode = null, int type = null, XPathResult inResult = null]) {
    if (contextNode === null) {
      if (type === null) {
        if (inResult === null) {
          return _evaluate(this);
        }
      }
    } else {
      if (type === null) {
        if (inResult === null) {
          return _evaluate_2(this, contextNode);
        }
      } else {
        if (inResult === null) {
          return _evaluate_3(this, contextNode, type);
        } else {
          return _evaluate_4(this, contextNode, type, inResult);
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static XPathResult _evaluate(receiver) native;
  static XPathResult _evaluate_2(receiver, contextNode) native;
  static XPathResult _evaluate_3(receiver, contextNode, type) native;
  static XPathResult _evaluate_4(receiver, contextNode, type, inResult) native;

  String get typeName() { return "XPathExpression"; }
}
