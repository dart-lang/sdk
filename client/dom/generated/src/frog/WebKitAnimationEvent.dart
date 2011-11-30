
class WebKitAnimationEvent extends Event native "*WebKitAnimationEvent" {

  String animationName;

  num elapsedTime;

  void initWebKitAnimationEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String animationNameArg, num elapsedTimeArg) native;
}
