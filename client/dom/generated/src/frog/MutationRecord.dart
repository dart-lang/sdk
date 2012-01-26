
class MutationRecordJs extends DOMTypeJs implements MutationRecord native "*MutationRecord" {

  NodeListJs get addedNodes() native "return this.addedNodes;";

  String get attributeName() native "return this.attributeName;";

  String get attributeNamespace() native "return this.attributeNamespace;";

  NodeJs get nextSibling() native "return this.nextSibling;";

  String get oldValue() native "return this.oldValue;";

  NodeJs get previousSibling() native "return this.previousSibling;";

  NodeListJs get removedNodes() native "return this.removedNodes;";

  NodeJs get target() native "return this.target;";

  String get type() native "return this.type;";
}
