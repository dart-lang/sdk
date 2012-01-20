
class ClientRectList native "*ClientRectList" {

  int get length() native "return this.length;";

  ClientRect item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
