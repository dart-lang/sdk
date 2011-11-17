
class Event native "Event" {

  bool bubbles;

  bool cancelBubble;

  bool cancelable;

  Clipboard clipboardData;

  EventTarget currentTarget;

  bool defaultPrevented;

  int eventPhase;

  bool returnValue;

  EventTarget srcElement;

  EventTarget target;

  int timeStamp;

  String type;

  void initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) native;

  void preventDefault() native;

  void stopImmediatePropagation() native;

  void stopPropagation() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
