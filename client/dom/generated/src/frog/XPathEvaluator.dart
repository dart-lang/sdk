
class XPathEvaluator native "*XPathEvaluator" {

  XPathExpression createExpression(String expression, XPathNSResolver resolver) native;

  XPathNSResolver createNSResolver(Node nodeResolver) native;

  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
