
class WebKitAnimationList native "*WebKitAnimationList" {

  int length;

  WebKitAnimation item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
