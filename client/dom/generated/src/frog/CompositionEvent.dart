
class CompositionEvent extends UIEvent native "CompositionEvent" {

  String data;

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindow viewArg, String dataArg) native;
}
