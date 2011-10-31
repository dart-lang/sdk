
class CanvasPixelArray native "CanvasPixelArray" {

  int length;

  int operator[](int index) native;

  int item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
