
class TextEventJS extends UIEventJS implements TextEvent native "*TextEvent" {

  String get data() native "return this.data;";

  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindowJS viewArg, String dataArg) native;
}
