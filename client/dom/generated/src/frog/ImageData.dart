
class _ImageDataJs extends _DOMTypeJs implements ImageData native "*ImageData" {

  _CanvasPixelArrayJs get data() native "return this.data;";

  int get height() native "return this.height;";

  int get width() native "return this.width;";
}
