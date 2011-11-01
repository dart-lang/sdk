
class TouchList native "TouchList" {

  int length;

  Touch operator[](int index) native;

  Touch item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
