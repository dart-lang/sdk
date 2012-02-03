
class _CompositionEventJs extends _UIEventJs implements CompositionEvent native "*CompositionEvent" {

  String get data() native "return this.data;";

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, _DOMWindowJs viewArg, String dataArg) native;
}
