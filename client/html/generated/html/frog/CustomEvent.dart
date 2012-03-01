
class _CustomEventImpl extends _EventImpl implements CustomEvent native "*CustomEvent" {

  final Object detail;

  void initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) native;
}
