
class HTMLTableSectionElementJs extends HTMLElementJs implements HTMLTableSectionElement native "*HTMLTableSectionElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get ch() native "return this.ch;";

  void set ch(String value) native "this.ch = value;";

  String get chOff() native "return this.chOff;";

  void set chOff(String value) native "this.chOff = value;";

  HTMLCollectionJs get rows() native "return this.rows;";

  String get vAlign() native "return this.vAlign;";

  void set vAlign(String value) native "this.vAlign = value;";

  void deleteRow(int index) native;

  HTMLElementJs insertRow(int index) native;
}
