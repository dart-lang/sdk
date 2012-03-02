
class _SVGLengthListImpl implements SVGLengthList native "*SVGLengthList" {

  final int numberOfItems;

  _SVGLengthImpl appendItem(_SVGLengthImpl item) native;

  void clear() native;

  _SVGLengthImpl getItem(int index) native;

  _SVGLengthImpl initialize(_SVGLengthImpl item) native;

  _SVGLengthImpl insertItemBefore(_SVGLengthImpl item, int index) native;

  _SVGLengthImpl removeItem(int index) native;

  _SVGLengthImpl replaceItem(_SVGLengthImpl item, int index) native;
}
