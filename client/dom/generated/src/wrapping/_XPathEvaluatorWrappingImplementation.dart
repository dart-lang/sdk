// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XPathEvaluatorWrappingImplementation extends DOMWrapperBase implements XPathEvaluator {
  _XPathEvaluatorWrappingImplementation() : super() {}

  static create__XPathEvaluatorWrappingImplementation() native {
    return new _XPathEvaluatorWrappingImplementation();
  }

  XPathExpression createExpression(String expression, XPathNSResolver resolver) {
    return _createExpression(this, expression, resolver);
  }
  static XPathExpression _createExpression(receiver, expression, resolver) native;

  XPathNSResolver createNSResolver(Node nodeResolver) {
    return _createNSResolver(this, nodeResolver);
  }
  static XPathNSResolver _createNSResolver(receiver, nodeResolver) native;

  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult) {
    return _evaluate(this, expression, contextNode, resolver, type, inResult);
  }
  static XPathResult _evaluate(receiver, expression, contextNode, resolver, type, inResult) native;

  String get typeName() { return "XPathEvaluator"; }
}
