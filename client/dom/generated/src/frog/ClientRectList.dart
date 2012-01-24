
class ClientRectListJS implements ClientRectList native "*ClientRectList" {

  int get length() native "return this.length;";

  ClientRectJS item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
