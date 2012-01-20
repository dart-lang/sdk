
class MutationRecord native "*MutationRecord" {

  NodeList get addedNodes() native "return this.addedNodes;";

  String get attributeName() native "return this.attributeName;";

  String get attributeNamespace() native "return this.attributeNamespace;";

  Node get nextSibling() native "return this.nextSibling;";

  String get oldValue() native "return this.oldValue;";

  Node get previousSibling() native "return this.previousSibling;";

  NodeList get removedNodes() native "return this.removedNodes;";

  Node get target() native "return this.target;";

  String get type() native "return this.type;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
