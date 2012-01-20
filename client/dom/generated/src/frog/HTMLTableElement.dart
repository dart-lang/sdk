
class HTMLTableElement extends HTMLElement native "*HTMLTableElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get bgColor() native "return this.bgColor;";

  void set bgColor(String value) native "this.bgColor = value;";

  String get border() native "return this.border;";

  void set border(String value) native "this.border = value;";

  HTMLTableCaptionElement get caption() native "return this.caption;";

  void set caption(HTMLTableCaptionElement value) native "this.caption = value;";

  String get cellPadding() native "return this.cellPadding;";

  void set cellPadding(String value) native "this.cellPadding = value;";

  String get cellSpacing() native "return this.cellSpacing;";

  void set cellSpacing(String value) native "this.cellSpacing = value;";

  String get frame() native "return this.frame;";

  void set frame(String value) native "this.frame = value;";

  HTMLCollection get rows() native "return this.rows;";

  String get rules() native "return this.rules;";

  void set rules(String value) native "this.rules = value;";

  String get summary() native "return this.summary;";

  void set summary(String value) native "this.summary = value;";

  HTMLCollection get tBodies() native "return this.tBodies;";

  HTMLTableSectionElement get tFoot() native "return this.tFoot;";

  void set tFoot(HTMLTableSectionElement value) native "this.tFoot = value;";

  HTMLTableSectionElement get tHead() native "return this.tHead;";

  void set tHead(HTMLTableSectionElement value) native "this.tHead = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";

  HTMLElement createCaption() native;

  HTMLElement createTFoot() native;

  HTMLElement createTHead() native;

  void deleteCaption() native;

  void deleteRow(int index) native;

  void deleteTFoot() native;

  void deleteTHead() native;

  HTMLElement insertRow(int index) native;
}
