
class PopStateEvent extends Event native "PopStateEvent" {

  Object state;

  void initPopStateEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object stateArg) native;
}
