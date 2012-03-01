
class _TableSectionElementImpl extends _ElementImpl implements TableSectionElement native "*HTMLTableSectionElement" {

  String align;

  String ch;

  String chOff;

  final _HTMLCollectionImpl rows;

  String vAlign;

  void deleteRow(int index) native;

  _ElementImpl insertRow(int index) native;
}
