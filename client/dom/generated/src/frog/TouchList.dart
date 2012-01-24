
class TouchListJS implements TouchList native "*TouchList" {

  int get length() native "return this.length;";

  TouchJS operator[](int index) native;

  void operator[]=(int index, TouchJS value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  TouchJS item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
