
class MutationEvent extends Event native "MutationEvent" {

  int attrChange;

  String attrName;

  String newValue;

  String prevValue;

  Node relatedNode;

  void initMutationEvent(String type, bool canBubble, bool cancelable, Node relatedNode, String prevValue, String newValue, String attrName, int attrChange) native;
}
