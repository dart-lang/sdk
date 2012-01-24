
class CompositionEventJS extends UIEventJS implements CompositionEvent native "*CompositionEvent" {

  String get data() native "return this.data;";

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindowJS viewArg, String dataArg) native;
}
