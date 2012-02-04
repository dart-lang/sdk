
class _TextEventJs extends _UIEventJs implements TextEvent native "*TextEvent" {

  final String data;

  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, _DOMWindowJs viewArg, String dataArg) native;
}
