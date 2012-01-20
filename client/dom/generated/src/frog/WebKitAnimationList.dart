
class WebKitAnimationList native "*WebKitAnimationList" {

  int get length() native "return this.length;";

  WebKitAnimation item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
