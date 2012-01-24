
class ScreenJs extends DOMTypeJs implements Screen native "*Screen" {

  int get availHeight() native "return this.availHeight;";

  int get availLeft() native "return this.availLeft;";

  int get availTop() native "return this.availTop;";

  int get availWidth() native "return this.availWidth;";

  int get colorDepth() native "return this.colorDepth;";

  int get height() native "return this.height;";

  int get pixelDepth() native "return this.pixelDepth;";

  int get width() native "return this.width;";
}
