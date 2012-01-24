
class MutationRecordJS implements MutationRecord native "*MutationRecord" {

  NodeListJS get addedNodes() native "return this.addedNodes;";

  String get attributeName() native "return this.attributeName;";

  String get attributeNamespace() native "return this.attributeNamespace;";

  NodeJS get nextSibling() native "return this.nextSibling;";

  String get oldValue() native "return this.oldValue;";

  NodeJS get previousSibling() native "return this.previousSibling;";

  NodeListJS get removedNodes() native "return this.removedNodes;";

  NodeJS get target() native "return this.target;";

  String get type() native "return this.type;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
