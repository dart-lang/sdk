
class _SelectElementImpl extends _ElementImpl implements SelectElement native "*HTMLSelectElement" {

  bool autofocus;

  bool disabled;

  final _FormElementImpl form;

  final _NodeListImpl labels;

  int length;

  bool multiple;

  String name;

  final _HTMLOptionsCollectionImpl options;

  bool required;

  int selectedIndex;

  int size;

  final String type;

  final String validationMessage;

  final _ValidityStateImpl validity;

  String value;

  final bool willValidate;

  void add(_ElementImpl element, _ElementImpl before) native;

  bool checkValidity() native;

  _NodeImpl item(int index) native;

  _NodeImpl namedItem(String name) native;

  void setCustomValidity(String error) native;
}
