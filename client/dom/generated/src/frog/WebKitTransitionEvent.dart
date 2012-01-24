
class WebKitTransitionEventJS extends EventJS implements WebKitTransitionEvent native "*WebKitTransitionEvent" {

  num get elapsedTime() native "return this.elapsedTime;";

  String get propertyName() native "return this.propertyName;";
}
