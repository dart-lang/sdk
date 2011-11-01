
class XPathExpression native "XPathExpression" {

  XPathResult evaluate(Node contextNode, int type, XPathResult inResult) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
