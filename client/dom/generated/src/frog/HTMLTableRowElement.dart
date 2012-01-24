
class HTMLTableRowElementJS extends HTMLElementJS implements HTMLTableRowElement native "*HTMLTableRowElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get bgColor() native "return this.bgColor;";

  void set bgColor(String value) native "this.bgColor = value;";

  HTMLCollectionJS get cells() native "return this.cells;";

  String get ch() native "return this.ch;";

  void set ch(String value) native "this.ch = value;";

  String get chOff() native "return this.chOff;";

  void set chOff(String value) native "this.chOff = value;";

  int get rowIndex() native "return this.rowIndex;";

  int get sectionRowIndex() native "return this.sectionRowIndex;";

  String get vAlign() native "return this.vAlign;";

  void set vAlign(String value) native "this.vAlign = value;";

  void deleteCell(int index) native;

  HTMLElementJS insertCell(int index) native;
}
