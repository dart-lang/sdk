
class _IFrameElementImpl extends _ElementImpl implements IFrameElement native "*HTMLIFrameElement" {

  String align;

  _DocumentImpl get contentDocument() => _FixHtmlDocumentReference(_contentDocument);

  _EventTargetImpl get _contentDocument() native "return this.contentDocument;";

  final _WindowImpl contentWindow;

  String frameBorder;

  String height;

  String longDesc;

  String marginHeight;

  String marginWidth;

  String name;

  String sandbox;

  String scrolling;

  String src;

  String width;

  _SVGDocumentImpl getSVGDocument() native;
}
