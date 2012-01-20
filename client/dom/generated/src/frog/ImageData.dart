
class ImageData native "*ImageData" {

  CanvasPixelArray get data() native "return this.data;";

  int get height() native "return this.height;";

  int get width() native "return this.width;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
