
class HTMLIFrameElementJs extends HTMLElementJs implements HTMLIFrameElement native "*HTMLIFrameElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  DocumentJs get contentDocument() native "return this.contentDocument;";

  DOMWindowJs get contentWindow() native "return this.contentWindow;";

  String get frameBorder() native "return this.frameBorder;";

  void set frameBorder(String value) native "this.frameBorder = value;";

  String get height() native "return this.height;";

  void set height(String value) native "this.height = value;";

  String get longDesc() native "return this.longDesc;";

  void set longDesc(String value) native "this.longDesc = value;";

  String get marginHeight() native "return this.marginHeight;";

  void set marginHeight(String value) native "this.marginHeight = value;";

  String get marginWidth() native "return this.marginWidth;";

  void set marginWidth(String value) native "this.marginWidth = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get sandbox() native "return this.sandbox;";

  void set sandbox(String value) native "this.sandbox = value;";

  String get scrolling() native "return this.scrolling;";

  void set scrolling(String value) native "this.scrolling = value;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";

  SVGDocumentJs getSVGDocument() native;
}
