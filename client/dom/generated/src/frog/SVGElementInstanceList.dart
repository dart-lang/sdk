
class SVGElementInstanceListJs extends DOMTypeJs implements SVGElementInstanceList native "*SVGElementInstanceList" {

  int get length() native "return this.length;";

  SVGElementInstanceJs item(int index) native;
}
