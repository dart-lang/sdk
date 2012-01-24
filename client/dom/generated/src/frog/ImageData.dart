
class ImageDataJS implements ImageData native "*ImageData" {

  CanvasPixelArrayJS get data() native "return this.data;";

  int get height() native "return this.height;";

  int get width() native "return this.width;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
