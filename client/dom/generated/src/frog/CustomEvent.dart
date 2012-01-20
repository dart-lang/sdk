
class CustomEvent extends Event native "*CustomEvent" {

  Object get detail() native "return this.detail;";

  void initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) native;
}
