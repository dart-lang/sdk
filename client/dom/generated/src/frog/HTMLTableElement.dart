
class HTMLTableElementJS extends HTMLElementJS implements HTMLTableElement native "*HTMLTableElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get bgColor() native "return this.bgColor;";

  void set bgColor(String value) native "this.bgColor = value;";

  String get border() native "return this.border;";

  void set border(String value) native "this.border = value;";

  HTMLTableCaptionElementJS get caption() native "return this.caption;";

  void set caption(HTMLTableCaptionElementJS value) native "this.caption = value;";

  String get cellPadding() native "return this.cellPadding;";

  void set cellPadding(String value) native "this.cellPadding = value;";

  String get cellSpacing() native "return this.cellSpacing;";

  void set cellSpacing(String value) native "this.cellSpacing = value;";

  String get frame() native "return this.frame;";

  void set frame(String value) native "this.frame = value;";

  HTMLCollectionJS get rows() native "return this.rows;";

  String get rules() native "return this.rules;";

  void set rules(String value) native "this.rules = value;";

  String get summary() native "return this.summary;";

  void set summary(String value) native "this.summary = value;";

  HTMLCollectionJS get tBodies() native "return this.tBodies;";

  HTMLTableSectionElementJS get tFoot() native "return this.tFoot;";

  void set tFoot(HTMLTableSectionElementJS value) native "this.tFoot = value;";

  HTMLTableSectionElementJS get tHead() native "return this.tHead;";

  void set tHead(HTMLTableSectionElementJS value) native "this.tHead = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";

  HTMLElementJS createCaption() native;

  HTMLElementJS createTFoot() native;

  HTMLElementJS createTHead() native;

  void deleteCaption() native;

  void deleteRow(int index) native;

  void deleteTFoot() native;

  void deleteTHead() native;

  HTMLElementJS insertRow(int index) native;
}
