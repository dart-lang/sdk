
class CustomEvent extends Event native "*CustomEvent" {

  Object detail;

  void initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) native;
}
