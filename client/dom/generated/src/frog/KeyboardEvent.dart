
class KeyboardEvent extends UIEvent native "KeyboardEvent" {

  bool altGraphKey;

  bool altKey;

  bool ctrlKey;

  String keyIdentifier;

  int keyLocation;

  bool metaKey;

  bool shiftKey;

  bool getModifierState(String keyIdentifierArg) native;

  void initKeyboardEvent(String type, bool canBubble, bool cancelable, DOMWindow view, String keyIdentifier, int keyLocation, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool altGraphKey) native;
}
