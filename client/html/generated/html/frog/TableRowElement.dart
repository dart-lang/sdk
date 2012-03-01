
class _TableRowElementImpl extends _ElementImpl implements TableRowElement native "*HTMLTableRowElement" {

  String align;

  String bgColor;

  final _HTMLCollectionImpl cells;

  String ch;

  String chOff;

  final int rowIndex;

  final int sectionRowIndex;

  String vAlign;

  void deleteCell(int index) native;

  _ElementImpl insertCell(int index) native;
}
