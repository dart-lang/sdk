
class _XPathEvaluatorImpl extends _DOMTypeBase implements XPathEvaluator {
  _XPathEvaluatorImpl._wrap(ptr) : super._wrap(ptr);

  XPathExpression createExpression(String expression, XPathNSResolver resolver) {
    return _wrap(_ptr.createExpression(_unwrap(expression), _unwrap(resolver)));
  }

  XPathNSResolver createNSResolver(Node nodeResolver) {
    return _wrap(_ptr.createNSResolver(_unwrap(nodeResolver)));
  }

  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult) {
    return _wrap(_ptr.evaluate(_unwrap(expression), _unwrap(contextNode), _unwrap(resolver), _unwrap(type), _unwrap(inResult)));
  }
}
