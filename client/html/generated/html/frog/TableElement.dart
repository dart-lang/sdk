
class _TableElementImpl extends _ElementImpl implements TableElement native "*HTMLTableElement" {

  String align;

  String bgColor;

  String border;

  _TableCaptionElementImpl caption;

  String cellPadding;

  String cellSpacing;

  String frame;

  final _HTMLCollectionImpl rows;

  String rules;

  String summary;

  final _HTMLCollectionImpl tBodies;

  _TableSectionElementImpl tFoot;

  _TableSectionElementImpl tHead;

  String width;

  _ElementImpl createCaption() native;

  _ElementImpl createTFoot() native;

  _ElementImpl createTHead() native;

  void deleteCaption() native;

  void deleteRow(int index) native;

  void deleteTFoot() native;

  void deleteTHead() native;

  _ElementImpl insertRow(int index) native;
}
