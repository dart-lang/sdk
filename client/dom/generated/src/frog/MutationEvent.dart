
class MutationEventJS extends EventJS implements MutationEvent native "*MutationEvent" {

  static final int ADDITION = 2;

  static final int MODIFICATION = 1;

  static final int REMOVAL = 3;

  int get attrChange() native "return this.attrChange;";

  String get attrName() native "return this.attrName;";

  String get newValue() native "return this.newValue;";

  String get prevValue() native "return this.prevValue;";

  NodeJS get relatedNode() native "return this.relatedNode;";

  void initMutationEvent(String type, bool canBubble, bool cancelable, NodeJS relatedNode, String prevValue, String newValue, String attrName, int attrChange) native;
}
