
class ClientRectList native "*ClientRectList" {

  int length;

  ClientRect item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
