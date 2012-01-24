
class CanvasPixelArrayJS implements CanvasPixelArray native "*CanvasPixelArray" {

  int get length() native "return this.length;";

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
