
class _TextEventImpl extends _UIEventImpl implements TextEvent native "*TextEvent" {

  final String data;

  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, _WindowImpl viewArg, String dataArg) native;
}
