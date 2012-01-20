
class WebKitTransitionEvent extends Event native "*WebKitTransitionEvent" {

  num get elapsedTime() native "return this.elapsedTime;";

  String get propertyName() native "return this.propertyName;";
}
