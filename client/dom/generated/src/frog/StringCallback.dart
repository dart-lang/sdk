
class StringCallback native "*StringCallback" {

  bool handleEvent(String data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
