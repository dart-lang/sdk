
class _XPathExpressionImpl extends _DOMTypeBase implements XPathExpression {
  _XPathExpressionImpl._wrap(ptr) : super._wrap(ptr);

  XPathResult evaluate(Node contextNode, int type, XPathResult inResult) {
    return _wrap(_ptr.evaluate(_unwrap(contextNode), _unwrap(type), _unwrap(inResult)));
  }
}
