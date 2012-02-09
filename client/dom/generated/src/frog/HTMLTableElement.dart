
class _HTMLTableElementJs extends _HTMLElementJs implements HTMLTableElement native "*HTMLTableElement" {

  String align;

  String bgColor;

  String border;

  _HTMLTableCaptionElementJs caption;

  String cellPadding;

  String cellSpacing;

  String frame;

  final _HTMLCollectionJs rows;

  String rules;

  String summary;

  final _HTMLCollectionJs tBodies;

  _HTMLTableSectionElementJs tFoot;

  _HTMLTableSectionElementJs tHead;

  String width;

  _HTMLElementJs createCaption() native;

  _HTMLElementJs createTFoot() native;

  _HTMLElementJs createTHead() native;

  void deleteCaption() native;

  void deleteRow(int index) native;

  void deleteTFoot() native;

  void deleteTHead() native;

  _HTMLElementJs insertRow(int index) native;
}
