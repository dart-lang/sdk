
class HTMLCanvasElementJs extends HTMLElementJs implements HTMLCanvasElement native "*HTMLCanvasElement" {

  int get height() native "return this.height;";

  void set height(int value) native "this.height = value;";

  int get width() native "return this.width;";

  void set width(int value) native "this.width = value;";

  Object getContext(String contextId) native;

  String toDataURL(String type) native;
}
