
class _MutationEventJs extends _EventJs implements MutationEvent native "*MutationEvent" {

  static final int ADDITION = 2;

  static final int MODIFICATION = 1;

  static final int REMOVAL = 3;

  final int attrChange;

  final String attrName;

  final String newValue;

  final String prevValue;

  final _NodeJs relatedNode;

  void initMutationEvent(String type, bool canBubble, bool cancelable, _NodeJs relatedNode, String prevValue, String newValue, String attrName, int attrChange) native;
}
