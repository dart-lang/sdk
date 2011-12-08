
class CanvasPixelArray native "*CanvasPixelArray" {

  int length;

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
