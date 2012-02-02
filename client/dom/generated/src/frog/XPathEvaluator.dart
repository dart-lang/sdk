
class _XPathEvaluatorJs extends _DOMTypeJs implements XPathEvaluator native "*XPathEvaluator" {

  _XPathExpressionJs createExpression(String expression, _XPathNSResolverJs resolver) native;

  _XPathNSResolverJs createNSResolver(_NodeJs nodeResolver) native;

  _XPathResultJs evaluate(String expression, _NodeJs contextNode, _XPathNSResolverJs resolver, int type, _XPathResultJs inResult) native;
}
