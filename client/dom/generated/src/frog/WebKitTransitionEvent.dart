
class WebKitTransitionEvent extends Event native "WebKitTransitionEvent" {

  num elapsedTime;

  String propertyName;

  void initWebKitTransitionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String propertyNameArg, num elapsedTimeArg) native;
}
