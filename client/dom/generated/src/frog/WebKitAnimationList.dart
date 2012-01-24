
class WebKitAnimationListJS implements WebKitAnimationList native "*WebKitAnimationList" {

  int get length() native "return this.length;";

  WebKitAnimationJS item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
