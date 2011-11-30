
class WebKitLoseContext native "*WebKitLoseContext" {

  void loseContext() native;

  void restoreContext() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
