
class XPathEvaluatorJS implements XPathEvaluator native "*XPathEvaluator" {

  XPathExpressionJS createExpression(String expression, XPathNSResolverJS resolver) native;

  XPathNSResolverJS createNSResolver(NodeJS nodeResolver) native;

  XPathResultJS evaluate(String expression, NodeJS contextNode, XPathNSResolverJS resolver, int type, XPathResultJS inResult) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
