
class _CompositionEventJs extends _UIEventJs implements CompositionEvent native "*CompositionEvent" {

  final String data;

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, _DOMWindowJs viewArg, String dataArg) native;
}
