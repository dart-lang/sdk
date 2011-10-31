
class TextEvent extends UIEvent native "TextEvent" {

  String data;

  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindow viewArg, String dataArg) native;
}
