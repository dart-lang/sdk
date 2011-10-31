
class HTMLTableElement extends HTMLElement native "HTMLTableElement" {

  String align;

  String bgColor;

  String border;

  HTMLTableCaptionElement caption;

  String cellPadding;

  String cellSpacing;

  String frame;

  HTMLCollection rows;

  String rules;

  String summary;

  HTMLCollection tBodies;

  HTMLTableSectionElement tFoot;

  HTMLTableSectionElement tHead;

  String width;

  HTMLElement createCaption() native;

  HTMLElement createTFoot() native;

  HTMLElement createTHead() native;

  void deleteCaption() native;

  void deleteRow(int index) native;

  void deleteTFoot() native;

  void deleteTHead() native;

  HTMLElement insertRow(int index) native;
}
