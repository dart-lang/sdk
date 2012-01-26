
class WebKitAnimationEventJs extends EventJs implements WebKitAnimationEvent native "*WebKitAnimationEvent" {

  String get animationName() native "return this.animationName;";

  num get elapsedTime() native "return this.elapsedTime;";
}
