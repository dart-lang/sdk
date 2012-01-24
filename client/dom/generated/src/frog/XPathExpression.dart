
class XPathExpressionJS implements XPathExpression native "*XPathExpression" {

  XPathResultJS evaluate(NodeJS contextNode, int type, XPathResultJS inResult) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
