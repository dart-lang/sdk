
class HTMLPreElementJs extends HTMLElementJs implements HTMLPreElement native "*HTMLPreElement" {

  int get width() native "return this.width;";

  void set width(int value) native "this.width = value;";

  bool get wrap() native "return this.wrap;";

  void set wrap(bool value) native "this.wrap = value;";
}
