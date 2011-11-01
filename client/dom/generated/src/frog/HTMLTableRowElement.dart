
class HTMLTableRowElement extends HTMLElement native "HTMLTableRowElement" {

  String align;

  String bgColor;

  HTMLCollection cells;

  String ch;

  String chOff;

  int rowIndex;

  int sectionRowIndex;

  String vAlign;

  void deleteCell(int index) native;

  HTMLElement insertCell(int index) native;
}
