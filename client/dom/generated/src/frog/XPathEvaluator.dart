
class XPathEvaluatorJs extends DOMTypeJs implements XPathEvaluator native "*XPathEvaluator" {

  XPathExpressionJs createExpression(String expression, XPathNSResolverJs resolver) native;

  XPathNSResolverJs createNSResolver(NodeJs nodeResolver) native;

  XPathResultJs evaluate(String expression, NodeJs contextNode, XPathNSResolverJs resolver, int type, XPathResultJs inResult) native;
}
