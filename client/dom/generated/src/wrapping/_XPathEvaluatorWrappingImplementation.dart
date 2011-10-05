// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XPathEvaluatorWrappingImplementation extends DOMWrapperBase implements XPathEvaluator {
  _XPathEvaluatorWrappingImplementation() : super() {}

  static create__XPathEvaluatorWrappingImplementation() native {
    return new _XPathEvaluatorWrappingImplementation();
  }

  XPathExpression createExpression(String expression = null, XPathNSResolver resolver = null) {
    if (expression === null) {
      if (resolver === null) {
        return _createExpression(this);
      }
    } else {
      if (resolver === null) {
        return _createExpression_2(this, expression);
      } else {
        return _createExpression_3(this, expression, resolver);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static XPathExpression _createExpression(receiver) native;
  static XPathExpression _createExpression_2(receiver, expression) native;
  static XPathExpression _createExpression_3(receiver, expression, resolver) native;

  XPathNSResolver createNSResolver(Node nodeResolver = null) {
    if (nodeResolver === null) {
      return _createNSResolver(this);
    } else {
      return _createNSResolver_2(this, nodeResolver);
    }
  }
  static XPathNSResolver _createNSResolver(receiver) native;
  static XPathNSResolver _createNSResolver_2(receiver, nodeResolver) native;

  XPathResult evaluate(String expression = null, Node contextNode = null, XPathNSResolver resolver = null, int type = null, XPathResult inResult = null) {
    if (expression === null) {
      if (contextNode === null) {
        if (resolver === null) {
          if (type === null) {
            if (inResult === null) {
              return _evaluate(this);
            }
          }
        }
      }
    } else {
      if (contextNode === null) {
        if (resolver === null) {
          if (type === null) {
            if (inResult === null) {
              return _evaluate_2(this, expression);
            }
          }
        }
      } else {
        if (resolver === null) {
          if (type === null) {
            if (inResult === null) {
              return _evaluate_3(this, expression, contextNode);
            }
          }
        } else {
          if (type === null) {
            if (inResult === null) {
              return _evaluate_4(this, expression, contextNode, resolver);
            }
          } else {
            if (inResult === null) {
              return _evaluate_5(this, expression, contextNode, resolver, type);
            } else {
              return _evaluate_6(this, expression, contextNode, resolver, type, inResult);
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static XPathResult _evaluate(receiver) native;
  static XPathResult _evaluate_2(receiver, expression) native;
  static XPathResult _evaluate_3(receiver, expression, contextNode) native;
  static XPathResult _evaluate_4(receiver, expression, contextNode, resolver) native;
  static XPathResult _evaluate_5(receiver, expression, contextNode, resolver, type) native;
  static XPathResult _evaluate_6(receiver, expression, contextNode, resolver, type, inResult) native;

  String get typeName() { return "XPathEvaluator"; }
}
