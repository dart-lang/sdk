
class SVGLengthListJs extends DOMTypeJs implements SVGLengthList native "*SVGLengthList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGLengthJs appendItem(SVGLengthJs item) native;

  void clear() native;

  SVGLengthJs getItem(int index) native;

  SVGLengthJs initialize(SVGLengthJs item) native;

  SVGLengthJs insertItemBefore(SVGLengthJs item, int index) native;

  SVGLengthJs removeItem(int index) native;

  SVGLengthJs replaceItem(SVGLengthJs item, int index) native;
}
