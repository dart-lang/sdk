
class _MutationRecordJs extends _DOMTypeJs implements MutationRecord native "*MutationRecord" {

  _NodeListJs get addedNodes() native "return this.addedNodes;";

  String get attributeName() native "return this.attributeName;";

  String get attributeNamespace() native "return this.attributeNamespace;";

  _NodeJs get nextSibling() native "return this.nextSibling;";

  String get oldValue() native "return this.oldValue;";

  _NodeJs get previousSibling() native "return this.previousSibling;";

  _NodeListJs get removedNodes() native "return this.removedNodes;";

  _NodeJs get target() native "return this.target;";

  String get type() native "return this.type;";
}
