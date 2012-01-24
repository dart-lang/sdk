
class NodeIteratorJS implements NodeIterator native "*NodeIterator" {

  bool get expandEntityReferences() native "return this.expandEntityReferences;";

  NodeFilterJS get filter() native "return this.filter;";

  bool get pointerBeforeReferenceNode() native "return this.pointerBeforeReferenceNode;";

  NodeJS get referenceNode() native "return this.referenceNode;";

  NodeJS get root() native "return this.root;";

  int get whatToShow() native "return this.whatToShow;";

  void detach() native;

  NodeJS nextNode() native;

  NodeJS previousNode() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
