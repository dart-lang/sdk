
class TouchList native "*TouchList" {

  int length;

  Touch operator[](int index) native;

  void operator[]=(int index, Touch value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  Touch item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
