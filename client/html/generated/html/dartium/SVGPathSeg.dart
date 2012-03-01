
class _SVGPathSegImpl extends _DOMTypeBase implements SVGPathSeg {
  _SVGPathSegImpl._wrap(ptr) : super._wrap(ptr);

  int get pathSegType() => _wrap(_ptr.pathSegType);

  String get pathSegTypeAsLetter() => _wrap(_ptr.pathSegTypeAsLetter);
}
