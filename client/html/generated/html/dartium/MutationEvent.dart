
class _MutationEventImpl extends _EventImpl implements MutationEvent {
  _MutationEventImpl._wrap(ptr) : super._wrap(ptr);

  int get attrChange() => _wrap(_ptr.attrChange);

  String get attrName() => _wrap(_ptr.attrName);

  String get newValue() => _wrap(_ptr.newValue);

  String get prevValue() => _wrap(_ptr.prevValue);

  Node get relatedNode() => _wrap(_ptr.relatedNode);

  void initMutationEvent(String type, bool canBubble, bool cancelable, Node relatedNode, String prevValue, String newValue, String attrName, int attrChange) {
    _ptr.initMutationEvent(_unwrap(type), _unwrap(canBubble), _unwrap(cancelable), _unwrap(relatedNode), _unwrap(prevValue), _unwrap(newValue), _unwrap(attrName), _unwrap(attrChange));
    return;
  }
}
