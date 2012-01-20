
class NodeIterator native "*NodeIterator" {

  bool get expandEntityReferences() native "return this.expandEntityReferences;";

  NodeFilter get filter() native "return this.filter;";

  bool get pointerBeforeReferenceNode() native "return this.pointerBeforeReferenceNode;";

  Node get referenceNode() native "return this.referenceNode;";

  Node get root() native "return this.root;";

  int get whatToShow() native "return this.whatToShow;";

  void detach() native;

  Node nextNode() native;

  Node previousNode() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
