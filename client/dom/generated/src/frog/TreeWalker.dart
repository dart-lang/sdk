
class TreeWalkerJS implements TreeWalker native "*TreeWalker" {

  NodeJS get currentNode() native "return this.currentNode;";

  void set currentNode(NodeJS value) native "this.currentNode = value;";

  bool get expandEntityReferences() native "return this.expandEntityReferences;";

  NodeFilterJS get filter() native "return this.filter;";

  NodeJS get root() native "return this.root;";

  int get whatToShow() native "return this.whatToShow;";

  NodeJS firstChild() native;

  NodeJS lastChild() native;

  NodeJS nextNode() native;

  NodeJS nextSibling() native;

  NodeJS parentNode() native;

  NodeJS previousNode() native;

  NodeJS previousSibling() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
