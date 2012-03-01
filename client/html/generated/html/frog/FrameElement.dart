
class _FrameElementImpl extends _ElementImpl implements FrameElement native "*HTMLFrameElement" {

  _DocumentImpl get contentDocument() => _FixHtmlDocumentReference(_contentDocument);

  _EventTargetImpl get _contentDocument() native "return this.contentDocument;";

  final _WindowImpl contentWindow;

  String frameBorder;

  final int height;

  String location;

  String longDesc;

  String marginHeight;

  String marginWidth;

  String name;

  bool noResize;

  String scrolling;

  String src;

  final int width;

  _SVGDocumentImpl getSVGDocument() native;
}
