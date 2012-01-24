
class KeyboardEventJS extends UIEventJS implements KeyboardEvent native "*KeyboardEvent" {

  bool get altGraphKey() native "return this.altGraphKey;";

  bool get altKey() native "return this.altKey;";

  bool get ctrlKey() native "return this.ctrlKey;";

  String get keyIdentifier() native "return this.keyIdentifier;";

  int get keyLocation() native "return this.keyLocation;";

  bool get metaKey() native "return this.metaKey;";

  bool get shiftKey() native "return this.shiftKey;";

  void initKeyboardEvent(String type, bool canBubble, bool cancelable, DOMWindowJS view, String keyIdentifier, int keyLocation, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool altGraphKey) native;
}
