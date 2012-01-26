
class CompositionEventJs extends UIEventJs implements CompositionEvent native "*CompositionEvent" {

  String get data() native "return this.data;";

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindowJs viewArg, String dataArg) native;
}
