
class _CompositionEventImpl extends _UIEventImpl implements CompositionEvent native "*CompositionEvent" {

  final String data;

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, _WindowImpl viewArg, String dataArg) native;
}
