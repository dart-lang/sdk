
class HTMLFrameElementJs extends HTMLElementJs implements HTMLFrameElement native "*HTMLFrameElement" {

  DocumentJs get contentDocument() native "return this.contentDocument;";

  DOMWindowJs get contentWindow() native "return this.contentWindow;";

  String get frameBorder() native "return this.frameBorder;";

  void set frameBorder(String value) native "this.frameBorder = value;";

  int get height() native "return this.height;";

  String get location() native "return this.location;";

  void set location(String value) native "this.location = value;";

  String get longDesc() native "return this.longDesc;";

  void set longDesc(String value) native "this.longDesc = value;";

  String get marginHeight() native "return this.marginHeight;";

  void set marginHeight(String value) native "this.marginHeight = value;";

  String get marginWidth() native "return this.marginWidth;";

  void set marginWidth(String value) native "this.marginWidth = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  bool get noResize() native "return this.noResize;";

  void set noResize(bool value) native "this.noResize = value;";

  String get scrolling() native "return this.scrolling;";

  void set scrolling(String value) native "this.scrolling = value;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  int get width() native "return this.width;";

  SVGDocumentJs getSVGDocument() native;
}
