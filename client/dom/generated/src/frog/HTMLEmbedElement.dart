
class _HTMLEmbedElementJs extends _HTMLElementJs implements HTMLEmbedElement native "*HTMLEmbedElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get height() native "return this.height;";

  void set height(String value) native "this.height = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";

  _SVGDocumentJs getSVGDocument() native;
}
