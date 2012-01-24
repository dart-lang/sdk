
class TextEventJs extends UIEventJs implements TextEvent native "*TextEvent" {

  String get data() native "return this.data;";

  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindowJs viewArg, String dataArg) native;
}
