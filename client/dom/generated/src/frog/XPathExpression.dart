
class XPathExpressionJs extends DOMTypeJs implements XPathExpression native "*XPathExpression" {

  XPathResultJs evaluate(NodeJs contextNode, int type, XPathResultJs inResult) native;
}
