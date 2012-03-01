
class _XPathEvaluatorImpl implements XPathEvaluator native "*XPathEvaluator" {

  _XPathExpressionImpl createExpression(String expression, _XPathNSResolverImpl resolver) native;

  _XPathNSResolverImpl createNSResolver(_NodeImpl nodeResolver) native;

  _XPathResultImpl evaluate(String expression, _NodeImpl contextNode, _XPathNSResolverImpl resolver, int type, _XPathResultImpl inResult) native;
}
